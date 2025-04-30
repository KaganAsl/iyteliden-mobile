class ErrorResponse {
  final int status;
  final String message;
  final DateTime timestamp;

  ErrorResponse({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      status: json['status'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}