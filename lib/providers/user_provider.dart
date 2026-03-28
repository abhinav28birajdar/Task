import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';
import '../data/models/user_model.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _user;
  bool _isLoading = false;
  StreamSubscription? _userSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!);
      }
      // Start listening for real-time updates after load
      startListening(uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startListening(String uid) {
    _userSubscription?.cancel();
    _userSubscription =
        _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    }, onError: (e) {
      print('Error listening to user updates: $e');
    });
  }

  void ensureListening() {
    final uid = _auth.currentUser?.uid;
    if (uid != null && _userSubscription == null) {
      startListening(uid);
    }
  }

  Future<bool> updateProfile({String? name, String? photoURL}) async {
    try {
      final uid = _auth.currentUser!.uid;
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
      }

      await _db.collection('users').doc(uid).update(updates);

      if (name != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }
      if (photoURL != null) {
        await _auth.currentUser!.updatePhotoURL(photoURL);
      }
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> updateAvatar(String filePath) async {
    try {
      _isLoading = true;
      notifyListeners();
      final uid = _auth.currentUser!.uid;
      final file = File(filePath);
      final url = await StorageService.instance.uploadAvatar(uid, file);
      if (url != null) {
        await updateProfile(photoURL: url);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating avatar: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) return false;

      // Reauthenticate user
      final email = user.email;
      if (email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmail(String newEmail, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Reauthenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email in Firebase Auth
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update in Firestore
      await _db.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating email: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
