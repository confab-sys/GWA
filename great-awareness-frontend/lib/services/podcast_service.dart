import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/podcast.dart';

class PodcastService {
  // Using the new worker URL
  static const String _baseUrl = 'https://gwa-podcast-worker.aashardcustomz.workers.dev/api';

  // Fetch all podcasts
  static Future<List<Podcast>> getPodcasts({String category = 'All', int page = 1, int limit = 50}) async {
    try {
      String url = '$_baseUrl/podcasts?page=$page&limit=$limit';
      if (category != 'All') {
        url += '&category=${Uri.encodeComponent(category)}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['podcasts'] != null) {
          final List<dynamic> podcastsData = data['podcasts'];
          return podcastsData.map((json) => Podcast.fromJson(json)).toList();
        }
      }
      
      throw Exception('Failed to load podcasts: ${response.statusCode}');
    } catch (e) {
      print('Error fetching podcasts: $e');
      return [];
    }
  }

  // Get single podcast
  static Future<Podcast?> getPodcast(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/podcasts/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['podcast'] != null) {
          return Podcast.fromJson(data['podcast']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching podcast details: $e');
      return null;
    }
  }
}
