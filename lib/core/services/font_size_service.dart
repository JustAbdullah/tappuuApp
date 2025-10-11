// lib/core/services/font_size_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RemoteFontSize {
  final String name; // e.g. 'small','medium'
  final int value; // e.g. 12, 14
  final String description;

  RemoteFontSize({
    required this.name,
    required this.value,
    required this.description,
  });

  factory RemoteFontSize.fromJson(Map<String, dynamic> j) => RemoteFontSize(
        name: j['size_name'].toString(),
        value: int.parse(j['size_value'].toString()),
        description: j['description']?.toString() ?? '',
      );
}

class FontSizeService {
  FontSizeService._private();
  static final FontSizeService instance = FontSizeService._private();

  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  static const _kPrefsKey = 'font_sizes_map';
  static const _kPrefsRawKey = 'font_sizes_raw';

  final Map<String, int> _sizes = {};

  /// init: if forceRefresh=false, will apply cached sizes immediately (if exist),
  /// then try to fetch remote in background and update if changed.
  Future<void> init({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // apply cached immediately if present and not forcing refresh
    final localRaw = prefs.getString(_kPrefsKey);
    if (!forceRefresh && localRaw != null) {
      try {
        final decoded = json.decode(localRaw) as Map<String, dynamic>;
        _sizes.clear();
        decoded.forEach((k, v) {
          _sizes[k] = int.parse(v.toString());
        });
        if (kDebugMode) debugPrint('FontSizeService: applied cached sizes $_sizes');
        // continue to fetch remote in background to check for updates
        _fetchAndSyncInBackground();
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('FontSizeService: cached decode error $e');
        // fallthrough to fetch remote below
      }
    }

    // otherwise fetch immediately (blocking) to initialize
    await _fetchAndSync();
  }

  Future<void> refresh() async {
    await _fetchAndSync(force: true);
  }

  /// background check (non-blocking)
  void _fetchAndSyncInBackground() {
    // ignore errors
    _fetchAndSync().catchError((e) {
      if (kDebugMode) debugPrint('FontSizeService background fetch error: $e');
    });
  }

  /// fetches remote and syncs if changed
  Future<void> _fetchAndSync({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final uri = Uri.parse('$_baseUrl/font-sizes/active');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body;
        final prevRaw = prefs.getString(_kPrefsRawKey);

        if (!force && prevRaw != null && prevRaw == raw) {
          if (kDebugMode) debugPrint('FontSizeService: remote sizes unchanged.');
          return;
        }

        final body = json.decode(raw);
        if (body is Map<String, dynamic> && body['success'] == true && body['data'] != null) {
          final list = (body['data'] as List<dynamic>).map((e) => RemoteFontSize.fromJson(e as Map<String, dynamic>)).toList();
          _sizes.clear();
          for (var f in list) {
            _sizes[f.name] = f.value;
          }
          // save to prefs
          await prefs.setString(_kPrefsKey, json.encode(_sizes));
          await prefs.setString(_kPrefsRawKey, raw);
          if (kDebugMode) debugPrint('FontSizeService: remote sizes updated -> $_sizes');
        } else {
          if (kDebugMode) debugPrint('FontSizeService: unexpected remote payload.');
        }
      } else {
        if (kDebugMode) debugPrint('FontSizeService HTTP error ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FontSizeService.fetch error: $e');
    }
  }

  /// get size as double or null
  double? get(String name) {
    final v = _sizes[name];
    if (v == null) return null;
    return v.toDouble();
  }

  /// get raw sizes map
  Map<String, int> getAll() => Map.unmodifiable(_sizes);
}
