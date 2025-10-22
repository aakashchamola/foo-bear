import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';
import 'remote_config_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final RemoteConfigService _remoteConfig = RemoteConfigService();

  // User Profile Methods
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? role, // 'male' or 'female'
  }) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).set({
      'email': email,
      'displayName': displayName ?? '',
      'photoUrl': photoUrl ?? '',
      'partnerId': '',
      'role': role ?? '', // Store the role
      'authUid': userId, // Store the Firebase Auth UID
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  // Find or create user profile based on role/gender using Remote Config data
  // IMPORTANT: This is for a SINGLE COUPLE - only 1 male and 1 female document should exist
  static Future<String> findOrCreateUserByRole(
      String authUid, String role) async {
    try {
      print('🔍 Looking for user with role: $role and authUid: $authUid');

      // First check if this auth UID already has a document (user logged in before)
      final existingByAuthUid = await _firestore
          .collection(AppConstants.usersCollection)
          .where('authUid', isEqualTo: authUid)
          .limit(1)
          .get();

      if (existingByAuthUid.docs.isNotEmpty) {
        final docId = existingByAuthUid.docs.first.id;
        print('✅ Welcome back! Found your existing profile: $docId');

        // Update last active
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(docId)
            .update({
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
        });

        return docId;
      }

      // User is new - find THE SINGLE document for this gender
      // For this couple's app, there should only be ONE male and ONE female doc
      final existingByGender = await _firestore
          .collection(AppConstants.usersCollection)
          .where('gender', isEqualTo: role)
          .limit(1)
          .get();

      // Get pre-configured user data from Remote Config
      final userData = _remoteConfig.getUserDataByRole(role);

      if (existingByGender.docs.isNotEmpty) {
        // Found THE document for this gender - claim it with this authUid
        final docId = existingByGender.docs.first.id;
        final existingData =
            existingByGender.docs.first.data() as Map<String, dynamic>;
        final oldAuthUid = existingData['authUid'] ?? '';

        print('✅ Found THE ${role} document: $docId');
        if (oldAuthUid.isNotEmpty && oldAuthUid != authUid) {
          print('🔄 Document was previously used by: $oldAuthUid');
          print('🔄 Now claiming it for new authUid: $authUid (app reinstall)');
        }

        // Update/claim this document with new auth info and Remote Config data
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(docId)
            .update({
          'authUid':
              authUid, // Update to new auth UID (important for reinstalls)
          'role': role,
          'gender': role,
          'name': userData['name'] ?? (role == 'male' ? 'Him' : 'Her'),
          'nickname':
              userData['nickname'] ?? (role == 'male' ? 'King' : 'Queen'),
          'email':
              userData['email'] ?? 'user_${authUid.substring(0, 8)}@ustime.app',
          'displayName': userData['displayName'] ?? userData['name'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'lastActive': FieldValue.serverTimestamp(),
          'isOnline': true,
          // Keep partnerId if it exists (preserve connection)
        });

        print('✅ Claimed/updated document $docId with new authUid');
        return docId;
      }

      // No document exists for this gender - create THE FIRST ONE (initial setup)
      print('📝 Creating THE ${role} document (first time setup)');
      final docRef =
          await _firestore.collection(AppConstants.usersCollection).add({
        'authUid': authUid,
        'role': role,
        'gender': role,
        'name': userData['name'] ?? (role == 'male' ? 'Him' : 'Her'),
        'nickname': userData['nickname'] ?? (role == 'male' ? 'King' : 'Queen'),
        'email':
            userData['email'] ?? 'user_${authUid.substring(0, 8)}@ustime.app',
        'displayName': userData['displayName'] ?? userData['name'] ?? '',
        'photoUrl': userData['photoUrl'] ?? '',
        'partnerId': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': true,
      });

      print('✅ Created THE ${role} document: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error in findOrCreateUserByRole: $e');
      throw 'Error finding/creating user: $e';
    }
  }

  // Get user profile by auth UID (checks both docId and authUid field)
  static Future<DocumentSnapshot?> getUserProfileByAuthUid(
      String authUid) async {
    try {
      // First try direct lookup by document ID
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(authUid)
          .get();

      if (doc.exists) {
        return doc;
      }

      // Try finding by authUid field
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('authUid', isEqualTo: authUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }

      return null;
    } catch (e) {
      throw 'Error getting user profile: $e';
    }
  }

  static Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
  }

  static Stream<DocumentSnapshot> getUserProfileStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots();
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

  // Set typing status
  static Future<void> setTypingStatus(String userId, bool isTyping) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'isTyping': isTyping,
    });
  }

  // Mark all messages from partner as read
  static Future<void> markAllMessagesAsRead(
      String userId, String partnerId) async {
    final chatId = _getChatId(userId, partnerId);

    final unreadMessages = await _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get unread message count as a stream
  static Stream<int> getUnreadMessageCount(String userId, String partnerId) {
    final chatId = _getChatId(userId, partnerId);

    return _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Partner Connection Methods

  // Create a connection request (when user presses the magic button)
  static Future<void> createConnectionRequest(String userId) async {
    await _firestore
        .collection(AppConstants.connectionsCollection)
        .doc(userId)
        .set({
      'userId': userId,
      'status': 'waiting', // waiting, connected
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Check if user is connected
  static Future<bool> isUserConnected(String userId) async {
    final userDoc = await getUserProfile(userId);
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      final partnerId = userData?['partnerId'] as String?;
      return partnerId != null && partnerId.isNotEmpty;
    }
    return false;
  }

  // Listen to connection requests and auto-match
  static Stream<DocumentSnapshot> watchConnectionRequest(String userId) {
    return _firestore
        .collection(AppConstants.connectionsCollection)
        .doc(userId)
        .snapshots();
  }

  // Find and connect with a waiting partner
  static Future<Map<String, dynamic>?> findAndConnectPartner(
      String userId) async {
    try {
      // Get all waiting connection requests except current user
      final waitingRequests = await _firestore
          .collection(AppConstants.connectionsCollection)
          .where('status', isEqualTo: 'waiting')
          .get();

      // Find another user who is waiting (not self)
      DocumentSnapshot? partnerRequest;
      for (var doc in waitingRequests.docs) {
        if (doc.id != userId) {
          partnerRequest = doc;
          break;
        }
      }

      if (partnerRequest != null) {
        final partnerId = partnerRequest.id;

        // Update both users as connected
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'partnerId': partnerId});

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(partnerId)
            .update({'partnerId': userId});

        // Update connection requests to connected
        await _firestore
            .collection(AppConstants.connectionsCollection)
            .doc(userId)
            .update({'status': 'connected', 'partnerId': partnerId});

        await _firestore
            .collection(AppConstants.connectionsCollection)
            .doc(partnerId)
            .update({'status': 'connected', 'partnerId': userId});

        // Get partner info
        final partnerDoc = await getUserProfile(partnerId);
        return partnerDoc.data() as Map<String, dynamic>?;
      }

      return null; // No partner found yet
    } catch (e) {
      throw 'Error connecting: $e';
    }
  }

  // Cancel connection request
  static Future<void> cancelConnectionRequest(String userId) async {
    await _firestore
        .collection(AppConstants.connectionsCollection)
        .doc(userId)
        .delete();
  }

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

  // Photo Gallery Methods
  static Future<void> uploadPhoto({
    required String userDocId,
    required String partnerId,
    required String imagePath,
    String caption = '',
  }) async {
    try {
      // Upload to Firebase Storage
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('photos')
          .child(_getChatId(userDocId, partnerId))
          .child(fileName);

      final uploadTask = await storageRef.putFile(File(imagePath));
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Save metadata to Firestore
      await _firestore.collection(AppConstants.photosCollection).add({
        'imageUrl': imageUrl,
        'caption': caption,
        'uploadedBy': userDocId,
        'partnerId': partnerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Upload photo error: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getSharedPhotos(
      String userDocId, String partnerId) {
    // Get photos where either user is the uploader (since both should see all)
    return _firestore
        .collection(AppConstants.photosCollection)
        .where('partnerId', whereIn: [userDocId, partnerId])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Shared Diary Methods (updated to support shared diary)
  static Future<void> createSharedDiaryEntry({
    required String authorDocId,
    required String partnerId,
    required String title,
    required String content,
    String mood = 'happy',
  }) async {
    await _firestore.collection(AppConstants.diaryCollection).add({
      'authorDocId': authorDocId,
      'partnerId': partnerId,
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getSharedDiaryEntries(
      String userDocId, String partnerId) {
    // Get all diary entries where either user is involved
    return _firestore
        .collection(AppConstants.diaryCollection)
        .where('partnerId', whereIn: [userDocId, partnerId])
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
