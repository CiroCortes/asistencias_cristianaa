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
  final String recordedByUserId;

  AttendanceRecordModel({
    this.id,
    required this.sectorId,
    required this.date,
    required this.meetingType,
    required this.attendedAttendeeIds,
    required this.recordedByUserId,
  })  : weekNumber = getWeekNumber(date),
        year = date.year;

  factory AttendanceRecordModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AttendanceRecordModel(
      id: snapshot.id,
      sectorId: data?['sectorId'],
      date: (data?['date'] as Timestamp).toDate(),
      meetingType: data?['meetingType'],
      attendedAttendeeIds: List<String>.from(data?['attendedAttendeeIds'] ?? []),
      recordedByUserId: data?['recordedByUserId'],
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
      "recordedByUserId": recordedByUserId,
    };
  }
} 