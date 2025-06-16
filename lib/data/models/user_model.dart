import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'normal_user', 'admin'
  final String? sectorId; // ID del sector al que pertenece el usuario normal
  final bool isApproved; // Para la aprobación del administrador
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.sectorId,
    required this.isApproved,
    this.photoUrl,
  });

  factory UserModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return UserModel(
      uid: snapshot.id,
      email: data?['email'],
      displayName: data?['displayName'],
      role: data?['role'],
      sectorId: data?['sectorId'],
      isApproved: data?['isApproved'] ?? false,
      photoUrl: data?['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "email": email,
      "displayName": displayName,
      "role": role,
      "sectorId": sectorId,
      "isApproved": isApproved,
      "photoUrl": photoUrl,
    };
  }
} 