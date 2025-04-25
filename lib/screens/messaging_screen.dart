import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:coffeecore/utils/role_utils.dart';

class MessagingScreen extends StatefulWidget {
  final String cooperativeName;
  final String? initialChat;

  const MessagingScreen({super.key, required this.cooperativeName, this.initialChat});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final logger = Logger(printer: PrettyPrinter());
  String? _userId;
  String? _userRole;
  String? _selectedChat;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _selectedChat = widget.initialChat;
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (_userId == null) return;
    String role = await RoleUtils.getUserRole(_userId!, widget.cooperativeName);
    setState(() {
      _userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
    final chatGroups = [
      {'name': 'Market Managers', 'id': '${formattedCoopName}_Prices'},
      {'name': 'Cooperative Users', 'id': '${formattedCoopName}_Users'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: _selectedChat == null
          ? ListView.builder(
              itemCount: chatGroups.length,
              itemBuilder: (context, index) {
                final chat = chatGroups[index];
                return ListTile(
                  leading: Icon(Icons.group, color: Colors.brown[700]),
                  title: Text(chat['name']!),
                  onTap: () {
                    setState(() {
                      _selectedChat = chat['id'];
                    });
                  },
                );
              },
            )
          : ChatScreen(
              cooperativeName: widget.cooperativeName,
              chatId: _selectedChat!,
              userId: _userId,
              userRole: _userRole,
            ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String cooperativeName;
  final String chatId;
  final String? userId;
  final String? userRole;

  const ChatScreen({
    super.key,
    required this.cooperativeName,
    required this.chatId,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final logger = Logger(printer: PrettyPrinter());
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.userId == null) return;
    try {
      String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
      await FirebaseFirestore.instance
          .collection('${formattedCoopName}_messages')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': widget.userId,
        'message': _messageController.text.trim(),
        'timestamp': Timestamp.now(),
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      logger.e('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedCoopName = widget.cooperativeName.replaceAll(' ', '_');
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('${formattedCoopName}_messages')
                .doc(widget.chatId)
                .collection('messages')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                logger.e('Error loading messages: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final messages = snapshot.data!.docs;
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index].data() as Map<String, dynamic>;
                  final isMe = message['senderId'] == widget.userId;
                  return FutureBuilder<String>(
                    future: RoleUtils.getUserRole(message['senderId'], widget.cooperativeName),
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final senderRole = roleSnapshot.data ?? 'User';
                      final isAdminMessage =
                          senderRole == 'Coop Admin' && widget.chatId.contains('_Prices');

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF006400) // Darkest green for host
                                : isAdminMessage
                                    ? Colors.brown[900] // Theme brown for admin
                                    : const Color(0xFF333333), // Darkest gray for others
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message['message'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.brown[700]),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}