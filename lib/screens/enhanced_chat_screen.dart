import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String partnerId;

  const EnhancedChatScreen({super.key, required this.partnerId});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _partnerName;
  bool _partnerIsOnline = false;
  DateTime? _partnerLastSeen;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
    _messageController.addListener(_onTypingChanged);
  }

  void _onTypingChanged() {
    final isTypingNow = _messageController.text.isNotEmpty;
    if (isTypingNow != _isTyping) {
      setState(() {
        _isTyping = isTypingNow;
      });
      _updateTypingStatus(isTypingNow);
    }
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    final userDocId = await UserService.getUserDocId();
    if (userDocId != null) {
      await FirestoreService.setTypingStatus(userDocId, isTyping);
    }
  }

  Future<void> _loadPartnerInfo() async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      try {
        // Use the passed partnerId from widget
        final partnerDoc =
            await FirestoreService.getUserProfile(widget.partnerId);

        if (partnerDoc.exists && mounted) {
          final partnerData = partnerDoc.data() as Map<String, dynamic>?;
          setState(() {
            _partnerName =
                partnerData?['name'] ?? partnerData?['nickname'] ?? 'Partner';
            _partnerIsOnline = partnerData?['isOnline'] ?? false;
            final lastActive = partnerData?['lastActive'] as Timestamp?;
            _partnerLastSeen = lastActive?.toDate();
          });

          // Listen to partner's status changes
          FirestoreService.getUserProfileStream(widget.partnerId)
              .listen((snapshot) {
            if (snapshot.exists && mounted) {
              final partnerData = snapshot.data() as Map<String, dynamic>?;
              setState(() {
                _partnerName = partnerData?['name'] ??
                    partnerData?['nickname'] ??
                    'Partner';
                _partnerIsOnline = partnerData?['isOnline'] ?? false;
                final lastActive = partnerData?['lastActive'] as Timestamp?;
                _partnerLastSeen = lastActive?.toDate();
              });
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading partner info: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      final userDocId = await UserService.getUserDocId();
      if (userDocId != null) {
        await FirestoreService.sendMessage(
          senderId: userDocId,
          receiverId: widget.partnerId,
          message: _messageController.text.trim(),
        );

        _messageController.clear();
        _updateTypingStatus(false);

        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppConstants.heartRed,
          ),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    final userDocId = await UserService.getUserDocId();
    if (userDocId != null) {
      await FirestoreService.markAllMessagesAsRead(userDocId, widget.partnerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_partnerName ?? 'Chat'),
            const SizedBox(height: 2),
            Text(
              _partnerIsOnline
                  ? 'Online 🟢'
                  : _partnerLastSeen != null
                      ? 'Last seen ${_formatLastSeen(_partnerLastSeen!)}'
                      : 'Offline',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.pinkGradient,
        ),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: FutureBuilder<String?>(
                future: UserService.getUserDocId(),
                builder: (context, userDocSnapshot) {
                  if (!userDocSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppConstants.heartRed),
                    );
                  }

                  final userDocId = userDocSnapshot.data!;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirestoreService.getMessages(
                        userDocId, widget.partnerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppConstants.heartRed),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 60, color: AppConstants.textDark),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet\nSend your first love message! 💕',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, color: AppConstants.textDark),
                              ),
                            ],
                          ),
                        );
                      }

                      // Mark messages as read when viewing
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead();
                      });

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageData =
                              messages[index].data() as Map<String, dynamic>;
                          final isMe = messageData['senderId'] == userDocId;
                          final message = messageData['message'] as String;
                          final timestamp =
                              messageData['timestamp'] as Timestamp?;
                          final isRead = messageData['isRead'] ?? false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppConstants.heartRed
                                        : Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppConstants.shadowColor,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : AppConstants.textDark,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (timestamp != null)
                                            Text(
                                              _formatTime(timestamp.toDate()),
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                        .withOpacity(0.7)
                                                    : AppConstants.textDark
                                                        .withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              isRead
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 16,
                                              color: isRead
                                                  ? Colors.lightBlueAccent
                                                  : Colors.white
                                                      .withOpacity(0.7),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a love message... 💕',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppConstants.heartRed,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _updateTypingStatus(false);
    super.dispose();
  }
}
