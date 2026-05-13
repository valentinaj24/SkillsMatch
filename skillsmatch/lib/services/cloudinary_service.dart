import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dm4zcxqa4';
  static const String uploadPreset = 'skillsmatch_upload';

  static Future<String> uploadFile({
    required File file,
    required String folder,
    String resourceType = 'image',
  }) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload napaka: $responseData');
    }

    return jsonDecode(responseData)['secure_url'].toString();
  }

  static Future<String> uploadProfileImage(File file) {
    return uploadFile(
      file: file,
      folder: 'skillsmatch_profiles',
      resourceType: 'image',
    );
  }

  static Future<String> uploadChatImage(File file) {
    return uploadFile(
      file: file,
      folder: 'skillsmatch_chat_images',
      resourceType: 'image',
    );
  }

  static Future<String> uploadVoiceMessage(File file) {
    return uploadFile(
      file: file,
      folder: 'skillsmatch_voice_messages',
      resourceType: 'video',
    );
  }
}
