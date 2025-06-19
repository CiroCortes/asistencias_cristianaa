import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringMeetingModel {
  final String? id;
  final String name;
  final List<String> daysOfWeek; // Ej: ['Monday', 'Wednesday', 'Friday']
  final String time; // Ej: "19:00"
  final String locationId; // ID de la localidad
  final String createdByUserId;
  final DateTime createdAt;
  final bool isActive;

  RecurringMeetingModel({
    this.id,
    required this.name,
    required this.daysOfWeek,
    required this.time,
    required this.locationId,
    required this.createdByUserId,
    required this.createdAt,
    this.isActive = true,
  });

  factory RecurringMeetingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return RecurringMeetingModel(
      id: snapshot.id,
      name: data?['name'],
      daysOfWeek: (data?['daysOfWeek'] as List?)?.map((e) => e.toString()).toList() ?? [],
      time: data?['time'],
      locationId: data?['locationId'],
      createdByUserId: data?['createdByUserId'],
      createdAt: (data?['createdAt'] as Timestamp).toDate(),
      isActive: data?['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "daysOfWeek": daysOfWeek,
      "time": time,
      "locationId": locationId,
      "createdByUserId": createdByUserId,
      "createdAt": Timestamp.fromDate(createdAt),
      "isActive": isActive,
    };
  }
} 