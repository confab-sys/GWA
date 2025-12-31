import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class WellnessChatsScreen extends StatefulWidget {
  const WellnessChatsScreen({super.key});

  @override
  State<WellnessChatsScreen> createState() => _WellnessChatsScreenState();
}

class _WellnessChatsScreenState extends State<WellnessChatsScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  WebSocketChannel? _channel;
  final List<ChatMessage> _messages = [];
  bool _isConnected = false;
  String? _errorMessage;
  late User _currentUser;
  bool _isLoading = true;

  // Configuration - should be in config.dart ideally
  static const String _wsUrl = 'wss://gwa-chat-worker.aashardcustomz.workers.dev/room/wellness';
  static const String _historyUrl = 'https://gwa-chat-worker.aashardcustomz.workers.dev/room/wellness/history';

  @override
  void initState() {
    super.initState();
    _loadUserAndConnect();
  }

  Future<void> _loadUserAndConnect() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthentication();
    final user = authService.currentUser;
    
    if (mounted) {
      setState(() {
        _currentUser = user ?? User(
          id: 'anon-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Anonymous',
          email: 'anon@example.com',
          role: 'user',
        );
      });
      
      await _fetchHistory();
      
      if (mounted) {
        setState(() => _isLoading = false);
        _connectWebSocket();
      }
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await http.get(Uri.parse(_historyUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final history = data.map((msgData) => ChatMessage(
          id: msgData['id'] ?? 'unknown',
          senderName: msgData['user_name'] ?? 'Anonymous',
          content: msgData['content'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(msgData['created_at'] ?? 0),
          isMe: msgData['user_name'] == _currentUser.name,
        )).toList();

        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(history);
            // Sort by timestamp (oldest first)
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          
          // Scroll to bottom after a slight delay
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        }
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      setState(() {
        _isConnected = true;
        _errorMessage = null;
      });

      // Send join message
      _sendMessage({'type': 'join', 'user': {'id': _currentUser.id, 'name': _currentUser.name}});

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'new_message') {
            _handleNewMessage(data['message']);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _errorMessage = 'Connection lost. Reconnecting...';
            });
            // Simple reconnect logic
            Future.delayed(const Duration(seconds: 3), _connectWebSocket);
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isConnected = false);
          }
        },
      );
    } catch (e) {
      setState(() => _errorMessage = 'Could not connect to chat server.');
    }
  }

  void _handleNewMessage(Map<String, dynamic> msgData) {
    final newMessage = ChatMessage(
      id: msgData['id'],
      senderName: msgData['user_name'],
      content: msgData['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(msgData['created_at']),
      isMe: msgData['user_name'] == _currentUser.name, // Simple check, ideally use ID
    );

    if (mounted) {
      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
    }
  }

  void _sendMessagePayload() {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    
    // Send to WebSocket
    _sendMessage({
      'type': 'message',
      'content': content,
    });

    _messageController.clear();
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Soft color palette
    final bgStart = Colors.grey[50]!;
    final bgEnd = Colors.blueGrey[50]!;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Wellness Chat",
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green[400] : Colors.red[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? "Live • ${(_messages.length > 0 ? _messages.length : 1)} Online" : "Connecting...",
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              // Show guidelines
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Community Guidelines", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  content: Text(
                    "This is a shared quiet room.\n\n"
                    "• Support presence, not performance.\n"
                    "• Encourage thoughtful communication.\n"
                    "• No spam or rapid-fire messages.\n\n"
                    "Let's heal together.",
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("I Understand"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: Column(
          children: [
            // Connection Error Banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.red[100],
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.red[800], fontSize: 12),
                ),
              ),
              
            // Chat List
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.spa_outlined, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "A quiet space for healing.\nSay hello.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final showTime = index == 0 || 
                                             msg.timestamp.difference(_messages[index - 1].timestamp).inMinutes > 5;
                            
                            return Column(
                              children: [
                                if (showTime)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      DateFormat.jm().format(msg.timestamp),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                _buildMessageBubble(msg),
                              ],
                            );
                          },
                        ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Share a thought...",
                          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessagePayload(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isConnected ? _sendMessagePayload : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isConnected ? const Color(0xFF6B9080) : Colors.grey[300], // Gentle green
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  msg.senderName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isMe ? const Color(0xFFEAF4F4) : Colors.white, // Gentle mint for me, white for others
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                  bottomRight: Radius.circular(msg.isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });
}
