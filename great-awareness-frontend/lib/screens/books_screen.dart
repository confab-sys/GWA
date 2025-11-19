import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class Book {
  final String id;
  final String title;
  final String imagePath;
  final String description;
  bool isFavorite;
  double readingProgress;
  bool isDownloaded;

  Book({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.description,
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

class _BooksScreenState extends State<BooksScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    // Initialize books from assets
    final initialBooks = [
      Book(
        id: '1',
        title: 'Breaking Free from Masturbation',
        imagePath: 'assets/images/Breaking free from mastubation.png',
        description: 'A comprehensive guide to understanding and overcoming compulsive behaviors.',
      ),
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
      ),
    ];

    // Load saved data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedBooksData = prefs.getString('books_data');
    
    if (savedBooksData != null) {
      try {
        final List<dynamic> decodedList = json.decode(savedBooksData);
        final savedBooks = decodedList.map((item) => Book.fromJson(item)).toList();
        
        // Merge saved data with initial books
        for (var i = 0; i < initialBooks.length; i++) {
          final savedBook = savedBooks.firstWhere(
            (book) => book.id == initialBooks[i].id,
            orElse: () => initialBooks[i],
          );
          initialBooks[i] = savedBook;
        }
      } catch (e) {
        print('Error loading saved books: $e');
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Books',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : books.isEmpty
              ? Center(
                  child: Text(
                    'No books available',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _buildBookCard(book);
                  },
                ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Hero(
      tag: 'book_${book.id}',
      child: Card(
        color: Colors.grey[900],
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to book reader or details screen
            _showBookDetails(book);
          },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: DecorationImage(
                        image: AssetImage(book.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Reading progress indicator
                  if (book.readingProgress > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
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
                                  backgroundColor: Colors.grey[700],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              child: Text('${book.readingProgress.toInt()}%'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite and action buttons
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Download button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: book.isDownloaded ? Colors.green.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                book.isDownloaded ? Icons.check : Icons.download,
                                color: Colors.white,
                                size: 14,
                                key: ValueKey<bool>(book.isDownloaded),
                              ),
                            ),
                            onPressed: book.isDownloaded ? null : () => _downloadBook(book),
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Favorite button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: Icon(
                                book.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: book.isFavorite ? Colors.red : Colors.white,
                                size: 14,
                                key: ValueKey<bool>(book.isFavorite),
                              ),
                            ),
                            onPressed: () => _toggleFavorite(book),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      book.description,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          constraints: const BoxConstraints(maxWidth: 400),
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
    );
  }
}