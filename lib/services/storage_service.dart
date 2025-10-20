import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/constants.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile image
  static Future<String> uploadProfileImage(
      String userId, File imageFile) async {
    final ref =
        _storage.ref().child('${AppConstants.profileImagePath}$userId.jpg');
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  // Upload gallery image
  static Future<String> uploadGalleryImage(
      String userId, File imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child('${AppConstants.galleryImagePath}${userId}_$timestamp.jpg');
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  // Upload secret gallery image (encrypted)
  static Future<String> uploadSecretImage(String userId, File imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child('${AppConstants.secretGalleryPath}${userId}_$timestamp.jpg');
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  // Upload from bytes (useful for encrypted data)
  static Future<String> uploadBytesData({
    required String path,
    required Uint8List data,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = ref.putData(data, metadata);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  // Delete file
  static Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  // Get download URL
  static Future<String> getDownloadURL(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }

  // Get file metadata
  static Future<FullMetadata> getMetadata(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getMetadata();
  }

  // Download file as bytes
  static Future<Uint8List?> downloadFileAsBytes(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getData();
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  // Upload with progress tracking
  static Stream<TaskSnapshot> uploadWithProgress(String path, File file) {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    return uploadTask.snapshotEvents;
  }

  // List files in a directory
  static Future<ListResult> listFiles(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.listAll();
  }
}
