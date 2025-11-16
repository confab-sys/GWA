class User {
  final String id;
  final String email;
  final String? name;
  final String? token;
  User({required this.id, required this.email, this.name, this.token});
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      token: token ?? json['token'],
    );
  }
}