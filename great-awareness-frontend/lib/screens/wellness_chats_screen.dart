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
import 'people_wellness_screen.dart';

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
  
  // Presence State
  List<Map<String, dynamic>> _onlineUsers = [];
  final Map<String, String> _typingUsers = {}; // userId -> userName
  Timer? _typingDebounce;
  bool _isTyping = false;

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
          senderId: msgData['user_id'],
          senderProfilePic: msgData['user_avatar'],
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
      _sendMessage({
        'type': 'join', 
        'user': {
          'id': _currentUser.id, 
          'name': _currentUser.name,
          'profilePictureUrl': _currentUser.profileImage,
        }
      });

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _handleWebSocketMessage(data);
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

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    switch (data['type']) {
      case 'new_message':
        _handleNewMessage(data['message']);
        break;
      case 'presence_update':
        setState(() {
          _onlineUsers = List<Map<String, dynamic>>.from(data['users']);
        });
        break;
      case 'typing_start':
        setState(() {
          _typingUsers[data['userId']] = data['userName'];
        });
        break;
      case 'typing_stop':
        setState(() {
          _typingUsers.remove(data['userId']);
        });
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> msgData) {
    final newMessage = ChatMessage(
      id: msgData['id'],
      senderName: msgData['user_name'],
      senderId: msgData['user_id'],
      senderProfilePic: msgData['user_avatar'],
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

  void _onTyping() {
    if (!_isConnected) return;

    if (!_isTyping) {
      _isTyping = true;
      _sendMessage({'type': 'typing_start'});
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted && _isTyping) {
        _isTyping = false;
        _sendMessage({'type': 'typing_stop'});
      }
    });
  }

  void _sendMessagePayload() {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    
    // Stop typing immediately
    _isTyping = false;
    _typingDebounce?.cancel();
    _sendMessage({'type': 'typing_stop'});

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

  void _showParticipantsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Live Participants",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Text(
                        "${_onlineUsers.length} Online",
                        style: GoogleFonts.inter(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _onlineUsers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final user = _onlineUsers[index];
                    final isMe = user['id'] == _currentUser.id;
                    
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PeopleWellnessScreen(
                              userId: user['id'],
                              userName: user['name'],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueGrey[100],
                                image: user['profilePictureUrl'] != null 
                                  ? DecorationImage(
                                      image: NetworkImage(user['profilePictureUrl']),
                                      fit: BoxFit.cover
                                    )
                                  : null,
                              ),
                              alignment: Alignment.center,
                              child: user['profilePictureUrl'] == null
                                  ? Text(
                                      (user['name'] ?? "?")[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? "Anonymous",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (isMe)
                                    Text(
                                      "You",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green[400],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _typingDebounce?.cancel();
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
        title: GestureDetector(
          onTap: _showParticipantsPanel,
          child: Column(
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
                    _isConnected ? "Live • ${_onlineUsers.length} Online" : "Connecting...",
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
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

            // Typing Indicator
            if (_typingUsers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTypingText(),
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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
                        onChanged: (_) => _onTyping(),
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

  String _getTypingText() {
    if (_typingUsers.isEmpty) return "";
    final names = _typingUsers.values.toList();
    if (names.length == 1) return "${names[0]} is typing...";
    if (names.length == 2) return "${names[0]} and ${names[1]} are typing...";
    return "${names.length} people are typing...";
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          // Navigate to profile if senderId is available and not me
          if (!msg.isMe && msg.senderId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PeopleWellnessScreen(
                  userId: msg.senderId,
                  userName: msg.senderName,
                ),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!msg.isMe) ...[
                // Tiny Profile Picture
                Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 4),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueGrey[100],
                    image: msg.senderProfilePic != null 
                      ? DecorationImage(
                          image: NetworkImage(msg.senderProfilePic!),
                          fit: BoxFit.cover
                        )
                      : null,
                  ),
                  alignment: Alignment.center,
                  child: msg.senderProfilePic == null
                      ? Text(
                          (msg.senderName.isNotEmpty ? msg.senderName[0] : "?").toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
              ],
              
              Flexible(
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
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderName;
  final String? senderId;
  final String? senderProfilePic;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderName,
    this.senderId,
    this.senderProfilePic,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });
}
