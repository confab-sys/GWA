import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
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
  Uint8List? _webVideoBytes;
  String? _webVideoName;
  bool _isUploading = false;
  String? _uploadError;
  String? _uploadSuccess;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      print('Starting file picker...');
      print('Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
      
      FilePickerResult? result;
      
      // For web, use a simpler approach to avoid plugin issues
      if (kIsWeb) {
        print('Using web-specific file picker approach...');
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowCompression: false,
            withData: true,
          );
          print('Web file picker result: $result');
        } catch (e) {
          print('Web file picker error: $e');
          // Try with any type as fallback for web
          try {
            result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowCompression: false,
              withData: true,
            );
            print('Web fallback file picker result: $result');
          } catch (e2) {
            print('Web fallback file picker also failed: $e2');
            result = null;
          }
        }
      } else {
        // Mobile/desktop approach with multiple attempts
        // Try with FileType.video first (this should work for most video files)
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowCompression: false,
            withData: true, // Always true - required for web, works on mobile too
          );
          print('Video file picker result: $result');
        } catch (e) {
          print('Error with video file picker: $e');
          result = null;
        }

        // If video type doesn't work, try with custom extensions
        if (result == null) {
          print('Video type failed, trying custom extensions...');
          try {
            result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['mp4', 'mov', 'avi', 'webm', 'mkv', 'm4v', '3gp', 'wmv', 'flv'],
              allowCompression: false,
              withData: true, // Always true - required for web, works on mobile too
            );
            print('Custom extensions file picker result: $result');
          } catch (e) {
            print('Error with custom extensions file picker: $e');
            result = null;
          }
        }

        // If still no result, try with any file type as fallback
        if (result == null) {
          print('Custom extensions failed, trying any file type...');
          try {
            result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowCompression: false,
              withData: true, // Always true - required for web, works on mobile too
            );
            print('Any file type picker result: $result');
          } catch (e) {
            print('Error with any file type picker: $e');
            result = null;
          }
        }
      }

      print('File picker result: $result');
          
          if (result != null) {
            print('Files selected: ${result.files.length}');
            if (result.files.isNotEmpty) {
              final file = result.files.single;
              
              // CRITICAL: Never access file.path on web platform
              if (kIsWeb) {
                print('=== Web File Details (SAFE) ===');
                print('File name: ${file.name}');
                print('File size: ${file.size}');
                print('File path: [INTENTIONALLY HIDDEN ON WEB]');
                print('File bytes available: ${file.bytes != null}');
                print('File bytes length: ${file.bytes?.length ?? 0}');
                print('Platform: Web');
                print('================================');
                
                if (file.bytes == null || file.bytes!.isEmpty) {
                  print('ERROR: Web platform but no bytes available!');
                  setState(() {
                    _uploadError = 'File picker did not provide file data on web. This might be a browser security restriction.';
                  });
                  return;
                }
              } else {
                print('=== Mobile/Desktop File Details ===');
                print('File name: ${file.name}');
                print('File size: ${file.size}');
                print('File path: ${file.path}');
                print('File bytes available: ${file.bytes != null}');
                print('Platform: Mobile/Desktop');
                print('=====================================');
              }
          
          // Validate that it's actually a video file
          final fileExtension = file.name.split('.').last.toLowerCase();
          final validVideoExtensions = ['mp4', 'mov', 'avi', 'webm', 'mkv', 'm4v', '3gp', 'wmv', 'flv'];
          
          if (!validVideoExtensions.contains(fileExtension)) {
            setState(() {
              _uploadError = 'Selected file is not a supported video format. Please select MP4, MOV, AVI, WebM, MKV, M4V, 3GP, WMV, or FLV file.';
            });
            print('Invalid file format: $fileExtension');
            return;
          }
          
          // Determine platform and handle accordingly
          if (kIsWeb) {
            // Handle web platform - must use bytes
            print('Using web/bytes approach (kIsWeb: true)');
            
            try {
              print('Processing web file: ${file.name}');
              print('Web file bytes: ${file.bytes}');
              print('Web file bytes length: ${file.bytes?.length ?? 0}');
              
              if (file.bytes != null && file.bytes!.isNotEmpty) {
                print('Web file bytes length: ${file.bytes!.length}');
                setState(() {
                  _webVideoBytes = file.bytes;
                  _webVideoName = file.name;
                  _selectedVideo = null; // Ensure _selectedVideo is null on web
                  _uploadError = null;
                });
                print('Video selected successfully on web: ${file.name} (${file.bytes!.length} bytes)');
                print('State after web selection:');
                print('  _webVideoBytes: ${_webVideoBytes != null}');
                print('  _webVideoBytes length: ${_webVideoBytes?.length ?? 0}');
                print('  _webVideoName: ${_webVideoName}');
                print('  _selectedVideo: ${_selectedVideo}');
              } else {
                setState(() {
                  _uploadError = 'Could not read video file bytes on web. Please try a different video file. The file picker may not have provided the file data.';
                });
                print('File bytes are null or empty on web');
                print('File details - name: ${file.name}, size: ${file.size}, bytes: ${file.bytes}');
                print('This might indicate that the file picker is not providing bytes. Check file picker configuration.');
              }
            } catch (e, stackTrace) {
              setState(() {
                _uploadError = 'Error processing video file on web: $e';
              });
              print('Error processing web video file: $e');
              print('Stack trace: $stackTrace');
            }
          } else if (file.path == null) {
            // Handle edge case where path is null but not on web (shouldn't happen, but just in case)
            setState(() {
              _uploadError = 'File path is null and not on web platform. This is unexpected.';
            });
            print('Unexpected state: file.path is null but not on web platform');
          } else {
            // Handle mobile/desktop platforms
            if (file.path != null) {
              final selectedFile = File(file.path!);
              // Verify the file exists and is accessible
              if (await selectedFile.exists()) {
                setState(() {
                  _selectedVideo = selectedFile;
                  _webVideoBytes = null; // Ensure web bytes are null on mobile
                  _webVideoName = null;
                  _uploadError = null;
                });
                print('Video selected successfully on mobile: ${file.path}');
              } else {
                setState(() {
                  _uploadError = 'Selected file does not exist or is not accessible';
                });
                print('File does not exist at path: ${file.path}');
              }
            } else {
              setState(() {
                _uploadError = 'File path is null - file picker may not have proper permissions';
              });
              print('File path is null');
            }
          }
        }
      } else {
        print('File picker was cancelled or returned null');
      }
    } catch (e, stackTrace) {
      print('Error selecting video: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Error selecting video: ';
      if (kIsWeb) {
        if (e.toString().toLowerCase().contains('path')) {
          errorMessage += 'File path is not available on web platform. The app is trying to access file.path which is always null on web. Make sure all code uses file.bytes instead.';
        } else if (e.toString().toLowerCase().contains('webplatform')) {
          errorMessage += 'File picker error on web platform. This usually means the file picker is trying to access file.path. The app should use file.bytes on web.';
        } else {
          errorMessage += 'Web platform error: ${e.toString()}';
        }
      } else {
        errorMessage += e.toString();
      }
      
      setState(() {
        _uploadError = errorMessage;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('=== UPLOAD BUTTON PRESSED ===');
    print('Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
    print('Web video bytes: ${_webVideoBytes}');
    print('Web video bytes length: ${_webVideoBytes?.length ?? 0}');
    print('Web video name: ${_webVideoName}');
    print('Selected video (mobile): ${_selectedVideo}');
    print('Form title: ${_titleController.text.trim()}');
    print('Form description: ${_descriptionController.text.trim()}');
    print('=============================');

    // Validate video selection based on platform
    if (kIsWeb) {
      if (_webVideoBytes == null) {
        print('ERROR: _webVideoBytes is null on web!');
        setState(() {
          _uploadError = 'Please select a video first';
        });
        return;
      }
      if (_webVideoBytes!.isEmpty) {
        print('ERROR: _webVideoBytes is empty on web!');
        setState(() {
          _uploadError = 'Video file is empty. Please select a different video.';
        });
        return;
      }
      if (_webVideoName == null || _webVideoName!.isEmpty) {
        print('ERROR: _webVideoName is null or empty on web!');
        setState(() {
          _uploadError = 'Video filename is missing. Please select a different video.';
        });
        return;
      }
      print('Web validation passed!');
    } else {
      if (_selectedVideo == null) {
        print('ERROR: _selectedVideo is null on mobile!');
        setState(() {
          _uploadError = 'Please select a video first';
        });
        return;
      }
      print('Mobile validation passed!');
    }

    // Check file size (100MB limit)
    int fileSize;
    if (kIsWeb) {
      fileSize = _webVideoBytes!.length;
    } else {
      fileSize = await _selectedVideo!.length();
    }
    
    const maxSize = 100 * 1024 * 1024; // 100MB in bytes
    
    if (fileSize > maxSize) {
      setState(() {
        _uploadError = 'File size exceeds 100MB limit. Please select a smaller video.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
      _uploadSuccess = null;
    });

    try {
      print('Starting upload...');
      print('Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
      
      // Pre-upload validation
      if (kIsWeb) {
        if (_webVideoBytes == null || _webVideoBytes!.isEmpty) {
          throw Exception('No video bytes available for upload');
        }
        if (_webVideoName == null || _webVideoName!.isEmpty) {
          throw Exception('No filename available for upload');
        }
        
        // Check file size (100MB limit)
        const maxSize = 100 * 1024 * 1024; // 100MB in bytes
        if (_webVideoBytes!.length > maxSize) {
          throw Exception('File size exceeds 100MB limit');
        }
        
        print('Pre-upload validation passed for web:');
        print('  File name: $_webVideoName');
        print('  File size: ${_webVideoBytes!.length} bytes (${(_webVideoBytes!.length / (1024 * 1024)).toStringAsFixed(2)} MB)');
        print('  Within size limit: ${_webVideoBytes!.length <= maxSize}');
      }
      
      // Upload video using platform-specific method
      final response;
      if (kIsWeb) {
        print('Uploading web video:');
        print('  File name: ${_webVideoName}');
        print('  File size: ${_webVideoBytes?.length ?? 0} bytes');
        print('  Title: ${_titleController.text.trim()}');
        print('  Description: ${_descriptionController.text.trim().isEmpty ? "(empty)" : _descriptionController.text.trim()}');
        
        response = await VideoService.uploadVideoWeb(
          videoBytes: _webVideoBytes!,
          fileName: _webVideoName!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      } else {
        print('Uploading mobile video:');
        print('  File path: ${_selectedVideo?.path}');
        print('  File size: ${_selectedVideo?.lengthSync() ?? 0} bytes');
        print('  Title: ${_titleController.text.trim()}');
        print('  Description: ${_descriptionController.text.trim().isEmpty ? "(empty)" : _descriptionController.text.trim()}');
        
        response = await VideoService.uploadVideo(
          videoFile: _selectedVideo!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }

      if (response.success) {
        setState(() {
          _uploadSuccess = 'Video uploaded successfully!';
          _isUploading = false;
        });

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Upload Successful'),
                content: Text('Your video "${_titleController.text}" has been uploaded successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Return to previous screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Upload failed on server side
        String errorMessage = response.error ?? 'Upload failed';
        if (response.message != null) {
          errorMessage += ': ${response.message}';
        }
        
        setState(() {
          _uploadError = errorMessage;
          _isUploading = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Upload failed: ';
      
      if (e.toString().contains('unsupported operation_namespace')) {
        errorMessage += 'Unsupported file format. Please use MP4, MOV, AVI, WebM, MKV, M4V, or 3GP format.';
      } else if (e.toString().contains('file too large')) {
        errorMessage += 'File size exceeds 100MB limit.';
      } else if (e.toString().contains('network')) {
        errorMessage += 'Network error. Please check your connection.';
      } else {
        errorMessage += e.toString();
      }
      
      setState(() {
        _uploadError = errorMessage;
        _isUploading = false;
      });
    }
  }

  String _getFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // Safe method to get file name without accessing path on web
  String _getFileName() {
    if (kIsWeb) {
      return _webVideoName ?? 'Unknown';
    } else {
      return _selectedVideo?.path.split('/').last ?? 'Unknown';
    }
  }

  // Safe method to get file size without accessing File on web
  int _getFileSizeBytes() {
    if (kIsWeb) {
      return _webVideoBytes?.length ?? 0;
    } else {
      return _selectedVideo?.lengthSync() ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Upload Video',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video Selection Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Video',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if ((kIsWeb ? _webVideoBytes != null : _selectedVideo != null)) ...[
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  _getFileName(),
                                  style: GoogleFonts.judson(
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${_getFileSize(_getFileSizeBytes())}',
                                  style: GoogleFonts.judson(
                                    textStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickVideo,
                              icon: const Icon(Icons.video_library),
                              label: Text(
                                'Select Video',
                                style: GoogleFonts.judson(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
                style: GoogleFonts.judson(),
              ),
              
              const SizedBox(height: 16),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
                style: GoogleFonts.judson(),
              ),
              
              const SizedBox(height: 24),
              
              // Error/Success Messages
              if (_uploadError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadError!,
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              color: Colors.red[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_uploadSuccess != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadSuccess!,
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
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
                            Text(
                              'Uploading...',
                              style: GoogleFonts.judson(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Upload Video',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Upload Requirements
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Requirements:',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementItem('Video file must be MP4, MOV, AVI, WebM, MKV, M4V, or 3GP format'),
                      _buildRequirementItem('Maximum file size: 100MB'),
                      _buildRequirementItem('Title is required (minimum 3 characters)'),
                      _buildRequirementItem('Description is optional but recommended'),
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

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.judson(
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}