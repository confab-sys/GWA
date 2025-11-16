class Content {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  Content({required this.id, required this.title, required this.body, this.createdAt});
  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['text'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}