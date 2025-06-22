import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final DateTime? createdAt;
  final List<String> favoriteTeams;
  final List<String> favoriteSports;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.createdAt,
    this.favoriteTeams = const [],
    this.favoriteSports = const [],
  });

  // Convertir de Firestore a UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      favoriteTeams: List<String>.from(data['favoriteTeams'] ?? []),
      favoriteSports: List<String>.from(data['favoriteSports'] ?? []),
    );
  }

  // Convertir de UserModel a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'favoriteTeams': favoriteTeams,
      'favoriteSports': favoriteSports,
    };
  }
}
