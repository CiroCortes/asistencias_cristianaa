import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';

class AttendeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo asistente (miembro, visita, oyente)
  Future<void> createAttendee(AttendeeModel attendee) async {
    try {
      await _firestore.collection('attendees').add(attendee.toFirestore());
    } catch (e) {
      throw Exception('Error al crear el asistente: $e');
    }
  }

  // Obtener asistentes de un sector específico en tiempo real
  Stream<List<AttendeeModel>> getAttendeesBySectorStream(String sectorId) {
    return _firestore
        .collection('attendees')
        .where('sectorId', isEqualTo: sectorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendeeModel.fromFirestore(doc, null))
          .toList();
    });
  }

  // Obtener todos los asistentes (para administradores) en tiempo real
  Stream<List<AttendeeModel>> getAllAttendeesStream() {
    return _firestore.collection('attendees').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendeeModel.fromFirestore(doc, null))
          .toList();
    });
  }

  // Actualizar un asistente
  Future<void> updateAttendee(AttendeeModel attendee) async {
    try {
      await _firestore.collection('attendees').doc(attendee.id).update(attendee.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar el asistente: $e');
    }
  }
} 