// lib/core/services/font_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Models used by the service:
class RemoteWeight {
  final int id;
  final int weightValue;
  final String assetPath;

  RemoteWeight({required this.id, required this.weightValue, required this.assetPath});

  factory RemoteWeight.fromJson(Map<String, dynamic> j) => RemoteWeight(
        id: int.parse(j['id'].toString()),
        weightValue: int.parse(j['weight_value'].toString()),
        assetPath: j['asset_path'] ?? '',
      );
}

class RemoteFont {
  final int id;
  final String familyName;
  final List<RemoteWeight> weights;

  RemoteFont({required this.id, required this.familyName, required this.weights});

  factory RemoteFont.fromJson(Map<String, dynamic> j) => RemoteFont(
        id: int.parse(j['id'].toString()),
        familyName: j['family_name'].toString(),
        weights: (j['weights'] as List<dynamic>?)?.map((e) => RemoteWeight.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      );
}

/// FontService: downloads fonts, registers via FontLoader, caches mapping in prefs.
/// Uses raw remote JSON comparison to detect changes and avoid re-downloading.
class FontService {
  FontService._private();
  static final FontService instance = FontService._private();

  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // prefs keys
  static const _kPrefsKeyFontMap = 'font_family_local_map'; // { family: { weight: localPath } }
  static const _kPrefsKeyActiveFamily = 'font_active_family';
  static const _kPrefsKeyRemoteRaw = 'font_remote_raw';

  // in-memory
  Map<String, Map<int, String>> _familyLocalMap = {};
  String? activeFamily;
  final Set<String> _registeredFamilies = {};

  /// initialize: applies cached map then fetches remote and updates if changed.
  Future<void> init({bool forceRefresh = false}) async {
    await _loadPrefs();

    // if not force and active family is already registered, still check remote in background
    if (!forceRefresh && activeFamily != null && _registeredFamilies.contains(activeFamily)) {
      // try background check to detect any change
      _fetchAndSyncInBackground();
      return;
    }

    // otherwise do full fetch-and-register
    await _fetchAndSync(force: forceRefresh);
  }

  Future<void> refresh() async {
    await _fetchAndSync(force: true);
  }

  // ---------------- persistence ----------------
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMap = prefs.getString(_kPrefsKeyFontMap);
    final active = prefs.getString(_kPrefsKeyActiveFamily);

    if (rawMap != null) {
      try {
        final decoded = json.decode(rawMap) as Map<String, dynamic>;
        _familyLocalMap = decoded.map((family, m) {
          final map = (m as Map).map((k, v) => MapEntry(int.parse(k.toString()), v.toString()));
          return MapEntry(family, map);
        });
      } catch (e) {
        if (kDebugMode) debugPrint('FontService._loadPrefs decode error: $e');
        _familyLocalMap = {};
      }
    } else {
      _familyLocalMap = {};
    }
    activeFamily = active;
    // mark registered families if files still exist
    for (final family in _familyLocalMap.keys) {
      _registeredFamilies.add(family);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _familyLocalMap.map((family, m) {
      return MapEntry(family, m.map((k, v) => MapEntry(k.toString(), v)));
    });
    await prefs.setString(_kPrefsKeyFontMap, json.encode(encoded));
    if (activeFamily != null) await prefs.setString(_kPrefsKeyActiveFamily, activeFamily!);
  }

  // ---------------- remote fetch & sync ----------------
  void _fetchAndSyncInBackground() {
    _fetchAndSync().catchError((e) {
      if (kDebugMode) debugPrint('FontService background _fetchAndSync error: $e');
    });
  }

  Future<void> _fetchAndSync({bool force = false}) async {
    final uri = Uri.parse('$_baseUrl/fonts/active');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('FontService HTTP ${res.statusCode}');
        return;
      }
      final raw = res.body;
      final prefs = await SharedPreferences.getInstance();
      final prevRaw = prefs.getString(_kPrefsKeyRemoteRaw);

      if (!force && prevRaw != null && prevRaw == raw) {
        if (kDebugMode) debugPrint('FontService: remote fonts unchanged.');
        return;
      }

      final body = json.decode(raw);
      if (body is Map<String, dynamic> && body['success'] == true && body['data'] != null) {
        final remote = RemoteFont.fromJson(body['data'] as Map<String, dynamic>);
        // download and register only if changed or force
        await _downloadAndRegister(remote);
        // store remote raw
        await prefs.setString(_kPrefsKeyRemoteRaw, raw);
      } else {
        if (kDebugMode) debugPrint('FontService: invalid remote payload.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FontService._fetchAndSync error: $e');
    }
  }

