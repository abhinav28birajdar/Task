import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/models/user_model.dart';
import '../core/errors/firebase_error_handler.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  Future<bool> signUp(
      {required String name,
      required String email,
      required String password}) async {
    try {
      _setLoading(true);
      _setError(null);
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user!.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set(UserModel(
            uid: cred.user!.uid,
            name: name,
            email: email,
            createdAt: DateTime.now(),
            theme: 'light',
            biometricEnabled: false,
            notificationsEnabled: true,
          ).toMap());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(FirebaseErrorHandler.getMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _setError(null);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(FirebaseErrorHandler.getMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(cred.user!.uid).set(UserModel(
              uid: cred.user!.uid,
              name: cred.user!.displayName ?? 'User',
              email: cred.user!.email ?? '',
              photoURL: cred.user!.photoURL,
              createdAt: DateTime.now(),
              theme: 'light',
              biometricEnabled: false,
              notificationsEnabled: true,
            ).toMap());
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(FirebaseErrorHandler.getMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(FirebaseErrorHandler.getMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      _setLoading(true);
      _setError(null);
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(FirebaseErrorHandler.getMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<bool> deleteAccount(String password) async {
    try {
      _setLoading(true);
      final user = _auth.currentUser!;
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);

      await _db.collection('users').doc(user.uid).delete();
      final tasks =
          await _db.collection('tasks').where('uid', isEqualTo: user.uid).get();
      for (final doc in tasks.docs) {
        await doc.reference.delete();
      }

      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(FirebaseErrorHandler.getMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
