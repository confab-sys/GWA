import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../models/book.dart';

class PdfReaderScreen extends StatefulWidget {
  final Book book;

  const PdfReaderScreen({super.key, required this.book});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  PdfControllerPinch? _pdfControllerPinch;
  PdfController? _pdfController; // For Windows
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  
  // Worker URL for updates
  static const String _workerUrl = 'https://gwa-books-worker.aashardcustomz.workers.dev';

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  @override
  void dispose() {
    _pdfControllerPinch?.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _initializeReader() async {
    try {
      final file = await _downloadOrGetCachedFile();
      if (file != null) {
        
        // Load initial page from SharedPreferences or Book object
        int initialPage = 1;
        final prefs = await SharedPreferences.getInstance();
        final savedPage = prefs.getInt('book_page_${widget.book.id}');
        if (savedPage != null && savedPage > 0) {
          initialPage = savedPage;
        }

        // Open document first to get page count and ensure valid file
        final document = await PdfDocument.openFile(file.path);
        
        if (mounted) {
            setState(() {
                _totalPages = document.pagesCount;
            });
        }

        if (Platform.isWindows) {
            _pdfController = PdfController(
              document: Future.value(document),
              initialPage: initialPage,
            );
        } else {
            _pdfControllerPinch = PdfControllerPinch(
              document: Future.value(document),
              initialPage: initialPage,
            );
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentPage = initialPage;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing PDF reader: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load PDF: $e';
        });
      }
    }
  }

  Future<File?> _downloadOrGetCachedFile() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final fileName = '${widget.book.id}.pdf'; 
      final file = File('${cacheDir.path}/$fileName');

      if (await file.exists()) {
        debugPrint('Opening cached PDF: ${file.path}');
        return file;
      }

      debugPrint('Downloading PDF from worker...');
      final downloadUrl = '$_workerUrl/download/${widget.book.id}';
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'guest';

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'X-User-ID': userId,
        },
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('PDF downloaded and cached: ${file.path}');
        return file;
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _saveProgress(page);
  }

  Future<void> _saveProgress(int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('book_page_${widget.book.id}', page);

      double progress = 0;
      if (_totalPages > 0) {
        progress = (page / _totalPages) * 100;
      }

      final userId = prefs.getString('user_id');
      if (userId != null) {
        // Fire and forget
        http.post(
          Uri.parse('$_workerUrl/progress'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': userId,
            'book_id': widget.book.id,
            'current_page': page,
            'progress_percent': progress,
            'completed': page == _totalPages,
          }),
        ).then((response) {
            if (response.statusCode != 200) {
               debugPrint('Failed to sync progress: ${response.body}');
            }
        }).catchError((e) {
           debugPrint('Error syncing progress: $e');
        });
      }
    } catch (e) {
      debugPrint('Error saving progress locally: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.book.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading Book...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeReader();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Windows View
    if (Platform.isWindows) {
        if (_pdfController == null) {
            return const Center(child: Text('Error: Controller not initialized', style: TextStyle(color: Colors.white)));
        }
        return Column(
          children: [
            Expanded(
              child: PdfView(
                controller: _pdfController!,
                onPageChanged: _onPageChanged,
              ),
            ),
            _buildWindowsControls(),
          ],
        );
    }

    // Mobile/Other View (Pinch)
    if (_pdfControllerPinch == null) {
       return const Center(child: Text('Unexpected error', style: TextStyle(color: Colors.white)));
    }

    return PdfViewPinch(
      controller: _pdfControllerPinch!,
      onPageChanged: _onPageChanged,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(
           loaderSwitchDuration: Duration(milliseconds: 100),
        ),
        documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (_, error) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildWindowsControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              _pdfController?.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () {
              _pdfController?.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }
}
