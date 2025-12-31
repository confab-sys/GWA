class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final String description;
  final String coverImageUrl;
  final String? fileKey;
  final String? epubUrl; // For backward compatibility or direct URL
  final int downloadCount;
  final DateTime? createdAt;
  final int pageCount;
  final int estimatedReadTime;
  final String accessLevel;
  final bool downloadAllowed;
  final bool streamReadAllowed;
  final bool onSale;
  final bool availableToRead;
  final double price;
  bool isFavorite;
  double readingProgress;
  bool isDownloaded;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.coverImageUrl,
    this.fileKey,
    this.epubUrl,
    this.downloadCount = 0,
    this.createdAt,
    this.pageCount = 0,
    this.estimatedReadTime = 0,
    this.accessLevel = 'free',
    this.downloadAllowed = true,
    this.streamReadAllowed = true,
    this.onSale = false,
    this.availableToRead = false,
    this.price = 0.0,
    this.isFavorite = false,
    this.readingProgress = 0.0,
    this.isDownloaded = false,
  });

  static const String _workerUrl = 'https://gwa-books-worker.aashardcustomz.workers.dev';

  factory Book.fromJson(Map<String, dynamic> json) {
    String coverUrl = json['cover_image_url'] ?? json['imagePath'] ?? '';
    // If it's a key (starts with books/), use the worker endpoint
    if (coverUrl.startsWith('books/')) {
      coverUrl = '$_workerUrl/books/${json['id']}/cover';
    }

    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      category: json['category'] ?? 'Uncategorized',
      description: json['description'] ?? '',
      coverImageUrl: coverUrl,
      fileKey: json['file_key'],
      epubUrl: json['epubUrl'],
      downloadCount: json['download_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      pageCount: json['page_count'] ?? 0,
      estimatedReadTime: json['estimated_read_time_minutes'] ?? 0,
      accessLevel: json['access_level'] ?? 'free',
      downloadAllowed: (json['download_allowed'] == 1 || json['download_allowed'] == true),
      streamReadAllowed: (json['stream_read_allowed'] == 1 || json['stream_read_allowed'] == true),
      onSale: json['on_sale'].toString().toUpperCase() == 'YES' || json['on_sale'] == true || json['on_sale'] == 1,
      availableToRead: json['available_to_read'].toString().toUpperCase() == 'YES' || json['available_to_read'] == true || json['available_to_read'] == 1,
      price: json['price']?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] ?? false,
      readingProgress: json['readingProgress']?.toDouble() ?? 0.0,
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'cover_image_url': coverImageUrl,
      'imagePath': coverImageUrl, // Keep legacy field populated
      'file_key': fileKey,
      'epubUrl': epubUrl,
      'download_count': downloadCount,
      'created_at': createdAt?.toIso8601String(),
      'on_sale': onSale ? 'YES' : 'NO',
      'available_to_read': availableToRead ? 'YES' : 'NO',
      'price': price,
      'isFavorite': isFavorite,
      'readingProgress': readingProgress,
      'isDownloaded': isDownloaded,
    };
  }
}
