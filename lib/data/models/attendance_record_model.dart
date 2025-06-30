import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/core/utils/date_utils.dart';

class AttendanceRecordModel {
  final String? id;
  final String sectorId;
  final DateTime date;
  final int weekNumber;
  final int year;
  final String meetingType;
  final List<String> attendedAttendeeIds;
  final int visitorCount;
  final String recordedByUserId;

  AttendanceRecordModel({
    this.id,
    required this.sectorId,
    required this.date,
    required this.meetingType,
    required this.attendedAttendeeIds,
    this.visitorCount = 0,
    required this.recordedByUserId,
  })  : weekNumber = getWeekNumber(date),
        year = date.year;

  factory AttendanceRecordModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    
    // Verificar que los campos requeridos no sean null
    if (data == null) {
      throw Exception('AttendanceRecord data is null for document ${snapshot.id}');
    }
    
    final sectorId = data['sectorId'] as String?;
    final meetingType = data['meetingType'] as String?;
    final recordedByUserId = data['recordedByUserId'] as String?;
    final date = data['date'] as Timestamp?;
    
    if (sectorId == null || sectorId.isEmpty) {
      throw Exception('AttendanceRecord sectorId is null or empty for document ${snapshot.id}');
    }
    if (meetingType == null || meetingType.isEmpty) {
      throw Exception('AttendanceRecord meetingType is null or empty for document ${snapshot.id}');
    }
    if (recordedByUserId == null || recordedByUserId.isEmpty) {
      throw Exception('AttendanceRecord recordedByUserId is null or empty for document ${snapshot.id}');
    }
    if (date == null) {
      throw Exception('AttendanceRecord date is null for document ${snapshot.id}');
    }
    
    return AttendanceRecordModel(
      id: snapshot.id,
      sectorId: sectorId,
      date: date.toDate(),
      meetingType: meetingType,
      attendedAttendeeIds: List<String>.from(data['attendedAttendeeIds'] ?? []),
      visitorCount: data['visitorCount'] ?? 0,
      recordedByUserId: recordedByUserId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "sectorId": sectorId,
      "date": Timestamp.fromDate(date),
      "weekNumber": weekNumber,
      "year": year,
      "meetingType": meetingType,
      "attendedAttendeeIds": attendedAttendeeIds,
      "visitorCount": visitorCount,
      "recordedByUserId": recordedByUserId,
    };
  }
} 