class User {
  final String id;
  final String email;
  final String? name;
  final String? token;
  final String? role;
  
  User({
    required this.id, 
    required this.email, 
    this.name, 
    this.token,
    this.role,
  });
  
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      token: token ?? json['token'],
      role: json['role'] ?? 'user',
    );
  }
  
  bool get isAdmin => role == 'admin';
  bool get canPost => isAdmin || role == 'content_creator';
}