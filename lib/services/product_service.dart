import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';

class ProductService {
  
  final String url = Env.apiUrl;

  Future<(SimpleSelfProductListResponse?, ErrorResponse?)> getSelfSimpleProducts(String jwt, int userId, int page) async {
    final response = await http.get(
      Uri.parse('$url/products/userId/$userId?page=$page'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (SimpleSelfProductListResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(SimpleProductListResponse?, ErrorResponse?)> getSimpleProducts(String jwt, int userId, int page) async {
    final response = await http.get(
      Uri.parse('$url/products/userId/$userId?page=$page'),
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

  Future<(bool?, ErrorResponse?)> isMyProduct(String jwt, int productId) async {
    final response = await http.get(
      Uri.parse('$url/products/ismine/$productId'),
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

  Future<(DetailedProductResponse?, ErrorResponse?)> getDetailedProduct(String jwt, int productId) async {
    final response = await http.get(
      Uri.parse('$url/products/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final detailedProduct = DetailedProductResponse.fromJson(json);
      return (detailedProduct, null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }

  Future<(DetailedSelfProductResponse?, ErrorResponse?)> getSelfDetailedProduct(String jwt, int productId) async {
    final response = await http.get(
      Uri.parse('$url/products/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return (DetailedSelfProductResponse.fromJson(json), null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}