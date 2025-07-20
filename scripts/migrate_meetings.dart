import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para migrar reuniones existentes al nuevo formato con meetingType
/// Ejecutar solo una vez para actualizar reuniones existentes
Future<void> migrateMeetings() async {
  final firestore = FirebaseFirestore.instance;

  print('🔄 Iniciando migración de reuniones...');

  try {
    // Obtener todas las reuniones existentes
    final meetingsSnapshot =
        await firestore.collection('recurring_meetings').get();

    print(
        '📊 Encontradas ${meetingsSnapshot.docs.length} reuniones para migrar');

    int migratedCount = 0;

    for (final doc in meetingsSnapshot.docs) {
      final data = doc.data();

      // Verificar si ya tiene meetingType
      if (data.containsKey('meetingType')) {
        print('✅ Reunión ${doc.id} ya tiene meetingType, saltando...');
        continue;
      }

      // Determinar meetingType basado en el nombre o crear uno por defecto
      String meetingType = 'culto_miercoles'; // Por defecto

      final name = data['name'] as String? ?? '';
      final time = data['time'] as String? ?? '';
      final daysOfWeek = data['daysOfWeek'] as List? ?? [];

      // Lógica para determinar el tipo basado en el nombre o días
      if (name.toLowerCase().contains('miércoles') ||
          name.toLowerCase().contains('miercoles') ||
          daysOfWeek.any(
              (day) => day.toString().toLowerCase().contains('miércoles'))) {
        meetingType = 'culto_miercoles';
      } else if (name.toLowerCase().contains('sábado') ||
          name.toLowerCase().contains('sabado') ||
          daysOfWeek
              .any((day) => day.toString().toLowerCase().contains('sábado'))) {
        meetingType = 'ttl_sabado';
      } else if (name.toLowerCase().contains('domingo') &&
          (name.toLowerCase().contains('mañana') ||
              name.toLowerCase().contains('manana') ||
              time.contains('10') ||
              time.contains('11'))) {
        meetingType = 'culto_domingo_manana';
      } else if (name.toLowerCase().contains('domingo') &&
          (name.toLowerCase().contains('tarde') ||
              time.contains('19') ||
              time.contains('20'))) {
        meetingType = 'culto_domingo_tarde';
      }

      // Actualizar el documento
      await firestore.collection('recurring_meetings').doc(doc.id).update({
        'meetingType': meetingType,
      });

      print('✅ Migrada reunión ${doc.id}: "$name" → $meetingType');
      migratedCount++;
    }

    print('🎉 Migración completada: $migratedCount reuniones actualizadas');
  } catch (e) {
    print('❌ Error durante la migración: $e');
  }
}

void main() async {
  await migrateMeetings();
}
