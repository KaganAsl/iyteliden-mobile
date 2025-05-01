import 'dart:convert';

import 'package:iyteliden_mobile/models/request/auth_entity.dart';
import 'package:iyteliden_mobile/models/response/auth_response.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String url = Env.apiUrl;

  Future<(AuthResponse?, ErrorResponse?)> login(AuthEntity data) async {
    final response = await http.post(
      Uri.parse('$url/auth/login'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(data.toJson())
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (AuthResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(String?, ErrorResponse?)> register(AuthEntity data) async {
    final response = await http.post(
      Uri.parse('$url/auth/register'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(data.toJson()),
    );
    if (response.statusCode == 200) {
      return(response.body, null);
    } else {
      final json = jsonDecode(response.body);
      return (null, ErrorResponse.fromJson(json));
    }
  }

  Future<int> userVerification(String jwt) async {
    final response = await http.get(
      Uri.parse('$url/auth/verification'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    return response.statusCode;
  }
}