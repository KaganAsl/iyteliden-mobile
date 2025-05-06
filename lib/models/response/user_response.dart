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

class UserResponse {
  final int userId;
  final String userName;

  UserResponse({
    required this.userId,
    required this.userName,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(userId: json['userId'], userName: json['userName']);
  }
}