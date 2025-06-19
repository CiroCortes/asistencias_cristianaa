import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/data/models/recurring_meeting_model.dart';

class MeetingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear una nueva plantilla de reunión recurrente
  Future<void> createRecurringMeeting(RecurringMeetingModel meeting) async {
    try {
      await _firestore.collection('recurring_meetings').add(meeting.toFirestore());
    } catch (e) {
      throw Exception('Error al crear la reunión recurrente: $e');
    }
  }

  // Obtener todas las plantillas de reuniones recurrentes en tiempo real
  Stream<List<RecurringMeetingModel>> getRecurringMeetingsStream() {
    return _firestore.collection('recurring_meetings').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RecurringMeetingModel.fromFirestore(doc, null))
          .toList();
    });
  }

  // Actualizar una reunión recurrente
  Future<void> updateRecurringMeeting(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('recurring_meetings').doc(id).update(data);
    } catch (e) {
      throw Exception('Error al actualizar la reunión recurrente: $e');
    }
  }

  // TODO: Añadir métodos para actualizar y eliminar reuniones recurrentes
} 