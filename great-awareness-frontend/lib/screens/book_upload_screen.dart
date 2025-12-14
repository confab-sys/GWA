import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookUploadScreen extends StatefulWidget {
  const BookUploadScreen({super.key});

  @override
  State<BookUploadScreen> createState() => _BookUploadScreenState();
}

class _BookUploadScreenState extends State<BookUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _languageController = TextEditingController(text: 'en');
  final _readTimeController = TextEditingController();
  
  String _accessLevel = 'free';
  bool _downloadAllowed = true;
  bool _streamAllowed = true;
  
  File? _bookFile;
  File? _coverImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _pageCountController.dispose();
    _languageController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _bookFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    
    if (result != null) {
      setState(() {
        _coverImage = File(result.path);
      });
    }
  }

  Future<void> _uploadBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_bookFile == null || _coverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both book file and cover image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://your-worker-domain.com/upload'), // Replace with your worker URL
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-User-ID'] = 'user123'; // Replace with actual user ID

      // Add form fields
      request.fields.addAll({
        'title': _titleController.text,
        'author': _authorController.text,
        'category': _categoryController.text,
        'description': _descriptionController.text,
        'page_count': _pageCountController.text,
        'language': _languageController.text,
        'estimated_read_time_minutes': _readTimeController.text,
        'access_level': _accessLevel,
        'download_allowed': _downloadAllowed.toString(),
        'stream_read_allowed': _streamAllowed.toString(),
      });

      // Add files
      request.files.add(await http.MultipartFile.fromPath('file', _bookFile!.path));
      request.files.add(await http.MultipartFile.fromPath('cover_image', _coverImage!.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book uploaded successfully: ${result['bookId']}')),        );
        Navigator.pop(context);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading book: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Upload Book',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book File Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _pickBookFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          _bookFile != null ? Icons.check_circle : Icons.upload_file,
                          size: 48,
                          color: _bookFile != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bookFile != null 
                            ? 'Book selected: ${_bookFile!.path.split(Platform.pathSeparator).last}'
                            : 'Select Book File (EPUB/PDF)',
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              fontSize: 16,
                              color: _bookFile != null ? Colors.green : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cover Image Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _pickCoverImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_coverImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _coverImage!,
                              height: 120,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          _coverImage != null ? 'Change Cover Image' : 'Select Cover Image',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: 'Author',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an author';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Row with Page Count, Language, Read Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pageCountController,
                      decoration: InputDecoration(
                        labelText: 'Pages',
                        labelStyle: GoogleFonts.judson(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _languageController,
                      decoration: InputDecoration(
                        labelText: 'Language',
                        labelStyle: GoogleFonts.judson(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _readTimeController,
                      decoration: InputDecoration(
                        labelText: 'Read Time (min)',
                        labelStyle: GoogleFonts.judson(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Access Level
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
                        'Access Level',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Free', style: GoogleFonts.judson()),
                              value: 'free',
                              groupValue: _accessLevel,
                              onChanged: (value) {
                                setState(() {
                                  _accessLevel = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Premium', style: GoogleFonts.judson()),
                              value: 'premium',
                              groupValue: _accessLevel,
                              onChanged: (value) {
                                setState(() {
                                  _accessLevel = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Permissions
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
                        'Permissions',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: Text('Allow Download', style: GoogleFonts.judson()),
                        value: _downloadAllowed,
                        onChanged: (value) {
                          setState(() {
                            _downloadAllowed = value!;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Allow Streaming', style: GoogleFonts.judson()),
                        value: _streamAllowed,
                        onChanged: (value) {
                          setState(() {
                            _streamAllowed = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Upload Book',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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