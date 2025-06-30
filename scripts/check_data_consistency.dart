#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

void main() async {
  print('🔍 Verificando consistencia de datos de Firestore...');
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final firestore = FirebaseFirestore.instance;
    
    // Verificar registros de asistencia
    print('\n📊 ===== REGISTROS DE ASISTENCIA =====');
    final records = await firestore.collection('attendanceRecords').get();
    print('Total registros: ${records.docs.length}');
    
    int validRecords = 0;
    int invalidRecords = 0;
    final Set<String> fieldVariations = {};
    
    for (final doc in records.docs) {
      final data = doc.data();
      
      // Verificar campos requeridos
      final hasRecordedBy = data.containsKey('recordedByUserId');
      final hasCreatedBy = data.containsKey('createdByUserId');
      final hasSectorId = data.containsKey('sectorId');
      final hasDate = data.containsKey('date');
      final hasMeetingType = data.containsKey('meetingType');
      
      // Recopilar variaciones de campos
      for (final key in data.keys) {
        fieldVariations.add(key);
      }
      
      if (hasRecordedBy && hasSectorId && hasDate && hasMeetingType) {
        validRecords++;
      } else {
        invalidRecords++;
        print('❌ Registro inválido: ${doc.id}');
        print('   Campos: ${data.keys.toList()}');
      }
    }
    
    print('✅ Registros válidos: $validRecords');
    print('❌ Registros inválidos: $invalidRecords');
    print('🔧 Campos encontrados: $fieldVariations');
    
    // Verificar asistentes
    print('\n👥 ===== ASISTENTES =====');
    final attendees = await firestore.collection('attendees').get();
    print('Total asistentes: ${attendees.docs.length}');
    
    int testAttendees = 0;
    for (final doc in attendees.docs) {
      final data = doc.data();
      final name = data['name'] ?? '';
      if (name.contains('TEST') || name.contains('test') || 
          data['createdByUserId'] == 'test-admin-quilicura') {
        testAttendees++;
      }
    }
    print('🧪 Asistentes TEST: $testAttendees');
    
    // Verificar meetings
    print('\n📅 ===== MEETINGS RECURRENTES =====');
    final meetings = await firestore.collection('recurring_meetings').get();
    print('Total meetings: ${meetings.docs.length}');
    
    int testMeetings = 0;
    for (final doc in meetings.docs) {
      final data = doc.data();
      if (data['createdByUserId'] == 'test-admin-quilicura') {
        testMeetings++;
      }
    }
    print('🧪 Meetings TEST: $testMeetings');
    
    print('\n🎯 ===== RECOMENDACIONES =====');
    if (invalidRecords > 0) {
      print('⚠️  Hay $invalidRecords registros con estructura inconsistente');
      print('💡 Usa "Limpiar Datos Inconsistentes > Solo TEST" para limpiar');
    }
    if (testAttendees > 0 || testMeetings > 0) {
      print('🧪 Hay datos de prueba que pueden afectar los gráficos');
      print('💡 Usa "Limpiar Datos Inconsistentes > Solo TEST" para limpiar');
    }
    if (invalidRecords == 0 && testAttendees == 0 && testMeetings == 0) {
      print('✅ Los datos están consistentes');
    }
    
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }
} 