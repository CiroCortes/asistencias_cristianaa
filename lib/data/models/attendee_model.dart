import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeeModel {
  final String? id;
  final String name;
  final String type; // 'member', 'visitor', 'listener'
  final String sectorId;
  final String? contactInfo;

  AttendeeModel({
    this.id,
    required this.name,
    required this.type,
    required this.sectorId,
    this.contactInfo,
  });

  factory AttendeeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AttendeeModel(
      id: snapshot.id,
      name: data?['name'],
      type: data?['type'],
      sectorId: data?['sectorId'],
      contactInfo: data?['contactInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "type": type,
      "sectorId": sectorId,
      "contactInfo": contactInfo,
    };
  }
} 