class ReviewRequest {
  final int recipientId;
  final String content;
  final int rating;
  final int productId;
  final int bidId;

  ReviewRequest({
    required this.recipientId,
    required this.content,
    required this.rating,
    required this.productId,
    required this.bidId,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'content': content,
      'rating': rating,
      'productId': productId,
      'bidId': bidId,
    };
  }
}