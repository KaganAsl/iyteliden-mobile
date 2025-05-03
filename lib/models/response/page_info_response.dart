class PageInfoResponse {
  final int size;
  final int number;
  final int totalElements;
  final int totalPages;

  PageInfoResponse({
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  factory PageInfoResponse.fromJson(Map<String, dynamic> json) {
    return PageInfoResponse(
      size: json['size'],
      number: json['number'],
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
    );
  }
}