class Podcast {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String duration;
  final double listenProgress;
  final String thumbnailUrl;
  final String audioUrl;
  final DateTime createdAt;
  bool isFavorite;
  bool isSaved;

  Podcast({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    required this.category,
    this.duration = '',
    this.listenProgress = 0.0,
    this.thumbnailUrl = '',
    this.audioUrl = '',
    required this.createdAt,
    this.isFavorite = false,
    this.isSaved = false,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Podcast',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      duration: json['duration'] ?? '',
      // Default to 0.0 since we don't have progress tracking in DB yet
      listenProgress: 0.0, 
      thumbnailUrl: json['thumbnail_url'] ?? json['video_thumbnail_url'] ?? '',
      // Prefer signed_url, fallback to object_key if needed (though object_key isn't a URL)
      audioUrl: json['signed_url'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      // Default local states
      isFavorite: false,
      isSaved: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category,
      'duration': duration,
      'listenProgress': listenProgress,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'isSaved': isSaved,
    };
  }
}
