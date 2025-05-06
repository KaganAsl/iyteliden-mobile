import 'dart:convert';

import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/user_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';
import 'package:http/http.dart' as http;

class UserService {
  
  final String url = Env.apiUrl;

  Future<(SelfUserResponse?, ErrorResponse?)> getSelfUserProfile(String jwt) async {
    final response = await http.get(
      Uri.parse('$url/users/myprofile'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (SelfUserResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(UserResponse?, ErrorResponse?)> getUserProfile(String jwt, int userId) async {
    final response = await http.get(
      Uri.parse('$url/users/$userId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (UserResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}