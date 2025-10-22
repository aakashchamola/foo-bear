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

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _partnerName;
  bool _partnerIsOnline = false;
  DateTime? _partnerLastSeen;
  bool _isTyping = false;
  bool _partnerIsTyping = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  late AnimationController _emojiPanelController;
  late Animation<double> _emojiPanelAnimation;
  bool _showEmojiPicker = false;
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _typingAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _emojiPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _emojiPanelAnimation = CurvedAnimation(
      parent: _emojiPanelController,
      curve: Curves.easeOutCubic,
    );
    _loadPartnerInfo();
    _listenToPartnerTyping();
    _messageController.addListener(_onTypingChanged);
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus && _showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
        _emojiPanelController.reverse();
      }
    });
  }

  void _listenToPartnerTyping() {
    FirestoreService.getPartnerTypingStatus(widget.partnerId)
        .listen((isTyping) {
      if (mounted) {
        setState(() {
          _partnerIsTyping = isTyping;
        });
        // Debug print
        debugPrint('Partner typing status: $isTyping');
      }
    });
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
      // Debug print
      debugPrint('My typing status updated to: $isTyping');
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

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      _messageFocusNode.unfocus();
      _emojiPanelController.forward();
    } else {
      _emojiPanelController.reverse();
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  Widget _buildEmojiPicker() {
    // Categorized emojis like Telegram
    final emojiCategories = {
      '❤️ Love': [
        '❤️',
        '💕',
        '💖',
        '💗',
        '💓',
        '💝',
        '💘',
        '💞',
        '💌',
        '💟',
        '💑',
        '💏',
        '👩‍❤️‍👨',
        '💋',
        '😍',
        '🥰',
        '😘',
        '😻',
        '💗',
        '💓'
      ],
      '😊 Smileys': [
        '😊',
        '😀',
        '😃',
        '😄',
        '😁',
        '😆',
        '🥹',
        '😅',
        '😂',
        '🤣',
        '😇',
        '🙂',
        '🙃',
        '😉',
        '😌',
        '😍',
        '🥰',
        '😘',
        '😗',
        '😙'
      ],
      '😢 Emotions': [
        '😢',
        '😭',
        '😔',
        '😞',
        '😟',
        '😕',
        '🙁',
        '😣',
        '😖',
        '😫',
        '😩',
        '🥺',
        '😤',
        '😠',
        '😡',
        '🤬',
        '😳',
        '🥵',
        '🥶',
        '😱'
      ],
      '🎉 Celebrations': [
        '🎉',
        '🎊',
        '🎈',
        '🎁',
        '🎀',
        '🎂',
        '🍰',
        '🧁',
        '🥳',
        '🎆',
        '🎇',
        '✨',
        '🎄',
        '🎃',
        '💐',
        '🌹',
        '🌺',
        '🌸',
        '🌼',
        '🌻'
      ],
      '🤔 Gestures': [
        '🤔',
        '🤨',
        '🧐',
        '🤓',
        '😎',
        '🥸',
        '🤩',
        '🥳',
        '😏',
        '😒',
        '🙄',
        '😬',
        '🤥',
        '😶',
        '😐',
        '😑',
        '😯',
        '😦',
        '😧',
        '😮'
      ],
      '👋 Hands': [
        '👋',
        '🤚',
        '🖐️',
        '✋',
        '🖖',
        '👌',
        '🤌',
        '🤏',
        '✌️',
        '🤞',
        '🤟',
        '🤘',
        '🤙',
        '👈',
        '👉',
        '👆',
        '👇',
        '☝️',
        '👍',
        '👎'
      ],
      '🔥 Popular': [
        '🔥',
        '💯',
        '✨',
        '⭐',
        '🌟',
        '💫',
        '✅',
        '❌',
        '💀',
        '👻',
        '🤡',
        '💩',
        '🙈',
        '🙉',
        '🙊',
        '👀',
        '💤',
        '💢',
        '💬',
        '🗨️'
      ],
      '🌈 Nature': [
        '🌈',
        '☀️',
        '⛅',
        '🌤️',
        '⛈️',
        '🌧️',
        '🌩️',
        '⚡',
        '❄️',
        '☃️',
        '🌊',
        '🌙',
        '⭐',
        '🌟',
        '💫',
        '🌸',
        '🌺',
        '🌻',
        '🌹',
        '🌷'
      ],
    };

    return SizeTransition(
      sizeFactor: _emojiPanelAnimation,
      axisAlignment: -1,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: AppConstants.borderGrey,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pick an emoji',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textLight,
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleEmojiPicker,
                    icon:
                        const Icon(Icons.close, color: AppConstants.textLight),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppConstants.borderGrey),
            // Emoji grid with categories
            Expanded(
              child: DefaultTabController(
                length: emojiCategories.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      indicatorColor: AppConstants.accentBlue,
                      labelColor: AppConstants.accentBlue,
                      unselectedLabelColor: AppConstants.textMuted,
                      tabs: emojiCategories.keys.map((category) {
                        return Tab(
                          child: Text(
                            category.split(' ')[0],
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: emojiCategories.values.map((emojis) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: emojis.length,
                            itemBuilder: (context, index) {
                              final emoji = emojis[index];
                              return InkWell(
                                onTap: () => _insertEmoji(emoji),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppConstants.secondaryDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppConstants.borderGrey,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_partnerName ?? 'Chat',
                style: const TextStyle(color: AppConstants.textLight)),
            const SizedBox(height: 2),
            _partnerIsTyping
                ? FadeTransition(
                    opacity: _typingAnimation,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'typing',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.accentTeal,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: AppConstants.accentTeal,
                        ),
                      ],
                    ),
                  )
                : Text(
                    _partnerIsOnline
                        ? 'Online 🟢'
                        : _partnerLastSeen != null
                            ? 'Last seen ${_formatLastSeen(_partnerLastSeen!)}'
                            : 'Offline',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppConstants.textMuted,
                    ),
                  ),
          ],
        ),
        backgroundColor: AppConstants.secondaryDark,
        foregroundColor: AppConstants.textLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textLight),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.darkGradient,
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
                          color: AppConstants.accentBlue),
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
                              color: AppConstants.accentBlue),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 60, color: AppConstants.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet\nSend your first message! �',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppConstants.textMuted),
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
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Partner avatar for received messages
                                if (!isMe) ...[
                                  Container(
                                    width: 32,
                                    height: 32,
                                    margin: const EdgeInsets.only(
                                        right: 8, bottom: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppConstants.accentBlue,
                                          AppConstants.accentTeal,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppConstants.accentBlue
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '�',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                                // Message bubble
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.75,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isMe
                                          ? AppConstants.blueGradient
                                          : null,
                                      color: isMe
                                          ? null
                                          : AppConstants.receivedMessageBg,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft:
                                            Radius.circular(isMe ? 18 : 4),
                                        bottomRight:
                                            Radius.circular(isMe ? 4 : 18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isMe
                                              ? AppConstants.accentBlue
                                                  .withOpacity(0.25)
                                              : Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
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
                                                : AppConstants.textLight,
                                            fontSize: 15.5,
                                            height: 1.4,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (timestamp != null)
                                              Text(
                                                _formatTime(timestamp.toDate()),
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                          .withOpacity(0.75)
                                                      : AppConstants.textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            if (isMe) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                isRead
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 15,
                                                color: isRead
                                                    ? const Color(0xFF64B5F6)
                                                    : Colors.white
                                                        .withOpacity(0.75),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
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

            // Emoji Picker
            if (_showEmojiPicker) _buildEmojiPicker(),

            // Message input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.secondaryDark,
                border: Border(
                  top: BorderSide(
                    color: AppConstants.borderGrey,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Emoji button
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _showEmojiPicker
                            ? AppConstants.accentBlue.withOpacity(0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _toggleEmojiPicker,
                        icon: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard
                              : Icons.emoji_emotions,
                          color: _showEmojiPicker
                              ? AppConstants.accentBlue
                              : AppConstants.textMuted,
                        ),
                        iconSize: 26,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Message field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 120,
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(
                              color: AppConstants.textMuted,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppConstants.borderGrey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppConstants.borderGrey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppConstants.accentBlue,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: AppConstants.cardDark,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppConstants.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button with smooth animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        gradient: _messageController.text.trim().isNotEmpty
                            ? AppConstants.blueGradient
                            : null,
                        color: _messageController.text.trim().isEmpty
                            ? AppConstants.borderGrey
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: _messageController.text.trim().isNotEmpty
                            ? [
                                BoxShadow(
                                  color:
                                      AppConstants.accentBlue.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: IconButton(
                        onPressed: _messageController.text.trim().isNotEmpty
                            ? _sendMessage
                            : null,
                        icon:
                            const Icon(Icons.send_rounded, color: Colors.white),
                        iconSize: 22,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
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
    _messageFocusNode.dispose();
    _typingAnimationController.dispose();
    _emojiPanelController.dispose();
    _updateTypingStatus(false);
    super.dispose();
  }
}
