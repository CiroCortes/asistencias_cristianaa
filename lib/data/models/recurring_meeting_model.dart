import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringMeetingModel {
  final String? id;
  final String name;
  final List<String> daysOfWeek; // Ej: ['Monday', 'Wednesday', 'Friday']
  final String time; // Ej: "19:00"
  final String?
      locationId; // ID de la localidad (opcional para reuniones generales)
  final String
      meetingType; // Tipo de reunión para KPI (ej: 'culto_miercoles', 'ttl_sabado')
  final String createdByUserId;
  final DateTime createdAt;
  final bool isActive;

  RecurringMeetingModel({
    this.id,
    required this.name,
    required this.daysOfWeek,
    required this.time,
    this.locationId, // Ahora opcional
    required this.meetingType,
    required this.createdByUserId,
    required this.createdAt,
    this.isActive = true,
  });

  factory RecurringMeetingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options) {
    final data = snapshot.data();

    // Verificar que los campos requeridos no sean null
    if (data == null) {
      throw Exception(
          'RecurringMeeting data is null for document ${snapshot.id}');
    }

    final name = data['name'] as String?;
    final time = data['time'] as String?;
    final locationId = data['locationId'] as String?; // Ahora opcional
    final meetingType = data['meetingType'] as String?;
    final createdByUserId = data['createdByUserId'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;

    if (name == null || name.isEmpty) {
      throw Exception(
          'RecurringMeeting name is null or empty for document ${snapshot.id}');
    }
    if (time == null || time.isEmpty) {
      throw Exception(
          'RecurringMeeting time is null or empty for document ${snapshot.id}');
    }
    if (meetingType == null || meetingType.isEmpty) {
      throw Exception(
          'RecurringMeeting meetingType is null or empty for document ${snapshot.id}');
    }
    if (createdByUserId == null || createdByUserId.isEmpty) {
      throw Exception(
          'RecurringMeeting createdByUserId is null or empty for document ${snapshot.id}');
    }
    if (createdAt == null) {
      throw Exception(
          'RecurringMeeting createdAt is null for document ${snapshot.id}');
    }

    return RecurringMeetingModel(
      id: snapshot.id,
      name: name,
      daysOfWeek:
          (data['daysOfWeek'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      time: time,
      locationId: locationId, // Puede ser null
      meetingType: meetingType,
      createdByUserId: createdByUserId,
      createdAt: createdAt.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "daysOfWeek": daysOfWeek,
      "time": time,
      "locationId": locationId, // Puede ser null
      "meetingType": meetingType,
      "createdByUserId": createdByUserId,
      "createdAt": Timestamp.fromDate(createdAt),
      "isActive": isActive,
    };
  }
}
