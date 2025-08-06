import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';

class AttendanceRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAttendanceRecord(AttendanceRecordModel record) async {
    try {
      await _firestore
          .collection('attendanceRecords')
          .add(record.toFirestore());
    } catch (e) {
      throw Exception('Error al registrar la asistencia: $e');
    }
  }

  /// Verifica si ya existen registros para el mismo sector, fecha y tipo de reunión
  /// Retorna los IDs de asistentes ya registrados para evitar duplicados
  Future<List<String>> getExistingAttendeeIds(
      String sectorId, DateTime date, String meetingType) async {
    try {
      // Normalizar la fecha para comparar solo día, mes, año (sin hora)
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final querySnapshot = await _firestore
          .collection('attendanceRecords')
          .where('sectorId', isEqualTo: sectorId)
          .where('meetingType', isEqualTo: meetingType)
          .get();

      final Set<String> existingIds = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final recordDate = (data['date'] as Timestamp).toDate();
        final recordNormalizedDate =
            DateTime(recordDate.year, recordDate.month, recordDate.day);

        // Solo considerar registros del mismo día
        if (recordNormalizedDate.isAtSameMomentAs(normalizedDate)) {
          final attendeeIds =
              List<String>.from(data['attendedAttendeeIds'] ?? []);
          existingIds.addAll(attendeeIds);
        }
      }

      return existingIds.toList();
    } catch (e) {
      print('⚠️ Error al verificar registros existentes: $e');
      return []; // En caso de error, retornar lista vacía para permitir el registro
    }
  }

  Stream<List<AttendanceRecordModel>> getAttendanceRecordsStreamBySector(
      String sectorId) {
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

  Stream<List<AttendanceRecordModel>> getAllAttendanceRecordsStream() {
    return _firestore
        .collection('attendanceRecords')
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
