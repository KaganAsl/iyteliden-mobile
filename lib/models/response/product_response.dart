import 'package:iyteliden_mobile/models/response/page_info_response.dart';

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