import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/response/category_response.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class CategoryService {
  
  final String url = Env.apiUrl;

  Future<(CategoryResponse?, ErrorResponse?)> getSelfSimpleProducts(String jwt, int categoryId) async {
    final response = await http.get(
      Uri.parse('$url/categories/$categoryId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (CategoryResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}