import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/image_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class ImageService {
  
  final String url = Env.apiUrl;

  Future<(ImageResponse?, ErrorResponse?)> getImage(String jwt, String keyName) async {
    final response = await http.get(
      Uri.parse('$url/images/$keyName'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (ImageResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}