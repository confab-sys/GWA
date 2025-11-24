class User {
  final String id;
  final String email;
  final String? name;
  final String? token;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? county;
  
  User({
    required this.id, 
    required this.email, 
    this.name, 
    this.token,
    this.role,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.county,
  });
  
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      token: token ?? json['token'],
      role: json['role'] ?? 'user',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      county: json['county'],
    );
  }
  
  bool get isAdmin => role == 'admin';
  bool get canPost => isAdmin || role == 'content_creator';
}