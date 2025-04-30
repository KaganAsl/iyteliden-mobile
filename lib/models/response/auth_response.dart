class AuthResponse {
  final String authorization;
  final int expireSeconds;

  AuthResponse({
    required this.authorization,
    required this.expireSeconds,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      authorization: json['authorization'],
      expireSeconds: json['expireSeconds'],
    );
  }
}