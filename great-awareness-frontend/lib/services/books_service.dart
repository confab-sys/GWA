import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BooksService {
  // Assuming the worker URL based on the video worker pattern
  static const String workerUrl = 'https://gwa-books-worker.aashardcustomz.workers.dev';
  
  static Future<List<Book>> fetchBooks() async {
    try {
      // Fetch from API
      // Using /books endpoint as defined in worker
      final response = await http.get(Uri.parse('$workerUrl/books'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['books'] != null) {
           return (data['books'] as List)
              .map((json) => Book.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching books from API: $e');
      rethrow; // Propagate error so UI can handle it (or show retry)
    }
    
    return [];
  }

  static Future<void> syncBooks() async {
    try {
      final response = await http.post(Uri.parse('$workerUrl/sync'));
      if (response.statusCode == 200) {
        print('Books synced successfully: ${response.body}');
      } else {
        print('Failed to sync books: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error syncing books: $e');
    }
  }

  static List<String> getCategories() {
    return [
      'Latest',
      'Emotional Intelligence',
      'Finances',
      'Sexual Health',
      'Family',
      'Habits',
      'Relationships',
    ];
  }
}
