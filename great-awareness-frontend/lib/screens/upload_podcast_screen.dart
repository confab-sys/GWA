import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/podcast_service.dart';
import '../services/image_upload_service.dart';

class UploadPodcastScreen extends StatefulWidget {
  const UploadPodcastScreen({super.key});

  @override
  State<UploadPodcastScreen> createState() => _UploadPodcastScreenState();
}

class _UploadPodcastScreenState extends State<UploadPodcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  File? _audioFile;
  Uint8List? _audioBytes;
  String? _audioFileName;

  File? _thumbnailFile;
  Uint8List? _thumbnailBytes;
  
  bool _isUploading = false;
  String? _statusMessage;

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true, // Important for web
      );

      if (result != null) {
        if (kIsWeb) {
          setState(() {
            _audioBytes = result.files.single.bytes;
            _audioFileName = result.files.single.name;
            _audioFile = null;
          });
        } else if (result.files.single.path != null) {
          setState(() {
            _audioFile = File(result.files.single.path!);
            _audioFileName = result.files.single.name;
            _audioBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking audio: $e')),
      );
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _thumbnailBytes = bytes;
            _thumbnailFile = null;
          });
        } else {
          setState(() {
            _thumbnailFile = File(image.path);
            _thumbnailBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking thumbnail: $e')),
      );
    }
  }

  Future<void> _uploadPodcast() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_audioFile == null && _audioBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }
    if (_thumbnailFile == null && _thumbnailBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a thumbnail image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading thumbnail...';
    });

    try {
      // 1. Upload Thumbnail
      ImageUploadResponse imageResponse;
      
      if (kIsWeb && _thumbnailBytes != null) {
        imageResponse = await ImageUploadService.uploadImageBytes(
          imageBytes: _thumbnailBytes!,
          fileName: 'podcast_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
          title: _titleController.text,
          description: 'Podcast Thumbnail',
        );
      } else {
        imageResponse = await ImageUploadService.uploadImage(
          imageFile: _thumbnailFile!,
          title: _titleController.text,
          description: 'Podcast Thumbnail',
        );
      }

      if (!imageResponse.success || imageResponse.imageUrl == null) {
        throw Exception('Thumbnail upload failed: ${imageResponse.error}');
      }

      setState(() {
        _statusMessage = 'Uploading audio...';
      });

      // 2. Upload Audio
      String? audioUrl;
      
      if (kIsWeb && _audioBytes != null) {
        audioUrl = await PodcastService.uploadAudioBytes(
          _audioBytes!, 
          _audioFileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3'
        );
      } else {
        audioUrl = await PodcastService.uploadAudio(_audioFile!);
      }

      if (audioUrl == null) {
        throw Exception('Audio upload failed');
      }

      setState(() {
        _statusMessage = 'Creating podcast...';
      });

      // 3. Create Podcast Record
      final podcast = await PodcastService.createPodcast(
        title: _titleController.text,
        subtitle: _subtitleController.text,
        description: _descriptionController.text,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : 'General',
        audioUrl: audioUrl,
        thumbnailUrl: imageResponse.imageUrl!,
        duration: '00:00', // You might want to calculate this or let backend handle it
      );

      if (podcast != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Podcast uploaded successfully!')),
          );
          Navigator.pop(context, true); // Return true to refresh list
        }
      } else {
        throw Exception('Failed to create podcast record');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Podcast',
          style: GoogleFonts.judson(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail Selection
              GestureDetector(
                onTap: _isUploading ? null : _pickThumbnail,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                    image: (_thumbnailFile != null || _thumbnailBytes != null)
                        ? DecorationImage(
                            image: kIsWeb && _thumbnailBytes != null
                                ? MemoryImage(_thumbnailBytes!) as ImageProvider
                                : FileImage(_thumbnailFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (_thumbnailFile == null && _thumbnailBytes == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to select thumbnail',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),

              // Subtitle
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Meditation, Sleep, Anxiety',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                enabled: !_isUploading,
              ),
              const SizedBox(height: 24),

              // Audio File Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.audiotrack, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _audioFileName ?? 'No audio file selected',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickAudio,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Audio File'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Upload Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadPodcast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_statusMessage ?? 'Uploading...'),
                          ],
                        )
                      : const Text(
                          'Upload Podcast',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
