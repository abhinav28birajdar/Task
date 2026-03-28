import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;
  final DateTime createdAt;
  final String theme;
  final bool biometricEnabled;
  final bool notificationsEnabled;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
    required this.createdAt,
    required this.theme,
    required this.biometricEnabled,
    required this.notificationsEnabled,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoURL,
    DateTime? createdAt,
    String? theme,
    bool? biometricEnabled,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      theme: theme ?? this.theme,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        photoURL: map['photoURL'],
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        theme: map['theme'] ?? 'light',
        biometricEnabled: map['biometricEnabled'] ?? false,
        notificationsEnabled: map['notificationsEnabled'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoURL': photoURL,
        'createdAt': Timestamp.fromDate(createdAt),
        'theme': theme,
        'biometricEnabled': biometricEnabled,
        'notificationsEnabled': notificationsEnabled,
      };
}
