class BidRequest {
  final int productId;
  final double price;
  final int locationId;

  BidRequest({
    required this.productId,
    required this.price,
    required this.locationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'price': price,
      'locationId': locationId,
    };
  }
}