import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';
import 'book_reader_screen.dart';

class BooksSalesScreen extends StatefulWidget {
  const BooksSalesScreen({super.key});

  @override
  State<BooksSalesScreen> createState() => _BooksSalesScreenState();
}

class _BooksSalesScreenState extends State<BooksSalesScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    // Initialize books from assets - only the specific books for sales
    final initialBooks = [
      Book(
        id: '1',
        title: 'Resonance: Understanding Your Potential',
        author: 'Unknown',
        category: 'General',
        coverImageUrl: 'assets/images/Resonance, understanding the magnetic pull towards your unrealised potential.png',
        description: 'Discover the magnetic pull towards your unrealized potential.',
      ),
      Book(
        id: '2',
        title: 'Master Your Finances',
        author: 'Unknown',
        category: 'Finances',
        coverImageUrl: 'assets/images/Master your finances, how the primal brain hijacks your financial decisions.png',
        description: 'Learn how your brain influences financial decisions and how to take control.',
      ),
      Book(
        id: '3',
        title: 'The Secret Behind Romantic Love',
        author: 'Unknown',
        category: 'Relationships',
        coverImageUrl: 'assets/images/The secret behind romantic love, understanding the hidden force that influences relationships.png',
        description: 'Understanding the hidden force that influences relationships.',
      ),
    ];

    // Load saved data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedBooksData = prefs.getString('books_sales_data');
    
    // Clear old data to force fresh load
    await prefs.remove('books_sales_data');
    print('Cleared old books sales data - loading fresh books');

    setState(() {
      books = initialBooks;
      isLoading = false;
    });
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = books.map((book) => book.toJson()).toList();
    await prefs.setString('books_sales_data', json.encode(booksJson));
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
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Books Sales',
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : books.isEmpty
              ? Center(
                  child: Text(
                    'No books available for sale',
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
    );
  }

  Widget _buildBookCard(Book book) {
    return Hero(
      tag: 'book_sales_${book.id}',
      child: GestureDetector(
        onTap: () {
          _showBookDetails(book);
        },
        child: Image.asset(
             book.coverImageUrl,
             fit: BoxFit.cover, // Fill entire container to eliminate gaps
             alignment: Alignment.center,
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
                      image: AssetImage(book.coverImageUrl),
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