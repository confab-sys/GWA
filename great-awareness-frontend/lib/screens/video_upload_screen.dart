import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _selectedVideo;
  String? _fileName;
  int? _fileSize;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideo = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileSize = result.files.single.size;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick video: $e';
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate() || _selectedVideo == null) {
      setState(() {
        _errorMessage = 'Please select a video file and fill in all required fields';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      final response = await VideoService.uploadVideo(
        videoFile: _selectedVideo!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = total > 0 ? sent / total : 0.0;
            });
          }
        },
      );

      if (mounted) {
        if (response.success && response.video != null) {
          setState(() {
            _successMessage = 'Video uploaded successfully!';
            _isUploading = false;
            _selectedVideo = null;
            _fileName = null;
            _fileSize = null;
            _titleController.clear();
            _descriptionController.clear();
            _uploadProgress = 0.0;
          });

          // Show success dialog
          _showSuccessDialog(response.video!);
        } else {
          setState(() {
            _errorMessage = response.error ?? response.message ?? 'Upload failed';
            _isUploading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Upload error: $e';
          _isUploading = false;
        });
      }
    }
  }

  void _showSuccessDialog(Video video) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Upload Successful!',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your video "${video.title}" has been uploaded successfully.'),
              const SizedBox(height: 8),
              Text('File size: ${video.formattedFileSize}'),
              Text('Upload time: ${video.formattedDuration}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text('View Videos'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form for another upload
                setState(() {
                  _selectedVideo = null;
                  _fileName = null;
                  _fileSize = null;
                });
              },
              child: const Text('Upload Another'),
            ),
          ],
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Video',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _isUploading ? null : _pickVideo,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _selectedVideo != null 
                              ? Icons.video_library 
                              : Icons.cloud_upload,
                          size: 48,
                          color: _selectedVideo != null 
                              ? Colors.green 
                              : Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedVideo != null 
                              ? 'Video Selected'
                              : 'Select Video File',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_fileName != null) ...[
                          Text(
                            _fileName!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(_fileSize ?? 0),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ] else
                          Text(
                            'Tap to select a video file (MP4, MOV, AVI, WebM)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter video title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                enabled: !_isUploading,
              ),

              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter video description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                enabled: !_isUploading,
              ),

              const SizedBox(height: 24),

              // Upload Progress
              if (_isUploading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Success Message
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: GoogleFonts.inter(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Upload Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadVideo,
                icon: _isUploading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload Video',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              if (!_isUploading)
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}