import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class BookReaderScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String bookPath;
  final bool isAsset;
  final String? cloudUrl;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.bookPath,
    this.isAsset = true,
    this.cloudUrl,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = true;
  String? _downloadedFilePath;
  String _currentLocation = '';
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeBook();
  }

  Future<void> _initializeBook() async {
    try {
      if (widget.isAsset) {
        // For asset books, copy to temporary directory
        final bytes = await rootBundle.load(widget.bookPath);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.bookId}.epub');
        await tempFile.writeAsBytes(bytes.buffer.asUint8List());
        _downloadedFilePath = tempFile.path;
      } else if (widget.cloudUrl != null) {
        // For cloud books, download first
        await _downloadBookFromCloud();
      } else {
        // For already downloaded books
        _downloadedFilePath = widget.bookPath;
      }

      if (_downloadedFilePath != null) {
        await _loadLastReadingPosition();
      }
    } catch (e) {
      print('Error initializing book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading book: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadBookFromCloud() async {
    try {
      final response = await http.get(Uri.parse(widget.cloudUrl!));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.bookId}.epub');
        await tempFile.writeAsBytes(response.bodyBytes);
        _downloadedFilePath = tempFile.path;
      } else {
        throw Exception('Failed to download book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading book: $e');
    }
  }

  Future<void> _loadLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('book_location_${widget.bookId}');
    if (savedLocation != null) {
      _currentLocation = savedLocation;
    }
  }

  Future<void> _saveReadingProgress(String locator) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book_location_${widget.bookId}', locator);
    
    // Calculate reading progress based on current location
    setState(() {
      _readingProgress = _calculateReadingProgress(locator);
    });
  }

  double _calculateReadingProgress(String locator) {
    // This is a simplified progress calculation
    // You might want to implement a more sophisticated algorithm based on your book structure
    try {
      if (locator.isNotEmpty) {
        // Extract chapter number from locator (simplified)
        final chapterMatch = RegExp(r'chapter(\d+)').firstMatch(locator.toLowerCase());
        if (chapterMatch != null) {
          final chapter = int.tryParse(chapterMatch.group(1) ?? '0') ?? 0;
          return (chapter / 20).clamp(0.0, 1.0); // Assuming ~20 chapters
        }
      }
    } catch (e) {
      print('Error calculating progress: $e');
    }
    return 0.0;
  }

  void _openBook() {
    if (_downloadedFilePath == null) return;

    // Configure the EPUB viewer
    VocsyEpub.setConfig(
      themeColor: Theme.of(context).primaryColor,
      identifier: widget.bookId,
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: true,
    );

    // Listen for location changes to save progress
    VocsyEpub.locatorStream.listen((locator) {
      _saveReadingProgress(locator);
    });

    // Open the book
    VocsyEpub.open(
      _downloadedFilePath!,
      lastLocation: _currentLocation.isNotEmpty
          ? EpubLocator.fromJson(jsonDecode(_currentLocation))
          : null,
    );
  }

  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Settings',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.format_size),
              title: Text('Font Size', style: GoogleFonts.judson()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showFontSizeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text('Theme', style: GoogleFonts.judson()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showThemeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text('Bookmarks', style: GoogleFonts.judson()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showBookmarks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Reading Progress', style: GoogleFonts.judson()),
              trailing: Text(
                '${(_readingProgress * 100).toInt()}%',
                style: GoogleFonts.judson(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    double currentFontSize = 16.0; // Default font size
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Font Size', style: GoogleFonts.judson()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: currentFontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: currentFontSize.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    currentFontSize = value;
                  });
                  // Implement font size change
                  // This would require restarting the EPUB viewer with new settings
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reading Theme', style: GoogleFonts.judson()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: Text('Light Theme', style: GoogleFonts.judson()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: Text('Dark Theme', style: GoogleFonts.judson()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text('Sepia Theme', style: GoogleFonts.judson()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmarks feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.bookTitle, style: GoogleFonts.judson()),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.bookTitle,
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showReadingSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to Read',
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the button below to start reading',
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_readingProgress > 0) ...[
              Text(
                'Continue reading - ${(_readingProgress * 100).toInt()}% completed',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            ElevatedButton.icon(
              onPressed: _openBook,
              icon: const Icon(Icons.menu_book),
              label: Text(
                _readingProgress > 0 ? 'Continue Reading' : 'Start Reading',
                style: GoogleFonts.judson(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}