// testingimage.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class TestingImage extends StatefulWidget {
  const TestingImage({Key? key}) : super(key: key);

  @override
  State<TestingImage> createState() => _TestingImageState();
}

class _TestingImageState extends State<TestingImage> {
  File? _imageFile;
  String? _result;
  bool _loading = false;

  final String apiUrl =
      "https://justabdullah-clip-image-search.hf.space/api/predict";

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _result = null;
      });
      print("[INFO] Image selected: ${pickedFile.path}");
    }
  }

  Future<void> _sendImage() async {
    if (_imageFile == null) {
      print("[ERROR] No image selected!");
      setState(() {
        _result = "No image selected!";
      });
      return;
    }

    setState(() {
      _loading = true;
      _result = "Sending image to API...";
    });

    print("[INFO] Preparing image for upload...");
    final bytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final Map<String, dynamic> body = {"data": [base64Image]};
    print("[INFO] POST body prepared, sending to $apiUrl");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("[INFO] Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = jsonDecode(response.body);
        print("[INFO] Response data: ${res['data'][0]}");
        setState(() {
          _result = "Success! Embedding received:\n${res['data'][0]}";
        });
      } else {
        print("[ERROR] Failed with status: ${response.statusCode}");
        setState(() {
          _result = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("[EXCEPTION] $e");
      setState(() {
        _result = "Exception: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CLIP Image Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(_imageFile!, height: 250)
                : Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(child: Text("No Image Selected")),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Pick Image"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendImage,
              child: const Text("Send to API"),
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : _result != null
                    ? Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _result!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
