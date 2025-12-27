import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/podcast.dart';

class PodcastPlayerScreen extends StatefulWidget {
  final Podcast podcast;
  final ValueNotifier<VideoPlayerController?> controllerNotifier;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final VoidCallback onClose;

  const PodcastPlayerScreen({
    super.key,
    required this.podcast,
    required this.controllerNotifier,
    required this.onPlayPause,
    required this.onSeek,
    required this.onClose,
  });

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<String> _getLocalFilePath(String filename) async {
    if (kIsWeb) return '';
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  Future<void> _downloadPodcast() async {
    if (kIsWeb) {
      final Uri url = Uri.parse(widget.podcast.audioUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch download URL')),
          );
        }
      }
      return;
    }

    final filename = '${widget.podcast.id}.m4a';
    final savePath = await _getLocalFilePath(filename);

    if (await File(savePath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Podcast already downloaded')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      await dio.download(
        widget.podcast.audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download complete!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          onPressed: widget.onClose,
        ),
        title: Text(
          'Now Playing',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<VideoPlayerController?>(
        valueListenable: widget.controllerNotifier,
        builder: (context, controller, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Artwork (existing code)
                      Center(
                        child: Hero(
                          tag: 'podcast_art_${widget.podcast.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                widget.podcast.thumbnailUrl,
                                width: 280,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 280,
                                  height: 280,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Title & Subtitle (existing code)
                      Text(
                        widget.podcast.title,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.podcast.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Metadata (existing code)
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${widget.podcast.playCount} plays', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(widget.podcast.duration.isNotEmpty ? widget.podcast.duration : '25:00', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Player UI
                      if (controller != null)
                        ValueListenableBuilder(
                          valueListenable: controller,
                          builder: (context, value, child) {
                            return Column(
                              children: [
                                // Progress Bar
                                VideoProgressIndicator(
                                  controller,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.white,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Time Labels
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(value.position),
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(value.duration),
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 40),

                                // Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                     // Download Button
                                  IconButton(
                                    icon: _isDownloading
                                        ? SizedBox(
                                            width: 24, 
                                            height: 24, 
                                            child: CircularProgressIndicator(value: _downloadProgress, strokeWidth: 2, color: Colors.white)
                                          )
                                        : const Icon(Icons.download_rounded, color: Colors.white),
                                    onPressed: _isDownloading ? null : _downloadPodcast,
                                  ),

                                    IconButton(
                                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 32),
                                      onPressed: () {
                                          final newPos = value.position - const Duration(seconds: 10);
                                          widget.onSeek(newPos);
                                      },
                                    ),
                                    
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          )
                                        ]
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 48,
                                        ),
                                        onPressed: widget.onPlayPause,
                                      ),
                                    ),
                                    
                                    IconButton(
                                      icon: const Icon(Icons.forward_30_rounded, color: Colors.white, size: 32),
                                      onPressed: () {
                                          final newPos = value.position + const Duration(seconds: 30);
                                          widget.onSeek(newPos);
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                                      onPressed: () {
                                        Share.share(
                                          'Check out this podcast: ${widget.podcast.title}\n\n${widget.podcast.description}\n\nListen here: ${widget.podcast.audioUrl}',
                                          subject: 'Podcast: ${widget.podcast.title}',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        )
                      else
                        const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      
                      const SizedBox(height: 40),
                      
                      // Description
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'About this episode',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.podcast.description,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[300],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}