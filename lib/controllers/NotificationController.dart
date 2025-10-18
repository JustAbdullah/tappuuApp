import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationController extends GetxController {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];
  final String _projectId = 'tappuu-7c425';

  /// إرسال إشعار لتصنيف (topic = categoryId)
  Future<void> sendCategoryNotification(String title, String body, String categoryId) async {
    // ملف Service Account credentials (مشروع tappuu-7c425)
    final serviceAccount = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "tappuu-7c425",
      "private_key_id": "907d5cfe2cd2aadb8dec643235b63bb96fad7f16",
      "private_key": "-----BEGIN PRIVATE KEY-----\n"
          "MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDubcqSJUklGks3\n"
          "HeNkUtMWLcLCLUc+9jrdrF6vgfi/hcUJAg5w4dH+Y200vu5h79q//s+1E5825Xff\n"
          "AymaXHnMRdVL8hS7K6B2m2sTo0cWGD79vzVEaxZYqgVGI8ZIwcbP6uqCb9wrvRVh\n"
          "3Ze2c6JON8QVJkEA+Nqbq/rByaRjFtHuUgEosrDfk2+gIFhSQE2rFQyrpN1uy2+0\n"
          "xTvI9TrRBtpTPu4iBLG0nugVWVC5FxaG4YXfLMqklnjy0u8pWPgfFhlXAQTMaPEb\n"
          "vQd5VBXyoJyV1HcAMtQ8oZhJQafItubwdm+iPS5bU0mbK17DN3BITA7KJgpqHeBO\n"
          "2TJeVeY7AgMBAAECggEAQDihcikJ4S0Kam+qAqlOgzBTP8M7aAmhxHi7zlFXY5sP\n"
          "/gOoSR6CVh+I2Ea/ZfDZvpJPdyowXfSEC7VJ3PKgufVrZPfxPpMbNydYuaLmsFxa\n"
          "hzWcDvA7RimRnxlevNU5DGLtxLGFn+Bf5Irv5OyToLbjoYC6zJy7IWg69DywgyGq\n"
          "1USKDgQn164Kxpg+HRTNKP5fRrIgFXbfZzqZS6WtLD6fKD7qL7D4LZ4tjXLJnUI1\n"
          "oW3KHTkzXyjr+1c6dxCXqGt8d0Rdoo1H67ZY9Bq3QogzCgPVMwvcfp5q9SQYEQml\n"
          "1IVwf8DG6hl5/sUY7HXMNqHCBeZcXFKD0WIMirv5XQKBgQD3WeZ1VwnnI5WyUh2B\n"
          "AEzHzdTXYPQNeIF7RZmO7ZkLfWXukpBDmqrHBbAuZixXHtS2ZvZAsLhFw1gzgxaO\n"
          "of6DbrS/it+Umn/IzxrrrpHeGs9zkfUufjO/uuj8mvw+PkrEqyzELx86jzpv6uwB\n"
          "LuBYpsccAFfuVUdWuyzBwQ2KhQKBgQD2xAaBM9ueydmFWJU7AOZUZJtJCRdncYWc\n"
          "jKsExdqPQoTcT0u7rusQWCG4RpaSY8jKaqDUcPNNmXmRk5FWXZ19LgoqTIzMp6fC\n"
          "mlFOoy4B9rqjJGq/a5jNgvKlEe/NhFXrHcmBm6lAMHnArQT6FhhrJmzUOP7A50f8\n"
          "ba/gxS9pvwKBgQDSvMlYV5ucTfkQQF3atoK0CG26QmQrxeurNxUpbMzjuSbLKBu5\n"
          "PWEax4HfRjWo1B+ud/J+ExIsfc37tUfWpbXODNf6CTuLxEXytGDfQ5ALhxQQBt65\n"
          "idRVGc2+ydz2uuPAw4YUb4FPxw+moqQILgP+A7nH5ZME/6sT/cyYFv6OcQKBgQCO\n"
          "D4HzJcicnHXGh525zyXKlfSz0jEQE1GpM25NHB5b9R6JunjN/sBCs4oODU0nz5xL\n"
          "s6ENTE01clKDVWIJR3GgHD4r5c/1DdvNc4u1asnUxZbiztdJhgb84RMRpsbYGQRh\n"
          "i89y9wsz8fRV0QWZd9js7r0eXAWFRmCx2O+0xbAq/wKBgCzBfhUHC6rJkNO/JwpN\n"
          "EuxbY3kAFk2VLtQlwEP0bJnxVDKXX//eQ0NTYzLrpA4+rsbPH0yPYVDkRfopiHbf\n"
          "a3oej2u5IH8BPg5vwQJEGK7ho10uszXXXxOR7hdgDUuEi34DX/HVUhLTrrGXH3LT\n"
          "NyEQMco66zxETPv1K06ugFaA\n"
          "-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@tappuu-7c425.iam.gserviceaccount.com",
      "client_id": "114921813183076551164",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40tappuu-7c425.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    try {
      // إنشاء عميل معتمد
      final authClient = await clientViaServiceAccount(serviceAccount, _scopes);

      // الحصول على الـ access token
      final accessToken = authClient.credentials.accessToken.data;

      // تحضير طلب FCM HTTP v1
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // topic = categoryId
      final topicName = "$categoryId";

      final message = {
        "message": {
          "topic": topicName,
          "notification": {"title": title, "body": body},
          "android": {
            "priority": "HIGH",
            "notification": {
              "channel_id": "high_priority_channel",
              "sound": "default",
              "tag": "category_$categoryId"
            }
          },
          "apns": {
            "headers": {"apns-priority": "10"},
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
                "category": "category_$categoryId"
              }
            }
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "status": "new",
            "category_id": categoryId.toString(),
            "type": "category_notification"
          }
        }
      };

      // إرسال الطلب
      final response = await http.post(url, headers: headers, body: json.encode(message));

      if (response.statusCode == 200) {
        debugPrint('✅ تم إرسال الإشعار بنجاح إلى قناة $topicName');
      } else {
        debugPrint('‼️ فشل الإرسال: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('‼️ خطأ غير متوقع: $e');
      debugPrint('🔍 تفاصيل الخطأ: $stack');
    }
  }

  ////////

  /// إرسال إشعار تحديث سعر لإعلان محدد (topic = AdId_{adId})
  Future<void> sendUpdatePriceNotification(String title, String body, String adId) async {
    // ملف Service Account credentials (مشروع tappuu-7c425)
    final serviceAccount = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "tappuu-7c425",
      "private_key_id": "907d5cfe2cd2aadb8dec643235b63bb96fad7f16",
      "private_key": "-----BEGIN PRIVATE KEY-----\n"
          "MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDubcqSJUklGks3\n"
          "HeNkUtMWLcLCLUc+9jrdrF6vgfi/hcUJAg5w4dH+Y200vu5h79q//s+1E5825Xff\n"
          "AymaXHnMRdVL8hS7K6B2m2sTo0cWGD79vzVEaxZYqgVGI8ZIwcbP6uqCb9wrvRVh\n"
          "3Ze2c6JON8QVJkEA+Nqbq/rByaRjFtHuUgEosrDfk2+gIFhSQE2rFQyrpN1uy2+0\n"
          "xTvI9TrRBtpTPu4iBLG0nugVWVC5FxaG4YXfLMqklnjy0u8pWPgfFhlXAQTMaPEb\n"
          "vQd5VBXyoJyV1HcAMtQ8oZhJQafItubwdm+iPS5bU0mbK17DN3BITA7KJgpqHeBO\n"
          "2TJeVeY7AgMBAAECggEAQDihcikJ4S0Kam+qAqlOgzBTP8M7aAmhxHi7zlFXY5sP\n"
          "/gOoSR6CVh+I2Ea/ZfDZvpJPdyowXfSEC7VJ3PKgufVrZPfxPpMbNydYuaLmsFxa\n"
          "hzWcDvA7RimRnxlevNU5DGLtxLGFn+Bf5Irv5OyToLbjoYC6zJy7IWg69DywgyGq\n"
          "1USKDgQn164Kxpg+HRTNKP5fRrIgFXbfZzqZS6WtLD6fKD7qL7D4LZ4tjXLJnUI1\n"
          "oW3KHTkzXyjr+1c6dxCXqGt8d0Rdoo1H67ZY9Bq3QogzCgPVMwvcfp5q9SQYEQml\n"
          "1IVwf8DG6hl5/sUY7HXMNqHCBeZcXFKD0WIMirv5XQKBgQD3WeZ1VwnnI5WyUh2B\n"
          "AEzHzdTXYPQNeIF7RZmO7ZkLfWXukpBDmqrHBbAuZixXHtS2ZvZAsLhFw1gzgxaO\n"
          "of6DbrS/it+Umn/IzxrrrpHeGs9zkfUufjO/uuj8mvw+PkrEqyzELx86jzpv6uwB\n"
          "LuBYpsccAFfuVUdWuyzBwQ2KhQKBgQD2xAaBM9ueydmFWJU7AOZUZJtJCRdncYWc\n"
          "jKsExdqPQoTcT0u7rusQWCG4RpaSY8jKaqDUcPNNmXmRk5FWXZ19LgoqTIzMp6fC\n"
          "mlFOoy4B9rqjJGq/a5jNgvKlEe/NhFXrHcmBm6lAMHnArQT6FhhrJmzUOP7A50f8\n"
          "ba/gxS9pvwKBgQDSvMlYV5ucTfkQQF3atoK0CG26QmQrxeurNxUpbMzjuSbLKBu5\n"
          "PWEax4HfRjWo1B+ud/J+ExIsfc37tUfWpbXODNf6CTuLxEXytGDfQ5ALhxQQBt65\n"
          "idRVGc2+ydz2uuPAw4YUb4FPxw+moqQILgP+A7نH5ZME/6sT/cyYFv6OcQKBgQCO\n"
          "D4HzJcicnHXGh525zyXKlfSz0jEQE1GpM25NHB5b9R6JunjN/sBCs4oODU0nz5xL\n"
          "s6ENTE01clKDVWIJR3GgHD4r5c/1DdvNc4u1asnUxZbiztdJhgb84RMRpsbYGQRh\n"
          "i89y9wsz8fRV0QWZd9js7r0eXAWFRmCx2O+0xbAq/wKBgCzBfhUHC6rJkNO/JwpN\n"
          "EuxbY3kAFk2VLtQlwEP0bJnxVDKXX//eQ0NTYzLrpA4+rsbPH0yPYVDkRfopiHbf\n"
          "a3oej2u5IH8BPg5vwQJEGK7ho10uszXXXxOR7hdgDUuEi34DX/HVUhLTrrGXH3LT\n"
          "NyEQMco66zxETPv1K06ugFaA\n"
          "-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@tappuu-7c425.iam.gserviceaccount.com",
      "client_id": "114921813183076551164",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40tappuu-7c425.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    try {
      // إنشاء عميل معتمد
      final authClient = await clientViaServiceAccount(serviceAccount, _scopes);

      // الحصول على الـ access token
      final accessToken = authClient.credentials.accessToken.data;

      // تحضير طلب FCM HTTP v1
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // topic = AdId_{adId}
      final topicName = "AdId_$adId";

      final message = {
        "message": {
          "topic": topicName,
          "notification": {"title": title, "body": body},
          "android": {
            "priority": "HIGH",
            "notification": {
              "channel_id": "high_priority_channel",
              "sound": "default",
              "tag": "AdId_$adId"
            }
          },
          "apns": {
            "headers": {"apns-priority": "10"},
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
                "category": "AdId_$adId"
              }
            }
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "status": "new",
            "category_id": adId.toString(),
            "type": "category_notification"
          }
        }
      };

      // إرسال الطلب
      final response = await http.post(url, headers: headers, body: json.encode(message));

      if (response.statusCode == 200) {
        debugPrint('✅ تم إرسال الإشعار بنجاح إلى قناة $topicName');
      } else {
        debugPrint('‼️ فشل الإرسال: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('‼️ خطأ غير متوقع: $e');
      debugPrint('🔍 تفاصيل الخطأ: $stack');
    }
  }
}
