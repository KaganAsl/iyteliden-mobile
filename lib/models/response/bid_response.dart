class BidResponse {
  final int bidId;
  final int productId;
  final int bidderId;
  final String bidderName;
  final double price;
  final String status;
  final DateTime datetime;
  final String productName;

  BidResponse({
    required this.bidId,
    required this.productId,
    required this.bidderId,
    required this.bidderName,
    required this.price,
    required this.status,
    required this.datetime,
    required this.productName,
  });

  factory BidResponse.fromJson(Map<String, dynamic> json) {
    return BidResponse(
      bidId: json['bidId'] as int,
      productId: json['productId'] as int,
      bidderId: json['bidderId'] as int,
      bidderName: json['bidderName'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      datetime: DateTime.parse(json['datetime'] as String),
      productName: json['productName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bidId': bidId,
      'productId': productId,
      'bidderId': bidderId,
      'bidderName': bidderName,
      'price': price,
      'status': status,
      'datetime': datetime.toIso8601String(),
      'productName': productName,
    };
  }
}
