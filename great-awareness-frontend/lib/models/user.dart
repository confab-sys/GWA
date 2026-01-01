class User {
  final String? id;
  final String? email;
  final String? name;
  final String? token;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? county;
  final String? profileImage;
  
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
    this.profileImage,
  });
  
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '${json['first_name']?.toString() ?? ''} ${json['last_name']?.toString() ?? ''}'.trim(),
      token: token ?? json['token']?.toString(),
      role: json['role']?.toString() ?? 'user',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      county: json['county']?.toString(),
      profileImage: json['profile_image']?.toString(),
    );
  }
  
  bool get isAdmin => role == 'admin';
  bool get canPost => isAdmin || role == 'content_creator';
}