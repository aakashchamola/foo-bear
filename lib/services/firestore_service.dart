import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Profile Methods
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).set({
      'email': email,
      'displayName': displayName ?? '',
      'photoUrl': photoUrl ?? '',
      'partnerId': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  static Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
  }

  static Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  static Future<void> setUserOnlineStatus(String userId, bool isOnline) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // Partner Connection Methods
  static Future<void> connectPartner(String userId, String partnerEmail) async {
    // Find partner by email
    final partnerQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: partnerEmail)
        .get();

    if (partnerQuery.docs.isNotEmpty) {
      final partnerId = partnerQuery.docs.first.id;

      // Update both users with partner IDs
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'partnerId': partnerId});

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(partnerId)
          .update({'partnerId': userId});
    } else {
      throw 'Partner not found with email: $partnerEmail';
    }
  }

  // Message Methods
  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String type = 'text',
  }) async {
    final chatId = _getChatId(senderId, receiverId);

    await _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update last message in chat document
    await _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .set({
      'participants': [senderId, receiverId],
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> getMessages(String userId, String partnerId) {
    final chatId = _getChatId(userId, partnerId);

    return _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> markMessageAsRead(
      String userId, String partnerId, String messageId) async {
    final chatId = _getChatId(userId, partnerId);

    await _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Love Notification Methods
  static Future<void> sendLoveNotification({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    await _firestore.collection(AppConstants.notificationsCollection).add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': 'love_button',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Photo Gallery Methods
  static Future<void> addPhoto({
    required String userId,
    required String photoUrl,
    required String caption,
    bool isSecret = false,
  }) async {
    await _firestore.collection(AppConstants.photosCollection).add({
      'userId': userId,
      'photoUrl': photoUrl,
      'caption': caption,
      'isSecret': isSecret,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    });
  }

  static Stream<QuerySnapshot> getPhotos(bool isSecret) {
    return _firestore
        .collection(AppConstants.photosCollection)
        .where('isSecret', isEqualTo: isSecret)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Diary Methods
  static Future<void> addDiaryEntry({
    required String userId,
    required String title,
    required String content,
    String mood = 'happy',
  }) async {
    await _firestore.collection(AppConstants.diaryCollection).add({
      'userId': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getDiaryEntries(String userId) {
    return _firestore
        .collection(AppConstants.diaryCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Helper method to generate consistent chat ID
  static String _getChatId(String userId1, String userId2) {
    final List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }
}
