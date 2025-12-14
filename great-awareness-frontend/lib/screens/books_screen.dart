import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'book_reader_screen.dart';
import 'books_sales_screen.dart';
import 'book_upload_screen.dart';


class Book {
  final String id;
  final String title;
  final String imagePath;
  final String description;
  final String? epubUrl; // Cloudflare R2 URL for EPUB
  bool isFavorite;
  double readingProgress;
  bool isDownloaded;

  Book({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.description,
    this.epubUrl,
    this.isFavorite = false,
    this.readingProgress = 0.0,
    this.isDownloaded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'description': description,
      'epubUrl': epubUrl,
      'isFavorite': isFavorite,
      'readingProgress': readingProgress,
      'isDownloaded': isDownloaded,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      imagePath: json['imagePath'],
      description: json['description'],
      epubUrl: json['epubUrl'],
      isFavorite: json['isFavorite'] ?? false,
      readingProgress: json['readingProgress']?.toDouble() ?? 0.0,
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }
}

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  List<Book> books = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    // Initialize books from assets
    final initialBooks = [
      Book(
        id: '2',
        title: 'Master Your Finances',
        imagePath: 'assets/images/Master your finances, how the primal brain hijacks your financial decisions.png',
        description: 'Learn how your brain influences financial decisions and how to take control.',
      ),
      Book(
        id: '3',
        title: 'Resonance: Understanding Your Potential',
        imagePath: 'assets/images/Resonance, understanding the magnetic pull towards your unrealised potential.png',
        description: 'Discover the magnetic pull towards your unrealized potential.',
      ),
      Book(
        id: '4',
        title: 'The Woman: Power of the Feminine',
        imagePath: 'assets/images/The Woman, power of the feminine.png',
        description: 'Exploring the power and essence of feminine energy.',
      ),
      Book(
        id: '5',
        title: 'The Power Within: Emotions Secret',
        imagePath: 'assets/images/The power within, the secret behind emotions that you didnt know.png',
        description: 'Uncover the secret behind emotions that you didn\'t know.',
      ),
      Book(
        id: '6',
        title: 'The Secret Behind Romantic Love',
        imagePath: 'assets/images/The secret behind romantic love, understanding the hidden force that influences relationships.png',
        description: 'Understanding the hidden force that influences relationships.',
      ),
      Book(
        id: '7',
        title: 'Unlocking the Primal Brain',
        imagePath: 'assets/images/Unlocking the primal brainThe hidden force shaping your thoughts and emotions.png',
        description: 'Discover the hidden force shaping your thoughts and emotions.',
        epubUrl: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/Unlocking%20the%20primal%20brain%20The%20hidden%20force%20shaping%20your%20thoughts%20and%20emotions.epub',
      ),
      Book(
        id: '8',
        title: 'Confidence: Rewiring the Primal Brain',
        imagePath: 'assets/images/confidence , rewiring the primal brain to lead with power,not fear.png',
        description: 'Rewire your primal brain to lead with power, not fear.',
      ),
      Book(
        id: '9',
        title: 'No More Confusion: Finding Your Calling',
        imagePath: 'assets/images/no more confusion, the real reason why you avent found your calling yet.png',
        description: 'The real reason why you haven\'t found your calling yet.',
        epubUrl: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/no%20more%20confusion%2C%20the%20real%20reason%20why%20you%20avent%20found%20your%20calling%20yet.epub',
      ),
    ];

    // Load saved data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedBooksData = prefs.getString('books_data');
    
    // Clear old data to force fresh load with new R2 URLs
    await prefs.remove('books_data');
    print('Cleared old books data - loading fresh books with R2 URLs');
    
    // Debug: Show which books have EPUB URLs
    for (var book in initialBooks) {
      print('Book ${book.id}: ${book.title} - EPUB URL: ${book.epubUrl ?? "NOT AVAILABLE"}');
    }

    setState(() {
      books = initialBooks;
      isLoading = false;
    });
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = books.map((book) => book.toJson()).toList();
    await prefs.setString('books_data', json.encode(booksJson));
  }

  void _toggleFavorite(Book book) {
    setState(() {
      book.isFavorite = !book.isFavorite;
    });
    _saveBooks();
  }

  void _updateReadingProgress(Book book, double progress) {
    setState(() {
      book.readingProgress = progress.clamp(0.0, 100.0);
    });
    _saveBooks();
  }

  Future<void> _downloadBook(Book book) async {
    // Simulate download process
    setState(() {
      book.isDownloaded = true;
    });
    _saveBooks();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${book.title} downloaded successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Books',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Main Books'),
            Tab(text: 'On Sale'),
          ],
          labelStyle: GoogleFonts.judson(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          unselectedLabelStyle: GoogleFonts.judson(
            textStyle: const TextStyle(
              fontSize: 14,
            ),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.black,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookUploadScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Main Books Tab
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : books.isEmpty
                  ? Center(
                      child: Text(
                        'No books available',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 books per row
                        childAspectRatio: 0.7, // Adjusted for vertical layout
                        crossAxisSpacing: 16, // Space between books horizontally
                        mainAxisSpacing: 16, // Space between books vertically
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _buildBookCard(book);
                      },
                    ),
          // On Sale Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Special Book Offers',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Get these exclusive books at special prices',
                  style: GoogleFonts.judson(
                    textStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BooksSalesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View Books on Sale',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Hero(
      tag: 'book_${book.id}',
      child: GestureDetector(
        onTap: () {
          // Navigate to book reader if EPUB URL is available
          if (book.epubUrl != null) {
            print('Opening book: ${book.title} with URL: ${book.epubUrl}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookReaderScreen(
                  bookId: book.id,
                  bookTitle: book.title,
                  bookPath: book.imagePath,
                  isAsset: false,
                  cloudUrl: book.epubUrl!,
                ),
              ),
            ).then((_) {
              print('Book reader closed for: ${book.title}');
            }).catchError((error) {
              print('Error opening book reader: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error opening book: $error')),
              );
            });
          } else {
            // Show message if no EPUB available
            print('No EPUB URL for book: ${book.title}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('EPUB version not available for this book')),
            );
          }
        },
        child: Stack(
          children: [
            // Full cover image
            Positioned.fill(
              child: Image.asset(
                book.imagePath,
                fit: BoxFit.contain, // Show full cover without cropping
                alignment: Alignment.center,
              ),
            ),
            // Reading progress indicator
            if (book.readingProgress > 0)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                          child: LinearProgressIndicator(
                            value: book.readingProgress / 100,
                            backgroundColor: Colors.grey[400],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text('${book.readingProgress.toInt()}%'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBookDetails(Book book) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Book Details',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                book.title,
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(book.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                book.description,
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (book.readingProgress > 0) ...[
                Text(
                  'Reading Progress: ${book.readingProgress.toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Slider(
                    value: book.readingProgress,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[700],
                    onChanged: (value) {
                      setState(() {
                        book.readingProgress = value;
                      });
                      _saveBooks();
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleFavorite(book),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          book.isFavorite ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey<bool>(book.isFavorite),
                        ),
                      ),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          book.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                          key: ValueKey<bool>(book.isFavorite),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: book.isFavorite ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (!book.isDownloaded)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadBook(book);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}