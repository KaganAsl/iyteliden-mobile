import 'package:iyteliden_mobile/models/response/page_info_response.dart';

class SimpleProductResponse {
  final int productId;
  final String? coverImage; // actually keyName for image service.
  final String productName;
  final double price;

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