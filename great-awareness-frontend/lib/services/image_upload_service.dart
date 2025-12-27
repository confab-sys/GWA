import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static const String baseUrl = 'https://gwa-main-worker.aashardcustomz.workers.dev'; // Main Cloudflare worker

  /// Upload image file to Cloudflare R2 storage
  static Future<ImageUploadResponse> uploadImage({
    required File imageFile,
    required String title,
    String description = '',
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/contents/upload-image'),
      );

      // Add image file (field name 'file' as expected by worker)
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      
      request.files.add(http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      ));

      // Add form fields (optional, worker might not use them but good to keep)
      request.fields['title'] = title;
      request.fields['description'] = description;

      // Send request with progress tracking
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        
        // Handle relative URL from worker
        String? imageUrl = jsonResponse['url'];
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = '$baseUrl$imageUrl';
        }

        return ImageUploadResponse(
          success: true,
          imageUrl: imageUrl,
          message: jsonResponse['message'],
        );
      } else {
        final errorResponse = json.decode(response.body);
        return ImageUploadResponse(
          success: false,
          error: errorResponse['error'] ?? 'Upload failed',
          message: errorResponse['message'],
        );
      }
    } catch (e) {
      return ImageUploadResponse(
        success: false,
        error: 'Upload error',
        message: e.toString(),
      );
    }
  }

  /// Upload image from bytes (for web)
  static Future<ImageUploadResponse> uploadImageBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String title,
    String description = '',
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/contents/upload-image'),
      );

      // Add image file from bytes (field name 'file')
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ));

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        
        // Handle relative URL from worker
        String? imageUrl = jsonResponse['url'];
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = '$baseUrl$imageUrl';
        }

        return ImageUploadResponse(
          success: true,
          imageUrl: imageUrl,
          message: jsonResponse['message'],
        );
      } else {
        final errorResponse = json.decode(response.body);
        return ImageUploadResponse(
          success: false,
          error: errorResponse['error'] ?? 'Upload failed',
          message: errorResponse['message'],
        );
      }
    } catch (e) {
      return ImageUploadResponse(
        success: false,
        error: 'Upload error',
        message: e.toString(),
      );
    }
  }
}

class ImageUploadResponse {
  final bool success;
  final String? imageUrl;
  final String? imageId;
  final String? error;
  final String? message;

  ImageUploadResponse({
    required this.success,
    this.imageUrl,
    this.imageId,
    this.error,
    this.message,
  });

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      success: json['success'] ?? false,
      imageUrl: json['data']?['url'],
      imageId: json['data']?['id'],
      error: json['error'],
      message: json['message'],
    );
  }
}