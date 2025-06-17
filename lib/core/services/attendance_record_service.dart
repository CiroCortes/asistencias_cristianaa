import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';

class AttendanceRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAttendanceRecord(AttendanceRecordModel record) async {
    try {
      await _firestore.collection('attendanceRecords').add(record.toFirestore());
    } catch (e) {
      throw Exception('Error al registrar la asistencia: $e');
    }
  }

  Stream<List<AttendanceRecordModel>> getAttendanceRecordsStreamBySector(String sectorId) {
    return _firestore
        .collection('attendanceRecords')
        .where('sectorId', isEqualTo: sectorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecordModel.fromFirestore(doc, null))
          .toList();
    });
  }

  // Puedes añadir más métodos aquí según sea necesario, por ejemplo, para
  // obtener registros por tipo de reunión, por fecha, etc.
} 