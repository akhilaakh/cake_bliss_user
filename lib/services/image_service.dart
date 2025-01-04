// lib/services/image_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageService {
  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      var uri =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest("POST", uri);
      var fileBytes = await imageFile.readAsBytes();

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: imageFile.path.split("/").last,
      );

      request.files.add(multipartFile);
      request.fields['upload_preset'] =
          dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parse the response to get the URL
        final responseJson = json.decode(responseData);
        return responseJson['secure_url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
