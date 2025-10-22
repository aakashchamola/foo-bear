import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class DiaryScreen extends StatefulWidget {
  final String partnerId;

  const DiaryScreen({super.key, required this.partnerId});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _showAddEntryDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String selectedMood = 'happy';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'New Memory 📝',
            style: TextStyle(fontFamily: 'Pacifico'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What happened today?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title, color: AppConstants.heartRed),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Your thoughts',
                    hintText: 'Write about your day...',
                    border: OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.edit_note, color: AppConstants.heartRed),
                  ),
                  maxLines: 5,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                const Text(
                  'How are you feeling?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildMoodChip('happy', '😊', selectedMood, setState),
                    _buildMoodChip('love', '💕', selectedMood, setState),
                    _buildMoodChip('excited', '🎉', selectedMood, setState),
                    _buildMoodChip('grateful', '🙏', selectedMood, setState),
                    _buildMoodChip('sad', '😢', selectedMood, setState),
                    _buildMoodChip('thoughtful', '🤔', selectedMood, setState),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'mood': selectedMood,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _saveEntry(result);
    }
  }

  Widget _buildMoodChip(
      String mood, String emoji, String selectedMood, StateSetter setState) {
    final isSelected = mood == selectedMood;
    return ChoiceChip(
      label: Text(emoji, style: const TextStyle(fontSize: 20)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedMood = mood;
          });
        }
      },
      selectedColor: AppConstants.primaryPink.withOpacity(0.3),
      backgroundColor: Colors.grey[200],
    );
  }

  Future<void> _saveEntry(Map<String, dynamic> entryData) async {
    try {
      final userDocId = await UserService.getUserDocId();
      if (userDocId == null) {
        throw Exception('User not found');
      }

      await FirestoreService.createSharedDiaryEntry(
        authorDocId: userDocId,
        partnerId: widget.partnerId,
        title: entryData['title'],
        content: entryData['content'],
        mood: entryData['mood'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory saved! 💝'),
            backgroundColor: AppConstants.heartRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'love':
        return '💕';
      case 'excited':
        return '🎉';
      case 'grateful':
        return '🙏';
      case 'sad':
        return '😢';
      case 'thoughtful':
        return '🤔';
      default:
        return '📝';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Our Diary 📖',
          style: TextStyle(fontFamily: 'Pacifico', fontSize: 24),
        ),
        backgroundColor: AppConstants.primaryPink,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryPink.withOpacity(0.1),
              AppConstants.secondaryPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: FutureBuilder<String?>(
          future: UserService.getUserDocId(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppConstants.heartRed),
              );
            }

            final userDocId = userSnapshot.data!;

            return StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.getSharedDiaryEntries(
                  userDocId, widget.partnerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppConstants.heartRed),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 80,
                          color: AppConstants.textDark.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No memories yet\nStart writing your story together! 💕',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final entries = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entryData =
                        entries[index].data() as Map<String, dynamic>;
                    final title = entryData['title'] as String;
                    final content = entryData['content'] as String;
                    final mood = entryData['mood'] as String? ?? 'happy';
                    final authorDocId = entryData['authorDocId'] as String;
                    final timestamp = entryData['timestamp'] as Timestamp?;
                    final isAuthor = authorDocId == userDocId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                isAuthor
                                    ? AppConstants.primaryPink.withOpacity(0.05)
                                    : AppConstants.secondaryPurple
                                        .withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryPink
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getMoodEmoji(mood),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isAuthor
                                                      ? AppConstants.heartRed
                                                      : AppConstants
                                                          .secondaryPurple,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isAuthor ? 'You' : 'Partner',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (timestamp != null)
                                                Flexible(
                                                  child: Text(
                                                    _formatDate(
                                                        timestamp.toDate()),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppConstants
                                                          .textDark
                                                          .withOpacity(0.6),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  content,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showAddEntryDialog,
          backgroundColor: AppConstants.heartRed,
          icon: const Icon(Icons.add),
          label: const Text('Write'),
        ),
      ),
    );
  }
}
