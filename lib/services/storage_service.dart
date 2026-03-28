import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final instance = StorageService._();
  StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadAvatar(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('avatars/$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAvatar(String uid) async {
    try {
      final ref = _storage.ref().child('avatars/$uid.jpg');
      await ref.delete();
    } catch (e) {
      // ignore
    }
  }
}
