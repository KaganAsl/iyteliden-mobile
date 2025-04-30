class AuthEntity {
  final String mail;
  final String password;

  AuthEntity({
    required this.mail,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'mail': mail,
      'password': password
    };
  }
}