  // ---------------- download & register ----------------
  Future<void> _downloadAndRegister(RemoteFont remote) async {
    final family = remote.familyName;
    final dir = await getApplicationSupportDirectory();
    final familyDir = Directory(p.join(dir.path, 'fonts_cache', family));
    if (!await familyDir.exists()) await familyDir.create(recursive: true);

    // prepare loader
    final loader = FontLoader(family);
    final Map<int, String> weightToLocal = {};

    for (final w in remote.weights) {
      final url = w.assetPath;
      if (url.isEmpty) continue;

      try {
        final fileName = _fileNameFromUrl(url);
        final localPath = p.join(familyDir.path, fileName);
        final localFile = File(localPath);

        if (!await localFile.exists()) {
          final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
          if (resp.statusCode == 200) {
            await localFile.writeAsBytes(resp.bodyBytes, flush: true);
            if (kDebugMode) debugPrint('FontService: downloaded font $localPath');
          } else {
            if (kDebugMode) debugPrint('FontService: font download failed ${resp.statusCode} for $url');
            continue;
          }
        } else {
          if (kDebugMode) debugPrint('FontService: font already cached $localPath');
        }

        final bytes = await localFile.readAsBytes();
        final bd = ByteData.view(bytes.buffer);
        loader.addFont(Future.value(bd));
        weightToLocal[w.weightValue] = localPath;
      } catch (e) {
        if (kDebugMode) debugPrint('FontService: error downloading/registering ${w.assetPath} -> $e');
      }
    }

    if (weightToLocal.isEmpty) {
      if (kDebugMode) debugPrint('FontService: no weights downloaded for family $family -> skipping load.');
      return;
    }

    try {
      await loader.load();
      // update local map and prefs
      // cleanup previous family files if switching family
      await _cleanupOldFamilyIfNeeded(family);
      _familyLocalMap[family] = weightToLocal;
      activeFamily = family;
      _registeredFamilies.add(family);
      await _savePrefs();
      if (kDebugMode) debugPrint('FontService: registered family $family with weights ${weightToLocal.keys.toList()}');
    } catch (e) {
      if (kDebugMode) debugPrint('FontService: loader.load failed for $family -> $e');
    }
  }

  // ---------------- housekeeping ----------------
  Future<void> _cleanupOldFamilyIfNeeded(String newFamily) async {
    try {
      // remove any family that is not the newFamily (optional: keep multiple families if desired)
      final dir = await getApplicationSupportDirectory();
      final fontsRoot = Directory(p.join(dir.path, 'fonts_cache'));
      if (!await fontsRoot.exists()) return;

      final entries = fontsRoot.listSync();
      for (final e in entries) {
        if (e is Directory) {
          final name = p.basename(e.path);
          if (name != newFamily) {
            // delete directory entirely
            try {
              await e.delete(recursive: true);
              _familyLocalMap.remove(name);
              _registeredFamilies.remove(name);
              if (kDebugMode) debugPrint('FontService: removed old family cache $name');
            } catch (ex) {
              if (kDebugMode) debugPrint('FontService: failed to remove old family $name -> $ex');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FontService._cleanupOldFamilyIfNeeded error: $e');
    }
  }

  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) return segments.last;
      return 'font_${DateTime.now().millisecondsSinceEpoch}.ttf';
    } catch (_) {
      return 'font_${DateTime.now().millisecondsSinceEpoch}.ttf';
    }
  }

  // ---------------- public helpers ----------------
  /// active family name
  String? getActiveFamily() => activeFamily;

  /// check if family registered
  bool isFamilyRegistered(String family) => _registeredFamilies.contains(family);

  /// get local path for family weight
  String? getLocalPathForWeight(String family, int weightValue) {
    final m = _familyLocalMap[family];
    if (m == null) return null;
    return m[weightValue];
  }

  /// mapping helper for prefs or debugging
  Map<String, Map<int, String>> getFamilyLocalMap() => Map.unmodifiable(_familyLocalMap);

  /// utility to convert numeric weight into Flutter FontWeight
  static FontWeight weightValueToFontWeight(int w) {
    switch (w) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }
}
