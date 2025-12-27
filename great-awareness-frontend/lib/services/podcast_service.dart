import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
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

  // Upload audio file
  static Future<String?> uploadAudio(File audioFile) async {
    try {
      final mimeType = lookupMimeType(audioFile.path) ?? 'audio/mpeg';
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      
      final fileStream = http.ByteStream(audioFile.openRead());
      final fileLength = await audioFile.length();
      
      request.files.add(http.MultipartFile(
        'audio',
        fileStream,
        fileLength,
        filename: audioFile.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['url'] as String;
        }
      }
      print('Upload failed with status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('Error uploading audio: $e');
      return null;
    }
  }

  // Upload audio bytes (for web)
  static Future<String?> uploadAudioBytes(List<int> bytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        bytes,
        filename: filename,
        contentType: MediaType.parse('audio/mpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['url'] as String;
        }
      }
      print('Upload failed with status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('Error uploading audio bytes: $e');
      return null;
    }
  }

  // Create podcast
  static Future<Podcast?> createPodcast({
    required String title,
    required String description,
    required String category,
    required String audioUrl,
    required String thumbnailUrl,
    String subtitle = '',
    String duration = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/podcasts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
          'category': category,
          'audioUrl': audioUrl,
          'thumbnailUrl': thumbnailUrl,
          'subtitle': subtitle,
          'duration': duration,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['podcast'] != null) {
          return Podcast.fromJson(data['podcast']);
        }
      }
      print('Create podcast failed with status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('Error creating podcast: $e');
      return null;
    }
  }
}
