import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui'; // For BackdropFilter
import '../models/book.dart';
import '../services/books_service.dart';
import 'book_reader_screen.dart';
import 'pdf_reader_screen.dart';
import 'books_sales_screen.dart';
import 'book_upload_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<Book> allBooks = [];
  List<Book> filteredBooks = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch books from service
      final books = await BooksService.fetchBooks();

      // Load saved progress/favorites from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedDataStr = prefs.getString('books_user_data');
      if (savedDataStr != null) {
        final savedData = json.decode(savedDataStr) as Map<String, dynamic>;
        for (var book in books) {
          if (savedData.containsKey(book.id)) {
            final bookData = savedData[book.id];
            book.isFavorite = bookData['isFavorite'] ?? false;
            book.readingProgress = bookData['readingProgress']?.toDouble() ?? 0.0;
            book.isDownloaded = bookData['isDownloaded'] ?? false;
          }
        }
      }

      if (mounted) {
        setState(() {
          allBooks = books;
          filteredBooks = books;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading books: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          // You might want to show an error message or empty state here
          allBooks = [];
          filteredBooks = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load books: $e')),
        );
      }
    }
  }

  Future<void> _saveBookUserData(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDataStr = prefs.getString('books_user_data');
    Map<String, dynamic> savedData = {};
    if (savedDataStr != null) {
      savedData = json.decode(savedDataStr) as Map<String, dynamic>;
    }

    savedData[book.id] = {
      'isFavorite': book.isFavorite,
      'readingProgress': book.readingProgress,
      'isDownloaded': book.isDownloaded,
    };

    await prefs.setString('books_user_data', json.encode(savedData));
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredBooks = allBooks;
      } else {
        filteredBooks = allBooks.where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
                 book.author.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8), // Light, clean background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Library',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        actions: [

          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BooksSalesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookUploadScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadBooks,
              color: Colors.black,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search for books, authors...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  if (searchQuery.isNotEmpty)
                    _buildSearchResults()
                  else ...[
                    // Latest Books Section
                    SliverToBoxAdapter(
                      child: _buildLatestSection(),
                    ),

                    // Categories Sections
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final categories = BooksService.getCategories();
                          // Skip 'Latest' as it's handled separately
                          final category = categories[index + 1]; 
                          return _buildCategorySection(category);
                        },
                        childCount: BooksService.getCategories().length - 1,
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSearchResults() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildBookCard(filteredBooks[index]);
          },
          childCount: filteredBooks.length,
        ),
      ),
    );
  }

  Widget _buildLatestSection() {
    // Sort books by date (newest first)
    final latestBooks = List<Book>.from(allBooks)
      ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    
    // Take top 5
    final displayBooks = latestBooks.take(5).toList();

    if (displayBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Arrivals',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayBooks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 160,
                  child: _buildBookCard(displayBooks[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryBooks = allBooks.where((book) => book.category == category).toList();

    if (categoryBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            category,
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categoryBooks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 140,
                  child: _buildBookCard(categoryBooks[index], isSmall: true),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book, {bool isSmall = false}) {
    return GestureDetector(
      onTap: () => _showBookDetails(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'book_cover_${book.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: DecorationImage(
                    image: book.coverImageUrl.startsWith('assets') 
                        ? AssetImage(book.coverImageUrl) as ImageProvider
                        : NetworkImage(book.coverImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: book.readingProgress > 0 
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: LinearProgressIndicator(
                            value: book.readingProgress / 100,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                            minHeight: 4,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${book.downloadCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookDetails(Book book) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Book Details',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: book.coverImageUrl.startsWith('assets') 
                                        ? AssetImage(book.coverImageUrl) as ImageProvider
                                        : NetworkImage(book.coverImageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: GoogleFonts.judson(
                                        textStyle: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'by ${book.author}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.download_rounded, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${book.downloadCount} downloads',
                                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Description',
                            style: GoogleFonts.judson(
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (book.epubUrl != null && book.epubUrl!.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookReaderScreen(
                                            bookId: book.id,
                                            bookTitle: book.title,
                                            bookPath: book.coverImageUrl,
                                            isAsset: book.coverImageUrl.startsWith('assets'),
                                            cloudUrl: book.epubUrl!,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Navigate to PDF Reader
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PdfReaderScreen(
                                            book: book,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Read Now'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Handle download
                                    setState(() {
                                      book.isDownloaded = true;
                                    });
                                    _saveBookUserData(book);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Downloading ${book.title}...')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Colors.black),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Download'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
