class SelfUserResponse {
  final int userId;
  final String userName;
  final String mail;
  final String status;

  SelfUserResponse({
    required this.userId,
    required this.userName,
    required this.mail,
    required this.status,
  });

  factory SelfUserResponse.fromJson(Map<String, dynamic> json) {
    return SelfUserResponse(
      userId: json['userId'],
      userName: json['userName'],
      mail: json['mail'],
      status: json['status']
    );
  }
}