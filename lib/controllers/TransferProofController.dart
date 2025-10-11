// lib/core/controllers/transfer_proof_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/data/model/TransferProofModel.dart';

class TransferProofController extends GetxController {
  // عدّل الـ base URL على بيئتك إذا لزم
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  final String uploadApiUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api/upload';
  // إذا تحتاج توكن للمصادقة
  String? authToken;
  void setAuthToken(String? token) => authToken = token;

  // الحالة والبيانات
  RxList<TransferProofModel> proofs = <TransferProofModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isUploading = false.obs;
  RxBool isSaving = false.obs;
  Rxn<TransferProofModel> current = Rxn<TransferProofModel>();

  // التعامل مع الصور قبل الرفع
  Rx<Uint8List?> imageBytes = Rx<Uint8List?>(null);
  RxString uploadedImageUrl = ''.obs;
  String? _pickedPath;

  // ===== image helpers =====
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        imageBytes.value = bytes;
        _pickedPath = pickedFile.path;
        update(['transfer_proof_image']);
      }
    } catch (e) {
      print('pickImage error: $e');
      _showSnackbar('خطأ', 'فشل اختيار الصورة', true);
    }
  }

  void removeImage() {
    imageBytes.value = null;
    uploadedImageUrl.value = '';
    _pickedPath = null;
    update(['transfer_proof_image']);
  }

  Future<void> loadImageFromUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        imageBytes.value = res.bodyBytes;
        _pickedPath = null;
        update(['transfer_proof_image']);
      }
    } catch (e) {
      print('loadImageFromUrl error: $e');
    }
  }

  // ===== normalize helper =====
  /// إذا السيرفر رجع مسار نسبي مثل "/storage/..." يحوله لرابط كامل
  String normalizeServerImageUrl(String url) {
    if (url.startsWith('http')) return url;
    final base = 'https://stayinme.arabiagroup.net/lar_stayInMe';
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  // ===== upload helper (images[] style) =====
  /// يعيد رابط الصورة المرفوعة (full url أو ما يعطيه السيرفر بعد المعالجة)
  Future<String> uploadImageToServer() async {
    if (imageBytes.value == null) throw Exception('لا توجد صورة للرفع');
    isUploading.value = true;
    try {
      final ext = _pickedPath != null && _pickedPath!.contains('.') ? _pickedPath!.split('.').last : 'jpg';
      final filename = 'transfer_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final mimeType = lookupMimeFromExtension(ext) ?? 'image/jpeg';
      final parts = mimeType.split('/');

      var request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'images[]',
          imageBytes.value!,
          filename: filename,
          contentType: MediaType(parts[0], parts[1]),
        ),
      );
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      final streamed = await request.send();
      final respString = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final jsonData = json.decode(respString);
        String? raw;
        if (jsonData is Map && jsonData['image_urls'] != null) {
          final list = List<String>.from(jsonData['image_urls']);
          if (list.isNotEmpty) raw = list.first;
        } else if (jsonData is Map && jsonData['image_url'] != null) {
          raw = jsonData['image_url'].toString();
        } else if (jsonData is String && jsonData.isNotEmpty) {
          raw = jsonData;
        }

        if (raw == null || raw.isEmpty) {
          throw Exception('رد غير متوقع من نقطة الرفع: $jsonData');
        }

        // إذا رجع السيرفر مسار نسبي - حوّله لرابط كامل
        final finalUrl = normalizeServerImageUrl(raw);
        uploadedImageUrl.value = finalUrl;
        return finalUrl;
      } else {
        throw Exception('فشل رفع الصورة: ${streamed.statusCode} => $respString');
      }
    } finally {
      isUploading.value = false;
    }
  }

  // ===== upload single file helper (for proofFile) =====
  Future<String?> uploadFileAndGetUrl(File file) async {
    try {
      final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
      final filename = 'transfer_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final parts = mimeType.split('/');

      var request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'images[]', // same field backend expects for upload endpoint
          file.path,
          filename: filename,
          contentType: MediaType(parts[0], parts[1]),
        ),
      );
      if (authToken != null) request.headers['Authorization'] = 'Bearer $authToken';

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonData = json.decode(res.body);
        String? raw;
        if (jsonData is Map && jsonData['image_urls'] != null) {
          final list = List<String>.from(jsonData['image_urls']);
          if (list.isNotEmpty) raw = list.first;
        } else if (jsonData is Map && jsonData['image_url'] != null) {
          raw = jsonData['image_url'].toString();
        } else if (jsonData is String && jsonData.isNotEmpty) {
          raw = jsonData;
        }

        if (raw == null || raw.isEmpty) {
          print('uploadFileAndGetUrl: رد غير متوقع: ${res.body}');
          return null;
        }
        return normalizeServerImageUrl(raw);
      } else {
        print('uploadFileAndGetUrl: فشل الرفع ${res.statusCode} => ${res.body}');
        return null;
      }
    } catch (e) {
      print('uploadFileAndGetUrl exception: $e');
      return null;
    }
  }



  // ===== fetch proofs BY USER (new) =====
  /// GET /api/transfer-proofs/user/{userId}
  /// يخزن النتيجة داخل `proofs` ويطبّع proof_image لو كان مسار نسبي
  Future<void> fetchProofsByUser({
    required int userId,
    int? page,
    int perPage = 50,
    bool append = false,
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/transfer-proofs/user/$userId').replace(
        queryParameters: {
          if (page != null) 'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null) headers['Authorization'] = 'Bearer $authToken';

      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = (body is Map && body['data'] != null) ? body['data'] : body;

        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data.isNotEmpty) {
          items = [data];
        } else {
          items = [];
        }

        final parsed = items.map((e) {
          final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
          if (map.containsKey('proof_image') && map['proof_image'] is String && (map['proof_image'] as String).isNotEmpty) {
            map['proof_image'] = normalizeServerImageUrl(map['proof_image'] as String);
          }
          return TransferProofModel.fromJson(map);
        }).toList();

        if (append) {
          proofs.addAll(parsed);
        } else {
          proofs.value = parsed;
        }
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة: ${res.statusCode}', true);
      }
    } catch (e) {
      print('fetchProofsByUser Exception: $e');
      _showSnackbar('استثناء', 'حدث خطأ عند جلب أدلة المستخدم', true);
    } finally {
      isLoading.value = false;
    }
  }

  // ===== create proof =====
  /// supports:
  ///  - imageBytes -> upload first (uploadImageToServer)
  ///  - proofFile -> upload first (uploadFileAndGetUrl)
  ///  - external URL -> send directly
  Future<bool> createProof({
    required int bankAccountId,
    required int walletId,
    required double amount,
    String? sourceAccountNumber,
    File? proofFile,
    String? proofImageUrl,
    int? userId,
  }) async {
    isSaving.value = true;
    try {
      // Case A: image picked via picker (imageBytes)
      if (imageBytes.value != null) {
        try {
          final url = await uploadImageToServer();
          if (url.isEmpty) {
            _showSnackbar('خطأ', 'فشل الحصول على رابط الصورة بعد الرفع', true);
            return false;
          }
          final uri = Uri.parse('$_baseUrl/transfer-proofs');
          final headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          };
          if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
          final res = await http.post(
            uri,
            headers: headers,
            body: json.encode({
              'bank_account_id': bankAccountId,
              'wallet_id': walletId,
              'amount': amount,
              if (sourceAccountNumber != null) 'source_account_number': sourceAccountNumber,
              if (userId != null) 'user_id': userId,
              'proof_image': url,
            }),
          );

          if (res.statusCode == 201 || res.statusCode == 200) {
            final body = json.decode(res.body) as Map<String, dynamic>;
            final data = body['data'] ?? body;
            final model = TransferProofModel.fromJson(data as Map<String, dynamic>);
            proofs.insert(0, model);
            _showSnackbar('نجاح', 'تم رفع دليل التحويل', false);
            removeImage();
            return true;
          } else {
            print('createProof (via uploadedImageUrl) failed: ${res.body}');
            _showSnackbar('خطأ', 'رمز الاستجابة: ${res.statusCode}', true);
            return false;
          }
        } catch (e) {
          print('createProof.upload error: $e');
          _showSnackbar('استثناء', 'فشل رفع الصورة: $e', true);
          return false;
        }
      }

      // Case B: proofFile provided -> **أرفع أولاً** ثم أرسل JSON بالـURL (مش multipart مباشر)
      if (proofFile != null) {
        final uploadedUrl = await uploadFileAndGetUrl(proofFile);
        if (uploadedUrl == null || uploadedUrl.isEmpty) {
          _showSnackbar('خطأ', 'فشل رفع الملف للحصول على رابط', true);
          return false;
        }

        final uri = Uri.parse('$_baseUrl/transfer-proofs');
        final headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        };
        if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
        final res = await http.post(
          uri,
          headers: headers,
          body: json.encode({
            'bank_account_id': bankAccountId,
            'wallet_id': walletId,
            'amount': amount,
            if (sourceAccountNumber != null) 'source_account_number': sourceAccountNumber,
            if (userId != null) 'user_id': userId,
            'proof_image': uploadedUrl,
          }),
        );

        if (res.statusCode == 201 || res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final data = body['data'] ?? body;
          final model = TransferProofModel.fromJson(data as Map<String, dynamic>);
          proofs.insert(0, model);
          _showSnackbar('نجاح', 'تم رفع دليل التحويل', false);
          return true;
        } else {
          print('createProof (via uploadedUrl) failed: ${res.statusCode} => ${res.body}');
          _showSnackbar('خطأ', 'رمز الاستجابة: ${res.statusCode}', true);
          return false;
        }
      }

      // Case C: external image url -> send directly
      if (proofImageUrl != null && proofImageUrl.isNotEmpty) {
        final uri = Uri.parse('$_baseUrl/transfer-proofs');
        final headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        };
        if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
        final res = await http.post(
          uri,
          headers: headers,
          body: json.encode({
            'bank_account_id': bankAccountId,
            'wallet_id': walletId,
            'amount': amount,
            if (sourceAccountNumber != null) 'source_account_number': sourceAccountNumber,
            if (userId != null) 'user_id': userId,
            'proof_image': proofImageUrl,
          }),
        );

        if (res.statusCode == 201 || res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final data = body['data'] ?? body;
          final model = TransferProofModel.fromJson(data as Map<String, dynamic>);
          proofs.insert(0, model);
          _showSnackbar('نجاح', 'تم إضافة دليل التحويل', false);
          return true;
        } else {
          _showSnackbar('خطأ', 'رمز الاستجابة: ${res.statusCode}', true);
          return false;
        }
      }

      _showSnackbar('تحذير', 'لم تقدم صورة أو ملف أو رابط للدليل', true);
      return false;
    } catch (e) {
      print('createProof Exception: $e');
      _showSnackbar('استثناء', 'حدث خطأ أثناء رفع الدليل: $e', true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  

  // ===== helper functions =====
  String? lookupMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  String? lookupMimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return null;
    }
  }

  void _showSnackbar(String title, String message, bool isError) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: isError ? 4 : 3),
        icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
        shouldIconPulse: true,
        dismissDirection: DismissDirection.horizontal,
      );
    } catch (e) {
      print('snackbar error: $e');
    }
  }
}
