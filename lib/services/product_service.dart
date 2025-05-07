import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';
import 'package:mime/mime.dart';

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

  Future<(DetailedSelfProductResponse?, ErrorResponse?)> create(String jwt, Map<String, dynamic> product, List<File> files, List<int> locations) async {
    if (files.isEmpty || files.length > 6) {
      return (
        null,
        ErrorResponse(message: 'You must upload between 1 and 6 images.', status: 400, timestamp: DateTime.now())
      );
    }
    if (locations.isEmpty) {
      return (
        null,
        ErrorResponse(message: 'At least one location must be provided.', status: 400, timestamp: DateTime.now())
      );
    }
    final uri = Uri.parse('$url/products/create');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = jwt;
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';
    request.fields['product'] = jsonEncode(product);
    request.fields['locations'] = jsonEncode(locations);
    for (final file in files) {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileStream = http.MultipartFile.fromBytes(
        'files',
        await file.readAsBytes(),
        filename: file.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(fileStream);
    }
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (DetailedSelfProductResponse.fromJson(json), null);
      } else {
        final json = jsonDecode(response.body);
        final error = ErrorResponse.fromJson(json);
        return (null, error);
      }
    } catch (e) {
      return (null, ErrorResponse(status: 500, message: "An error occured", timestamp: DateTime.now()));
    }
  }
}