import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/page_info_response.dart';
import 'package:iyteliden_mobile/models/response/product_response.dart';
import 'package:iyteliden_mobile/utils/dotenv.dart';
import 'package:iyteliden_mobile/services/favorite_service.dart';

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
    
    // Add product as a JSON part with explicit content type
    final productJson = jsonEncode(product);
    request.files.add(
      http.MultipartFile.fromString(
        'product',
        productJson,
        contentType: MediaType('application', 'json'),
      )
    );
    
    // Add locations as a JSON part with explicit content type
    final locationsJson = jsonEncode(locations);
    request.files.add(
      http.MultipartFile.fromString(
        'locations',
        locationsJson,
        contentType: MediaType('application', 'json'),
      )
    );
    
    // Add image files without specifying content type
    for (final file in files) {
      final String fileName = file.path.split('/').last;
      final String extension = fileName.split('.').last.toLowerCase();
      
      // Set MIME type based on extension
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default to JPEG
      }
      
      final bytes = await file.readAsBytes();
      
      final multipartFile = http.MultipartFile(
        'files',
        http.ByteStream.fromBytes(bytes),
        bytes.length,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
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

  Future<ErrorResponse?> deleteProduct(String jwt, int productId) async {
    final response = await http.delete(
      Uri.parse('$url/products/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return null;
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return error;
    }
  }

  Future<(SimpleProductListResponse?, ErrorResponse?)> getAllProducts(String jwt, int page) async {
    final response = await http.get(
      Uri.parse('$url/products/main?page=$page'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      List<SimpleProductResponse> products;
      if (json is List) {
        products = json.map((item) => SimpleProductResponse.fromJson(item)).toList();
      } else {
        products = SimpleProductListResponse.fromJson(json).content;
      }

      // Check favorite status for each product
      for (var product in products) {
        final (isFavorite, error) = await FavoriteService().checkFavorite(jwt, product.productId);
        if (error == null) {
          product.isLiked = isFavorite;
        }
      }

      return (
        SimpleProductListResponse(
          content: products,
          page: json is List 
            ? PageInfoResponse(
                size: products.length,
                number: page,
                totalElements: products.length,
                totalPages: 1,
              )
            : SimpleProductListResponse.fromJson(json).page,
        ),
        null
      );
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}