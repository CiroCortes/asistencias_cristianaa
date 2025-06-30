#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

void main() async {
  print('🧹 Iniciando limpieza de datos de prueba de Quilicura...');
  
  try {
    // Inicializar Firebase usando las credenciales del proyecto
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final firestore = FirebaseFirestore.instance;
    const adminUserId = 'test-admin-quilicura';
    
    // Confirmar eliminación
    print('⚠️  ADVERTENCIA: Esto eliminará TODOS los datos de prueba creados por el script.');
    print('   - Asistentes con nombres TEST');
    print('   - Registros de asistencia de junio y julio 2025');
    print('   - Eventos recurrentes creados por el script');
    print('');
    stdout.write('¿Estás seguro? (escribe "CONFIRMAR" para continuar): ');
    final confirmacion = stdin.readLineSync();
    
    if (confirmacion != 'CONFIRMAR') {
      print('❌ Limpieza cancelada.');
      return;
    }
    
    print('🔍 Buscando datos de prueba...');
    
    // 1. Eliminar asistentes TEST
    print('👥 Eliminando asistentes TEST...');
    final attendeesQuery = await firestore
        .collection('attendees')
        .where('createdByUserId', isEqualTo: adminUserId)
        .get();
    
    int deletedAttendees = 0;
    for (final doc in attendeesQuery.docs) {
      await doc.reference.delete();
      deletedAttendees++;
    }
    print('✅ Eliminados $deletedAttendees asistentes TEST');
    
    // 2. Eliminar registros de asistencia
    print('📊 Eliminando registros de asistencia TEST...');
    final recordsQuery = await firestore
        .collection('attendanceRecords')
        .where('createdByUserId', isEqualTo: adminUserId)
        .get();
    
    int deletedRecords = 0;
    for (final doc in recordsQuery.docs) {
      await doc.reference.delete();
      deletedRecords++;
    }
    print('✅ Eliminados $deletedRecords registros de asistencia');
    
    // 3. Eliminar eventos recurrentes TEST (solo si fueron creados por el script)
    print('📅 Eliminando eventos recurrentes TEST...');
    final eventsQuery = await firestore
        .collection('recurring_meetings')
        .where('createdByUserId', isEqualTo: adminUserId)
        .get();
    
    int deletedEvents = 0;
    for (final doc in eventsQuery.docs) {
      await doc.reference.delete();
      deletedEvents++;
    }
    print('✅ Eliminados $deletedEvents eventos recurrentes TEST');
    
    // 4. Resumen final
    print('\n🎉 ¡LIMPIEZA COMPLETADA!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 ELIMINADOS:');
    print('  👥 Asistentes TEST: $deletedAttendees');
    print('  📊 Registros de asistencia: $deletedRecords');
    print('  📅 Eventos recurrentes: $deletedEvents');
    print('  💰 Costo Firebase: ~\$0.0001 USD (operaciones delete)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Base de datos limpia. Puedes volver a ejecutar generate_test_data.dart');
    
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }
} 