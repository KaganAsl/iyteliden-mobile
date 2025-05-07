
import 'package:iyteliden_mobile/models/response/category_response.dart';
import 'package:iyteliden_mobile/models/response/location_response.dart';
import 'package:iyteliden_mobile/models/response/page_info_response.dart';
import 'package:iyteliden_mobile/models/response/user_response.dart';

class SimpleSelfProductResponse {
  final int productId;
  final String? coverImage; // actually keyName for image service.
  final String productName;
  final double price;

  SimpleSelfProductResponse({
    required this.productId,
    this.coverImage,
    required this.productName,
    required this.price,
  });

  factory SimpleSelfProductResponse.fromJson(Map<String, dynamic> json) {
    return SimpleSelfProductResponse(
      productId: json['productId'],
      coverImage: json['coverImage'],
      productName: json['productName'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class SimpleProductResponse {
  final int productId;
  final String? coverImage; // actually keyName for image service.
  final String productName;
  final double price;
  bool? isLiked;

  SimpleProductResponse({
    required this.productId,
    this.coverImage,
    required this.productName,
    required this.price,
  });

  factory SimpleProductResponse.fromJson(Map<String, dynamic> json) {
    return SimpleProductResponse(
      productId: json['productId'],
      coverImage: json['coverImage'],
      productName: json['productName'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class SimpleSelfProductListResponse {
  
  final List<SimpleSelfProductResponse> content;
  final PageInfoResponse page;

  SimpleSelfProductListResponse({
    required this.content,
    required this.page,
  });

  factory SimpleSelfProductListResponse.fromJson(Map<String, dynamic> json) {
    return SimpleSelfProductListResponse(
      content: (json['content'] as List).map((item) => SimpleSelfProductResponse.fromJson(item)).toList(),
      page: PageInfoResponse.fromJson(json['page']),
    );
  }
}

class SimpleProductListResponse {
  
  final List<SimpleProductResponse> content;
  final PageInfoResponse page;

  SimpleProductListResponse({
    required this.content,
    required this.page,
  });

  factory SimpleProductListResponse.fromJson(Map<String, dynamic> json) {
    return SimpleProductListResponse(
      content: (json['content'] as List).map((item) => SimpleProductResponse.fromJson(item)).toList(),
      page: PageInfoResponse.fromJson(json['page']),
    );
  }
}

class DetailedProductResponse {

  final int productId;
  final UserResponse user;
  final CategoryResponse category;
  final List<String> imageUrls;
  final String productName;
  final String description;
  final double price;
  final List<Location> locations;
  bool? isLiked;

  DetailedProductResponse({
    required this.productId,
    required this.user,
    required this.category,
    required this.imageUrls,
    required this.productName,
    required this.description,
    required this.price,
    required this.locations,
  });

  factory DetailedProductResponse.fromJson(Map<String, dynamic> json) {
    return DetailedProductResponse(
      productId: json['productId'],
      user: UserResponse.fromJson(json['user']),
      category: CategoryResponse.fromJson(json['category']),
      imageUrls: List<String>.from(json['imageUrls']),
      productName: json['productName'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      locations: (json['locations'] as List)
          .map((item) => Location.fromJson(item))
          .toList(),
    );
  }
}

class DetailedSelfProductResponse {

  final int productId;
  final UserResponse user;
  final CategoryResponse category;
  final List<String> imageUrls;
  final String productName;
  final String description;
  final double price;
  final List<Location> locations;

  DetailedSelfProductResponse({
    required this.productId,
    required this.user,
    required this.category,
    required this.imageUrls,
    required this.productName,
    required this.description,
    required this.price,
    required this.locations,
  });

  factory DetailedSelfProductResponse.fromJson(Map<String, dynamic> json) {
    return DetailedSelfProductResponse(
      productId: json['productId'],
      user: UserResponse.fromJson(json['user']),
      category: CategoryResponse.fromJson(json['category']),
      imageUrls: List<String>.from(json['imageUrls']),
      productName: json['productName'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      locations: (json['locations'] as List)
          .map((item) => Location.fromJson(item))
          .toList(),
    );
  }
}