import 'package:iyteliden_mobile/models/response/page_info_response.dart';

class ReviewResponse {
  final int reviewId;
  final int writerId;
  final int recipientId;
  final String content;
  final int rating;
  final int productId;

  ReviewResponse({
    required this.reviewId,
    required this.writerId,
    required this.recipientId,
    required this.content,
    required this.rating,
    required this.productId,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      reviewId: json['reviewId'],
      writerId: json['writerId'],
      recipientId: json['recipientId'],
      content: json['content'],
      rating: json['rating'],
      productId: json['productId'],
    );
  }
}

class ReviewListResponse {
  final List<ReviewResponse> content;
  final PageInfoResponse page;

  ReviewListResponse({
    required this.content,
    required this.page,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    return ReviewListResponse(
      content: (json['content'] as List)
          .map((item) => ReviewResponse.fromJson(item))
          .toList(),
      page: PageInfoResponse.fromJson(json['page']),
    );
  }
}