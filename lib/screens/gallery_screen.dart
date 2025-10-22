import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class GalleryScreen extends StatefulWidget {
  final String partnerId;

  const GalleryScreen({super.key, required this.partnerId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isUploading = false;

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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      // Show caption dialog
      final caption = await _showCaptionDialog();
      if (caption == null) return;

      setState(() => _isUploading = true);

      final userDocId = await UserService.getUserDocId();
      if (userDocId == null) {
        throw Exception('User not found');
      }

      await FirestoreService.uploadPhoto(
        userDocId: userDocId,
        partnerId: widget.partnerId,
        imagePath: image.path,
        caption: caption,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded! 💕'),
            backgroundColor: AppConstants.heartRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _showCaptionDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a caption',
            style: TextStyle(fontFamily: 'Pacifico')),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What\'s this moment about? 💭',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Our Gallery 📸',
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
              stream:
                  FirestoreService.getSharedPhotos(userDocId, widget.partnerId),
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
                          Icons.photo_library_outlined,
                          size: 80,
                          color: AppConstants.textDark.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No photos yet\nStart capturing your memories! 📷',
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

                final photos = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photoData =
                        photos[index].data() as Map<String, dynamic>;
                    final imageUrl = photoData['imageUrl'] as String;
                    final caption = photoData['caption'] as String? ?? '';
                    final uploadedBy = photoData['uploadedBy'] as String;
                    final timestamp = photoData['timestamp'] as Timestamp?;
                    final isUploadedByMe = uploadedBy == userDocId;

                    return GestureDetector(
                      onTap: () => _showPhotoDetail(
                        imageUrl,
                        caption,
                        isUploadedByMe,
                        timestamp,
                      ),
                      child: Hero(
                        tag: imageUrl,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.shadowColor,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppConstants.primaryPink
                                          .withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppConstants.heartRed,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Polaroid-style bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (caption.isNotEmpty)
                                          Text(
                                            caption,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isUploadedByMe ? 'You' : 'Partner',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
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
      floatingActionButton: _isUploading
          ? const CircularProgressIndicator(color: AppConstants.heartRed)
          : ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: _pickAndUploadImage,
                backgroundColor: AppConstants.heartRed,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
              ),
            ),
    );
  }

  void _showPhotoDetail(
    String imageUrl,
    String caption,
    bool isUploadedByMe,
    Timestamp? timestamp,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: imageUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption.isNotEmpty) ...[
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUploadedByMe
                            ? 'Uploaded by You'
                            : 'Uploaded by Partner',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textDark.withOpacity(0.6),
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatDate(timestamp.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textDark.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
