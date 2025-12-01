import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
  EpubBook? _epubBook;
  List<EpubChapter> _chapters = [];
  int _currentChapterIndex = 0;
  String _currentChapterContent = "";
  double _readingProgress = 0.0;
  bool _showControls = true;

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
        await _loadEpubBook();
        await _loadLastReadingPosition();
      }
    } catch (e) {
      debugPrint('Error initializing book: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading book: $e')),
        );
      }
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
      debugPrint('Downloading book from: ${widget.cloudUrl}');
      final response = await http.get(Uri.parse(widget.cloudUrl!));
      debugPrint('Download response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.bookId}.epub');
        await tempFile.writeAsBytes(response.bodyBytes);
        _downloadedFilePath = tempFile.path;
        debugPrint('Book downloaded successfully to: ${_downloadedFilePath}');
      } else {
        throw Exception('Failed to download book: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error downloading book: $e');
      throw Exception('Error downloading book: $e');
    }
  }

  Future<void> _loadEpubBook() async {
    if (_downloadedFilePath == null) return;

    try {
      final file = File(_downloadedFilePath!);
      final bytes = await file.readAsBytes();
      _epubBook = await EpubReader.readBook(bytes);
      
      // Extract chapters
      _chapters = _extractChapters(_epubBook!);
      
      if (_chapters.isNotEmpty) {
        _loadChapter(0);
      }
    } catch (e) {
      debugPrint('Error loading EPUB book: $e');
      throw Exception('Error loading EPUB book: $e');
    }
  }

  List<EpubChapter> _extractChapters(EpubBook book) {
    List<EpubChapter> chapters = [];
    
    void addChapters(List<EpubChapter> chapterList) {
      for (var chapter in chapterList) {
        chapters.add(chapter);
        if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
          addChapters(chapter.SubChapters!);
        }
      }
    }
    
    if (book.Chapters != null) {
      addChapters(book.Chapters!);
    }
    
    return chapters;
  }

  void _loadChapter(int index) {
    if (index < 0 || index >= _chapters.length) return;
    
    setState(() {
      _currentChapterIndex = index;
      _currentChapterContent = _chapters[index].HtmlContent ?? '';
      _readingProgress = (index + 1) / _chapters.length;
    });
    
    _saveReadingPosition();
  }

  Future<void> _loadLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChapter = prefs.getInt('book_chapter_${widget.bookId}') ?? 0;
    if (savedChapter < _chapters.length) {
      _loadChapter(savedChapter);
    }
  }

  Future<void> _saveReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('book_chapter_${widget.bookId}', _currentChapterIndex);
  }

  void _nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      _loadChapter(_currentChapterIndex + 1);
    }
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      _loadChapter(_currentChapterIndex - 1);
    }
  }

  void _showChapterList() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table of Contents',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    return ListTile(
                      title: Text(
                        chapter.Title ?? 'Chapter ${index + 1}',
                        style: GoogleFonts.judson(),
                      ),
                      selected: index == _currentChapterIndex,
                      onTap: () {
                        Navigator.pop(context);
                        _loadChapter(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
              leading: const Icon(Icons.book),
              title: Text('Table of Contents', style: GoogleFonts.judson()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showChapterList();
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
    // For now, we'll just show a message since font size would require
    // re-rendering the HTML content
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Font size adjustment coming soon!')),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Loading your book...',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This may take a moment',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.bookTitle, style: GoogleFonts.judson()),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load book content',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The book format may not be supported',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
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
            icon: const Icon(Icons.list),
            onPressed: _showChapterList,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showReadingSettings,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Main content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentChapterIndex < _chapters.length)
                      Text(
                        _chapters[_currentChapterIndex].Title ?? 'Chapter ${_currentChapterIndex + 1}',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Html(
                      data: _currentChapterContent,
                      style: {
                        "body": Style(
                          fontFamily: 'Judson',
                          fontSize: FontSize(18),
                          lineHeight: LineHeight(1.6),
                        ),
                        "p": Style(
                          margin: Margins(bottom: Margin(16)),
                        ),
                        "h1,h2,h3,h4,h5,h6": Style(
                          margin: Margins(top: Margin(24), bottom: Margin(16)),
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Reading progress bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _readingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            
            // Navigation controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _previousChapter,
                        icon: const Icon(Icons.navigate_before),
                        label: Text('Previous', style: GoogleFonts.judson()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: Colors.black,
                        ),
                      ),
                      Text(
                        'Chapter ${_currentChapterIndex + 1} of ${_chapters.length}',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _nextChapter,
                        icon: const Icon(Icons.navigate_next),
                        label: Text('Next', style: GoogleFonts.judson()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: Colors.black,
                        ),
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
}