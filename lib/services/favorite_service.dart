import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class FavoriteService {
  
  final String url = Env.apiUrl;

  Future<(bool?, ErrorResponse?)> checkFavorite(String jwt, int productId) async {
    final response = await http.get(
      Uri.parse('$url/favorites/check/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (json as bool, null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(SimpleProductListResponse?, ErrorResponse?)> getAllFavorites(String jwt, int page) async {
    final response = await http.get(
      Uri.parse('$url/favorites?page=$page'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (SimpleProductListResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<ErrorResponse?> favorite(String jwt, int productId) async {
    final response = await http.post(
      Uri.parse('$url/favorites/favorite/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      return null;
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return error;
    }
  }

  Future<ErrorResponse?> unfavorite(String jwt, int productId) async {
    final response = await http.post(
      Uri.parse('$url/favorites/unfavorite/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      return null;
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return error;
    }
  }
}