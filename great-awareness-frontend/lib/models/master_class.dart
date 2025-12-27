class MasterClass {
  final String id;
  final String title;
  final String imageUrl;

  MasterClass({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory MasterClass.fromJson(Map<String, dynamic> json) {
    return MasterClass(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
