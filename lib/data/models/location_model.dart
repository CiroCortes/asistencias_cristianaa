import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String? id;
  final String name;
  final String type; // 'city', 'commune', 'sector'
  final String? parentId; // Para la jerarquía

  LocationModel({
    this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  factory LocationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return LocationModel(
      id: snapshot.id,
      name: data?['name'],
      type: data?['type'],
      parentId: data?['parentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "type": type,
      "parentId": parentId,
    };
  }
} 