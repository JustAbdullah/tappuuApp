// lib/core/controllers/editable_text_controller.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as ser;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../core/data/model/EditableTextModel.dart';

class EditableTextController extends GetxController {
  // عدّل الـ baseUrl بحسب بيئتك إذا احتجت
  static const String _baseUrl =
      'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // الحالة والبيانات
  RxList<EditableTextModel> items = <EditableTextModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  // تتبع الخطوط المحمّلة لتجنّب تحميل مكرر
  final Set<String> _loadedFontFamilies = <String>{};
  final Set<String> _loadingFontFamilies = <String>{};

  // توليد اسم عائلة الخط لكل مفتاح
  String _familyForKey(String keyName) => 'editable_font_$keyName';

  // تحويل HEX إلى Color
  Color hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final full = (clean.length == 6) ? 'FF$clean' : clean;
    final value = int.tryParse(full, radix: 16) ?? 0xFF000000;
    return Color(value);
  }

  // ===== find helpers =====
  EditableTextModel? findByKey(String key) {
    try {
      return items.firstWhere((e) => e.keyName == key);
    } catch (_) {
      return null;
    }
  }

  String fontFamilyForKey(String key) {
    final family = _familyForKey(key);
    return _loadedFontFamilies.contains(family) ? family : 'Tajawal'; // أو AppTextStyles.appFontFamily
  }

  /// Load font at runtime (if font_url present). Safe: multiple calls won't duplicate download.
  Future<void> ensureFontLoadedForKey(String key) async {
    final item = findByKey(key);
    if (item == null) return;
    await ensureFontLoaded(item);
  }

  Future<void> ensureFontLoaded(EditableTextModel item) async {
    final url = item.fontUrl;
    if (url == null || url.trim().isEmpty) return;

    final family = _familyForKey(item.keyName);
    if (_loadedFontFamilies.contains(family)) return;
    if (_loadingFontFamilies.contains(family)) {
      // if currently loading, wait for completion (poll)
      var attempts = 0;
      while (_loadingFontFamilies.contains(family) && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return;
    }

    _loadingFontFamilies.add(family);

    try {
      final uri = Uri.parse(url);
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('Font download failed (${res.statusCode}) for ${item.keyName}');
        }
        _loadingFontFamilies.remove(family);
        return;
      }

      final bytes = res.bodyBytes;
      final loader = ser.FontLoader(family);
      final byteData = ByteData.view(bytes.buffer);
      loader.addFont(Future.value(byteData));
      await loader.load();

      _loadedFontFamilies.add(family);
      if (kDebugMode) debugPrint('Loaded font for ${item.keyName} => family=$family');

      // إشعار الواجهة لتعيد البناء بالخطّ الجديد
      items.refresh();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading font for ${item.keyName}: $e');
    } finally {
      _loadingFontFamilies.remove(family);
    }
  }

  // ====== API calls ======
  Future<void> fetchAll({Duration timeout = const Duration(seconds: 10)}) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/editable-texts');
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode == 200) {
        final body = res.body;
        final parsed = body.isNotEmpty ? (await Future(() => jsonDecode(body))) : null;
        if (parsed is Map && parsed['data'] != null && parsed['data'] is List) {
          final list = parsed['data'] as List;
          items.value = list
              .map((e) => EditableTextModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (parsed is List) {
          items.value = parsed
              .map((e) => EditableTextModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          items.clear();
          if (kDebugMode) debugPrint('editable-texts: unexpected payload: $parsed');
        }
      } else {
        if (kDebugMode) debugPrint('fetchAll editable-texts failed: ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchAll editable-texts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<EditableTextModel?> fetchOne(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/editable-texts/$id');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        final data = parsed is Map && parsed['data'] != null ? parsed['data'] : parsed;
        if (data is Map<String, dynamic>) {
          final model = EditableTextModel.fromJson(data);
          // update local list (إعادة إسناد بمؤشر يضمن إعادة البناء)
          final idx = items.indexWhere((e) => e.id == model.id);
          if (idx != -1) {
            items[idx] = model;
          } else {
            items.insert(0, model);
          }
          return model;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchOne editable-texts error: $e');
    }
    return null;
  }

  /// Create (supports font_file multipart or font_url)
  Future<EditableTextModel?> create(Map<String, dynamic> payload, {File? fontFile}) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/editable-texts');

      if (fontFile != null) {
        // multipart
        final req = http.MultipartRequest('POST', uri);
        req.headers['Accept'] = 'application/json';
        // fields
        payload.forEach((k, v) {
          if (v != null) req.fields[k] = v.toString();
        });
        final mime = lookupMimeType(fontFile.path) ?? 'application/octet-stream';
        final parts = mime.split('/');
        final mf = http.MultipartFile.fromBytes(
          'font_file',
          await fontFile.readAsBytes(),
          filename: fontFile.path.split('/').last,
          contentType: MediaType(parts[0], parts[1]),
        );
        req.files.add(mf);
        final streamed = await req.send();
        final res = await http.Response.fromStream(streamed);
        if (res.statusCode == 201 || res.statusCode == 200) {
          final parsed = jsonDecode(res.body);
          final data = parsed['data'] ?? parsed;
          final model = EditableTextModel.fromJson(data as Map<String, dynamic>);
          items.insert(0, model);
          return model;
        } else {
          if (kDebugMode) debugPrint('create editable-text multipart failed: ${res.body}');
        }
      } else {
        // JSON post
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(payload),
        );
        if (res.statusCode == 201 || res.statusCode == 200) {
          final parsed = jsonDecode(res.body);
          final data = parsed['data'] ?? parsed;
          final model = EditableTextModel.fromJson(data as Map<String, dynamic>);
          items.insert(0, model);
          return model;
        } else {
          if (kDebugMode) {
            debugPrint('create editable-text JSON failed: ${res.statusCode} ${res.body}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('create editable-text error: $e');
    } finally {
      isSaving.value = false;
    }
    return null;
  }

  // ====== دوال تعديل فورية تضمن إعادة البناء ======
  void setText(String key, String text) {
    final idx = items.indexWhere((e) => e.keyName == key);
    if (idx == -1) return;
    final it = items[idx];
    items[idx] = it.copyWith(textContent: text);
  }

  void setFontSize(String key, int size) {
    final idx = items.indexWhere((e) => e.keyName == key);
    if (idx == -1) return;
    final it = items[idx];
    items[idx] = it.copyWith(fontSize: size);
  }

  void setColor(String key, String hex) {
    final idx = items.indexWhere((e) => e.keyName == key);
    if (idx == -1) return;
    final it = items[idx];
    items[idx] = it.copyWith(color: hex);
  }

  // لو تم تعديل الكائن in-place في مكان آخر
  void forceRefresh() => items.refresh();
}
