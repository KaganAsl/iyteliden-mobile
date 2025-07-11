import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:iyteliden_mobile/models/response/error_response.dart';
import 'package:iyteliden_mobile/models/response/location_response.dart';
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

  Future<(DetailedSelfProductResponse?, ErrorResponse?)> updateProduct(
    String jwt,
    int productId,
    Map<String, dynamic> productData,
    List<File> newFiles, // New images to upload
    List<int> locations, // Full list of location IDs for the product
    List<String> existingImageUrls, // URLs of existing images to keep
  ) async {
    // Basic validation for new files (if any) - can be adjusted
    if (newFiles.length > 6) { // Example: limit total new images
      return (
        null,
        ErrorResponse(message: 'You can upload a maximum of 6 new images.', status: 400, timestamp: DateTime.now())
      );
    }
    // Combined with existing, ensure total is not more than a limit (e.g., 6)
    if ((existingImageUrls.length + newFiles.length) > 6) {
       return (
        null,
        ErrorResponse(message: 'Total images (existing + new) cannot exceed 6.', status: 400, timestamp: DateTime.now())
      );
    }
    if ((existingImageUrls.isEmpty && newFiles.isEmpty)) {
       return (
        null,
        ErrorResponse(message: 'Product must have at least one image.', status: 400, timestamp: DateTime.now())
      );
    }
    if (locations.isEmpty) {
      return (
        null,
        ErrorResponse(message: 'At least one location must be provided.', status: 400, timestamp: DateTime.now())
      );
    }

    final uri = Uri.parse('$url/products/$productId'); // Assuming PUT request to /products/{id}
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = jwt;

    // Add productData as a JSON part
    final productJson = jsonEncode(productData);
    request.files.add(
      http.MultipartFile.fromString(
        'product', // Corresponds to DTO in backend
        productJson,
        contentType: MediaType('application', 'json'),
      )
    );

    // Add locations as a JSON part
    final locationsJson = jsonEncode(locations);
    request.files.add(
      http.MultipartFile.fromString(
        'locations', // Corresponds to DTO in backend
        locationsJson,
        contentType: MediaType('application', 'json'),
      )
    );

    // Add existingImageUrls as a JSON part (list of strings)
    final existingImagesJson = jsonEncode(existingImageUrls);
    request.files.add(
      http.MultipartFile.fromString(
        'existingImageUrls', // Key for backend to identify images to keep
        existingImagesJson,
        contentType: MediaType('application', 'json'),
      )
    );

    // Add new image files
    for (final file in newFiles) {
      final String fileName = file.path.split('/').last;
      final String extension = fileName.split('.').last.toLowerCase();
      
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        // Add other image types if necessary
        default:
          mimeType = 'application/octet-stream'; // Fallback or throw error
      }
      
      final bytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile(
        'files', // Key for new files in backend
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
      return (null, ErrorResponse(status: 500, message: "An error occurred: ${e.toString()}", timestamp: DateTime.now()));
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
    try {
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

        // Check favorite status for all products concurrently
        if (products.isNotEmpty) {
          final productIds = products.map((p) => p.productId).toList();
          final favoriteMap = await FavoriteService().checkMultipleFavorites(jwt, productIds);
          
          // Apply favorite statuses
          for (var product in products) {
            product.isLiked = favoriteMap[product.productId] ?? false;
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
    } catch (e) {
      return (null, ErrorResponse(
        status: 500, 
        message: "Error processing products: ${e.toString()}", 
        timestamp: DateTime.now()
      ));
    }
  }

  Future<(SimpleProductListResponse?, ErrorResponse?)> searchProducts(String jwt, String query, int page) async {
    try {
      final response = await http.get(
        Uri.parse('$url/products/search?query=$query&page=$page'),
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

        // Check favorite status for all products concurrently
        if (products.isNotEmpty) {
          final productIds = products.map((p) => p.productId).toList();
          final favoriteMap = await FavoriteService().checkMultipleFavorites(jwt, productIds);
          
          // Apply favorite statuses
          for (var product in products) {
            product.isLiked = favoriteMap[product.productId] ?? false;
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
    } catch (e) {
      return (null, ErrorResponse(
        status: 500, 
        message: "Error processing search results: ${e.toString()}", 
        timestamp: DateTime.now()
      ));
    }
  }

  Future<(SimpleProductListResponse?, ErrorResponse?)> getProductsByLocation(String jwt, int locationId, int page) async {
    try {
      final response = await http.get(
        Uri.parse('$url/products/location/$locationId?page=$page'), // Assumed endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': jwt
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        SimpleProductListResponse productList = SimpleProductListResponse.fromJson(json);

        // Check favorite status for all products concurrently
        if (productList.content.isNotEmpty) {
          final productIds = productList.content.map((p) => p.productId).toList();
          final favoriteMap = await FavoriteService().checkMultipleFavorites(jwt, productIds);
          
          // Apply favorite statuses
          for (var product in productList.content) {
            product.isLiked = favoriteMap[product.productId] ?? false;
          }
        }
        
        return (productList, null);
      } else {
        final json = jsonDecode(response.body);
        final error = ErrorResponse.fromJson(json);
        return (null, error);
      }
    } catch (e) {
      return (null, ErrorResponse(
        status: 500, 
        message: "Error fetching products by location: ${e.toString()}", 
        timestamp: DateTime.now()
      ));
    }
  }

  Future<(SimpleProductListResponse?, ErrorResponse?)> getProductsByCategory(String jwt, int categoryId, int page) async {
    try {
      final response = await http.get(
        Uri.parse('$url/products/categoryId/$categoryId?page=$page'), // New endpoint for categories
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': jwt
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        SimpleProductListResponse productList = SimpleProductListResponse.fromJson(json);

        // Check favorite status for all products concurrently
        if (productList.content.isNotEmpty) {
          final productIds = productList.content.map((p) => p.productId).toList();
          final favoriteMap = await FavoriteService().checkMultipleFavorites(jwt, productIds);
          
          // Apply favorite statuses
          for (var product in productList.content) {
            product.isLiked = favoriteMap[product.productId] ?? false;
          }
        }
        
        return (productList, null);
      } else {
        final json = jsonDecode(response.body);
        final error = ErrorResponse.fromJson(json);
        return (null, error);
      }
    } catch (e) {
      return (null, ErrorResponse(
        status: 500, 
        message: "Error fetching products by category: ${e.toString()}", 
        timestamp: DateTime.now()
      ));
    }
  }

  Future<(List<Location>?, ErrorResponse?)> getProductLocations(String jwt, int productId) async {
    final response = await http.get(
      Uri.parse('$url/products/locationsof/$productId'),
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': jwt
      }
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final locations = jsonList.map((json) => Location.fromJson(json)).toList();
      return (locations, null);
    } else {
      final json = jsonDecode(response.body);
      final error = ErrorResponse.fromJson(json);
      return (null, error);
    }
  }
}