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
        // For cloud books, we'll open directly without downloading
        // Check if we're running on web platform
        if (kIsWeb) {
          // On web, we can't use file system, so download directly to memory
          debugPrint('Running on web platform - downloading to memory');
          await _downloadBookFromCloud();
        } else {
          // For mobile/desktop, try cached version first
          try {
            final tempDir = await getTemporaryDirectory();
            final cachedFile = File('${tempDir.path}/${widget.bookId}.epub');
            
            if (await cachedFile.exists()) {
              // Use cached version if available
              _downloadedFilePath = cachedFile.path;
            } else {
              // Download and cache for future use
              await _downloadBookFromCloud();
            }
          } catch (e) {
            // If path_provider fails, download directly
            debugPrint('path_provider failed, downloading directly: $e');
            await _downloadBookFromCloud();
          }
        }
      } else {
        // For already downloaded books
        _downloadedFilePath = widget.bookPath;
      }

      if (_downloadedFilePath != null) {
        await _loadLastReadingPosition();
      }
    } catch (e) {
      debugPrint('Error initializing book: $e');
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
      debugPrint('Downloading book from: ${widget.cloudUrl}');
      final response = await http.get(Uri.parse(widget.cloudUrl!));
      debugPrint('Download response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        if (kIsWeb) {
          // On web platform, we don't need to "download" - just confirm the book is available
          // We'll use the cloud URL directly since we can't save files on web
          _downloadedFilePath = widget.cloudUrl!;
          debugPrint('Book confirmed available for web platform');
        } else {
          // For mobile/desktop, save to temporary file
          try {
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/${widget.bookId}.epub');
            await tempFile.writeAsBytes(response.bodyBytes);
            _downloadedFilePath = tempFile.path;
            debugPrint('Book downloaded successfully to: ${_downloadedFilePath}');
          } catch (pathError) {
            // If path_provider fails, use a fallback location
            debugPrint('path_provider failed in download, using fallback: $pathError');
            final fallbackPath = '${Directory.systemTemp.path}/${widget.bookId}.epub';
            final tempFile = File(fallbackPath);
            await tempFile.writeAsBytes(response.bodyBytes);
            _downloadedFilePath = tempFile.path;
            debugPrint('Book downloaded to fallback location: ${_downloadedFilePath}');
          }
        }
      } else {
        throw Exception('Failed to download book: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error downloading book: $e');
      throw Exception('Error downloading book: $e');
    }
  }

  void _openWebEpubReader() {
    // For web platform, we'll create a simple web view or redirect to the EPUB URL
    // Since we have the R2 URL, we can either:
    // 1. Open it in a new tab (if the browser supports EPUB)
    // 2. Use a web-based EPUB reader service
    // 3. Create a simple HTML viewer
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.bookTitle,
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
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'EPUB Book Reader',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Book: ${widget.bookTitle}',
                        style: GoogleFonts.judson(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Open the EPUB URL in a new tab
                          final url = widget.cloudUrl!;
                          try {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              throw 'Could not launch $url';
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error opening book: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: Text('Open Book in Browser', style: GoogleFonts.judson()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'URL: ${widget.cloudUrl}',
                        style: GoogleFonts.judson(textStyle: const TextStyle(fontSize: 10)),
                        textAlign: TextAlign.center,
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
      debugPrint('Error calculating progress: $e');
    }
    return 0.0;
  }

  void _openBook() {
    if (_downloadedFilePath == null) return;

    // Check if we're running on web platform
    if (kIsWeb) {
      // For web platform, show a message with the book URL since vocsy_epub_viewer doesn't support web
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Book Available', style: GoogleFonts.judson()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your book is ready to read!', style: GoogleFonts.judson()),
              const SizedBox(height: 16),
              Text('Book URL: ${widget.cloudUrl}', style: GoogleFonts.judson(textStyle: const TextStyle(fontSize: 12))),
              const SizedBox(height: 16),
              Text('Note: Web EPUB reading requires a dedicated web reader.', style: GoogleFonts.judson(textStyle: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.judson()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openWebEpubReader();
              },
              child: Text('Open in Web Reader', style: GoogleFonts.judson()),
            ),
          ],
        ),
      );
      return;
    }

    // Configure the EPUB viewer (only for mobile/desktop)
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

  void _openInNewTab() {
    // Open the EPUB file directly in a new tab
    // This will either download the file or open it if the browser supports EPUB
    final url = widget.cloudUrl!;
    debugPrint('Opening EPUB in new tab: $url');
    
    // For Flutter web, use url_launcher for cross-platform compatibility
    launchUrl(Uri.parse(url));
  }

  void _openInWebReader() {
    // Use a web-based EPUB reader service
    // There are several options, let's use a popular one
    final epubUrl = Uri.encodeComponent(widget.cloudUrl!);
    final readerUrl = 'https://www.bookfusion.com/read?url=$epubUrl';
    
    debugPrint('Opening in web EPUB reader: $readerUrl');
    
    // Open in new tab using url_launcher for cross-platform compatibility
    launchUrl(Uri.parse(readerUrl));
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
    // Automatically open the book when it's ready (with a small delay for stability)
    if (!_isLoading && _downloadedFilePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _openBook();
          }
        });
      });
    }
    
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
              'Opening Book...',
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we load your book',
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
            if (_downloadedFilePath != null) ...[
              ElevatedButton(
                onPressed: _openBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Open Book',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Preparing your book...',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}