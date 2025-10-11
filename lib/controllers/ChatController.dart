import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

import '../core/data/model/Message.dart';
import '../core/data/model/conversation.dart';

class ChatController extends GetxController {
  final String _apiBase = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
  String get messagesBase => '$_apiBase/messages';

  // ---------- state ----------
  var conversationsList = <Conversation>[].obs;
  var isLoadingConversations = false.obs;
  var messagesList = <Message>[].obs;
  var isLoadingMessages = false.obs;

  // ---------- recorder ----------
  final MicStreamRecorder _recorder = MicStreamRecorder();
  var isRecording = false.obs;
  String? _recordFilePath;
  var isUploading = false.obs;
  var currentAmplitude = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupAmplitudeListener();
  }

  void _setupAmplitudeListener() {
    try {
      _recorder.amplitudeStream.listen((amplitude) {
        currentAmplitude.value = amplitude;
      });
    } catch (e, st) {
      print('Amplitude listener error: $e\n$st');
    }
  }

  // ================= fetchConversations =================
  Future<void> fetchConversations({
    required int userId,
    String type = 'all',
  }) async {
    isLoadingConversations.value = true;
    try {
      final uri = Uri.parse('$messagesBase/conversations/$userId')
          .replace(queryParameters: type == 'all' ? null : {'type': type});
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final rawList = data['conversations'] as List<dynamic>? ?? [];
          final list = rawList.map((e) {
            try {
              return Conversation.fromJson(e as Map<String, dynamic>);
            } catch (err, st) {
              print('Error parsing conversation: $err\n$st\n${json.encode(e)}');
              return null;
            }
          }).whereType<Conversation>().toList();

          list.sort((a, b) {
            final aDt = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDt.compareTo(aDt);
          });

          conversationsList.value = list;
        } else {
          Get.snackbar('خطأ', 'فشل في جلب المحادثات',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('خطأ', 'خادم الاستجابة ${res.statusCode}',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e, st) {
      print('Exception in fetchConversations: $e\n$st');
      Get.snackbar('خطأ', 'فشل في تحميل المحادثات: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingConversations.value = false;
    }
  }

  // ================= fetchMessages =================
  Future<void> fetchMessages({
    required int userId,
    required int partnerId,
    int? adId,
    required int advertiserProfileId,
  }) async {
    isLoadingMessages.value = true;
    messagesList.clear();
    try {
      final adIdParam = adId ?? 0;
      final uri = Uri.parse('$messagesBase/$userId/$partnerId/$adIdParam/$advertiserProfileId');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = (data['messages'] as List)
              .map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList();
          messagesList.value = list;
        } else {
          print('fetchMessages: success flag false');
        }
      } else {
        print('fetchMessages failed: ${res.statusCode} ${res.body}');
      }
    } catch (e, st) {
      print('Exception in fetchMessages: $e\n$st');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  // ================= sendMessage (text) =================
  Future<bool> sendMessage({
    required int senderId,
    required int recipientId,
    int? adId,
    required int advertiserProfileId,
    required String body,
  }) async {
    final uri = Uri.parse('$messagesBase');
    try {
      final payload = {
        'sender_id': senderId,
        'recipient_id': recipientId,
        'ad_id': adId,
        'advertiser_profile_id': advertiserProfileId,
        'body': body,
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      );

      if (res.statusCode == 201) {
        return true;
      } else {
        print('sendMessage failed: ${res.statusCode} ${res.body}');
        Get.snackbar('خطأ', 'فشل في إرسال الرسالة', 
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    } catch (e, st) {
      print('Exception in sendMessage: $e\n$st');
      Get.snackbar('خطأ', 'فشل في إرسال الرسالة', 
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  // ================= deleteMessage =================
  Future<bool> deleteMessage(int messageId) async {
    try {
      final uri = Uri.parse('$messagesBase/$messageId');
      final res = await http.delete(uri);

      if (res.statusCode == 200) {
        messagesList.removeWhere((m) => m.id == messageId);
        return true;
      } else {
        print('deleteMessage failed: ${res.statusCode} ${res.body}');
        return false;
      }
    } catch (e) {
      print('Exception in deleteMessage: $e');
      return false;
    }
  }

  // ================= mark message as read =================
  Future<bool> markAsRead(int messageId) async {
    try {
      final uri = Uri.parse('$messagesBase/$messageId/read');
      final res = await http.patch(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final idx = messagesList.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          final msg = messagesList[idx];
          messagesList[idx] = Message(
            id: msg.id,
            senderId: msg.senderId,
            senderEmail: msg.senderEmail,
            recipientId: msg.recipientId,
            recipientEmail: msg.recipientEmail,
            body: msg.body,
            isVoice: msg.isVoice,
            voiceUrl: msg.voiceUrl,
            isRead: true,
            createdAt: msg.createdAt,
            readAt: DateTime.now(),
            updatedAt: msg.updatedAt,
            adId: msg.adId,
            adNumber: msg.adNumber,
            adTitleAr: msg.adTitleAr,
            adTitleEn: msg.adTitleEn,
            adSlug: msg.adSlug,
            adDescriptionAr: msg.adDescriptionAr,
            adDescriptionEn: msg.adDescriptionEn,
            adPrice: msg.adPrice,
            adShowTime: msg.adShowTime,
            adCreatedAt: msg.adCreatedAt,
            adImages: msg.adImages,
            advertiserProfileId: msg.advertiserProfileId,
            advertiserUserId: msg.advertiserUserId,
            advertiserName: msg.advertiserName,
            advertiserLogo: msg.advertiserLogo,
            advertiserDescription: msg.advertiserDescription,
            advertiserContactPhone: msg.advertiserContactPhone,
            advertiserWhatsappPhone: msg.advertiserWhatsappPhone,
            advertiserWhatsappCallNumber: msg.advertiserWhatsappCallNumber,
            advertiserWhatsappUrl: msg.advertiserWhatsappUrl,
            advertiserTelUrl: msg.advertiserTelUrl,
            advertiserLatitude: msg.advertiserLatitude,
            advertiserLongitude: msg.advertiserLongitude,
          );
        }
        return true;
      } else {
        print('markAsRead failed: ${res.statusCode} ${res.body}');
        return false;
      }
    } catch (e) {
      print('Exception in markAsRead: $e');
      return false;
    }
  }

  // ================= Recording methods =================
  Future<void> startRecording() async {
    try {
      if (isRecording.value) {
        await stopRecording();
        return;
      }

      final dir = await getTemporaryDirectory();
      _recordFilePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.configureRecording(
        sampleRate: 22050, // تقليل الجودة لتقليل الحجم
        channels: 1, // مونو بدل ستريو
        bufferSize: 1024,
        audioQuality: AudioQuality.medium, // جودة متوسطة
      );

      await _recorder.startRecording(_recordFilePath!);
      isRecording.value = true;
      print('Recording started -> $_recordFilePath');
    } catch (e, st) {
      print('startRecording error: $e\n$st');
      Get.snackbar('خطأ', 'فشل بدء التسجيل', 
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<String?> stopRecording() async {
    try {
      final String? path = await _recorder.stopRecording();
      isRecording.value = false;
      _recordFilePath = path;
      print('Recording stopped -> $path');
      
      // التحقق من حجم الملف
      if (path != null) {
        final file = File(path);
        final size = await file.length();
        print('Recording size: ${size / 1024} KB');
        
        if (size > 10485760) { // إذا كان أكبر من 10MB
          Get.snackbar('تحذير', 'حجم التسجيل كبير جداً', 
              backgroundColor: Colors.orange, colorText: Colors.white);
        }
      }
      
      return path;
    } catch (e, st) {
      print('stopRecording error: $e\n$st');
      isRecording.value = false;
      return null;
    }
  }

  // ================= uploadAudio =================
  Future<String?> uploadAudioFile(String localFilePath) async {
    if (localFilePath.isEmpty) return null;
    isUploading.value = true;

    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        print('uploadAudioFile: local file does not exist -> $localFilePath');
        Get.snackbar('خطأ', 'الملف الصوتي غير موجود محليًا', 
            backgroundColor: Colors.red, colorText: Colors.white);
        return null;
      }

      // التحقق من حجم الملف
      final fileSize = await file.length();
      if (fileSize > 20971520) { // 20MB
        Get.snackbar('خطأ', 'حجم الملف كبير جداً (الحد الأقصى 20MB)', 
            backgroundColor: Colors.red, colorText: Colors.white);
        return null;
      }

      final uri = Uri.parse('$messagesBase/upload-audio');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Accept': 'application/json'});

      // ✅ **التصحيح المهم: استخدم 'audio' بدل 'audios[]'**
      request.files.add(await http.MultipartFile.fromPath('audio', localFilePath));

      print('Uploading audio file: $localFilePath, size: ${fileSize / 1024} KB');

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      print('uploadAudioFile response: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 201) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        
        // ✅ **التصحيح: التعامل مع الاستجابة الجديدة**
        if (data.containsKey('audio_urls') && 
            data['audio_urls'] is List && 
            (data['audio_urls'] as List).isNotEmpty) {
          return (data['audio_urls'] as List).first?.toString();
        } else if (data.containsKey('audio_url')) {
          return data['audio_url']?.toString();
        } else {
          print('uploadAudioFile: unexpected response body: ${resp.body}');
          Get.snackbar('خطأ', 'استجابة غير متوقعة من السيرفر', 
              backgroundColor: Colors.red, colorText: Colors.white);
          return null;
        }
      } else if (resp.statusCode == 422) {
        try {
          final body = json.decode(resp.body);
          final errors = body['errors'] ?? body;
          print('Validation errors uploading audio: $errors');
          Get.snackbar('خطأ رفع صوت', errors.toString(),
              backgroundColor: Colors.red, colorText: Colors.white);
        } catch (_) {
          Get.snackbar('خطأ رفع صوت', 'فشل التحقق من الملف', 
              backgroundColor: Colors.red, colorText: Colors.white);
        }
        return null;
      } else {
        print('uploadAudioFile failed: ${resp.statusCode} ${resp.body}');
        Get.snackbar('خطأ', 'فشل رفع الملف الصوتي: ${resp.statusCode}', 
            backgroundColor: Colors.red, colorText: Colors.white);
        return null;
      }
    } catch (e, st) {
      print('Exception in uploadAudioFile: $e\n$st');
      Get.snackbar('خطأ', 'استثناء أثناء رفع الملف الصوتي: $e', 
          backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  // ================= sendVoiceMessage =================
  Future<bool> sendVoiceMessage({
    required int senderId,
    required int recipientId,
    int? adId,
    required int advertiserProfileId,
    required String localFilePath,
  }) async {
    try {
      final uploadedUrl = await uploadAudioFile(localFilePath);
      if (uploadedUrl == null) {
        Get.snackbar('خطأ', 'فشل رفع الملف الصوتي', 
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }

      final uri = Uri.parse('$messagesBase');
      final Map<String, dynamic> payload = {
        'sender_id': senderId,
        'recipient_id': recipientId,
        'ad_id': adId,
        'advertiser_profile_id': advertiserProfileId,
        'is_voice': true,
        'voice_url': uploadedUrl,
      };

      print('Sending voice message with payload: $payload');

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      );

      print('sendVoiceMessage response: ${res.statusCode} ${res.body}');

      if (res.statusCode == 201) {
        Get.snackbar('نجاح', 'تم إرسال الرسالة الصوتية', 
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        print('sendVoiceMessage failed: ${res.statusCode} ${res.body}');
        try {
          final body = json.decode(res.body);
          if (body is Map && body.containsKey('errors')) {
            Get.snackbar('خطأ', body['errors'].toString(), 
                backgroundColor: Colors.red, colorText: Colors.white);
          } else if (body is Map && body.containsKey('message')) {
            Get.snackbar('خطأ', body['message'].toString(), 
                backgroundColor: Colors.red, colorText: Colors.white);
          } else {
            Get.snackbar('خطأ', 'فشل إرسال الرسالة الصوتية', 
                backgroundColor: Colors.red, colorText: Colors.white);
          }
        } catch (_) {
          Get.snackbar('خطأ', 'فشل إرسال الرسالة الصوتية', 
              backgroundColor: Colors.red, colorText: Colors.white);
        }
        return false;
      }
    } catch (e, st) {
      print('Exception in sendVoiceMessage: $e\n$st');
      Get.snackbar('خطأ', 'استثناء أثناء إرسال الرسالة الصوتية: $e', 
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  // ================= Utilities =================
  Future<void> deleteLocalRecording() async {
    try {
      if (_recordFilePath != null) {
        final f = File(_recordFilePath!);
        if (await f.exists()) await f.delete();
        _recordFilePath = null;
      }
    } catch (e) {
      print('deleteLocalRecording error: $e');
    }
  }

  @override
  void onClose() {
    try {
      if (isRecording.value) {
        stopRecording().catchError((_) {});
      }
    } catch (_) {}
    super.onClose();
  }
}