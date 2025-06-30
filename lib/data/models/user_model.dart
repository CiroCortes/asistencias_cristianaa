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
    
    // Verificar que los campos requeridos no sean null
    if (data == null) {
      throw Exception('User data is null for document ${snapshot.id}');
    }
    
    final email = data['email'] as String?;
    final displayName = data['displayName'] as String?;
    final role = data['role'] as String?;
    
    if (email == null || email.isEmpty) {
      throw Exception('User email is null or empty for document ${snapshot.id}');
    }
    if (displayName == null || displayName.isEmpty) {
      throw Exception('User displayName is null or empty for document ${snapshot.id}');
    }
    if (role == null || role.isEmpty) {
      throw Exception('User role is null or empty for document ${snapshot.id}');
    }
    
    return UserModel(
      uid: snapshot.id,
      email: email,
      displayName: displayName,
      role: role,
      sectorId: data['sectorId'] as String?,
      isApproved: data['isApproved'] ?? false,
      photoUrl: data['photoUrl'] as String?,
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