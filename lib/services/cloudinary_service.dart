import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<bool> uploadToCloudinary(FilePickerResult? filePickerResult) async {
  if (filePickerResult == null || filePickerResult.files.isEmpty) {
    print("no file selected");
    return false;
  }
  File file = File(filePickerResult.files.single.path!);
  String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  var uri =
      Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
  var request = http.MultipartRequest("POST", uri);

  var fileBytes = await file.readAsBytes();

  var multipartFile = http.MultipartFile.fromBytes(
    'file',
    fileBytes,
    filename: file.path.split("/").last,
  );

  request.files.add(multipartFile);

  request.fields['upload_preset'] = "preset-for-file-upload";
  request.fields['upload_type'] = "image";

  var response = await request.send();

  var responseBody = await response.stream.bytesToString();

  print(responseBody);

  if (response.statusCode == 200) {
    print("upload successfull!");
    return true;
  } else {
    print("upload failed with status:${response.statusCode}");
    return false;
  }
}
