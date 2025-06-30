#!/usr/bin/env dart

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

void main() async {
  print('🚀 Iniciando generación de datos de prueba para Quilicura...');
  
  try {
    // Inicializar Firebase usando las credenciales del proyecto
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final firestore = FirebaseFirestore.instance;
    final random = Random();
    
    // 1. Primero, listar todas las rutas disponibles para debug
    print('🔍 Listando todas las rutas disponibles...');
    final allCommunesQuery = await firestore.collection('communes').get();
    
    print('📋 RUTAS ENCONTRADAS EN FIREBASE:');
    for (final doc in allCommunesQuery.docs) {
      final data = doc.data();
      print('   • ID: ${doc.id} | Nombre: "${data['name']}" | Ciudad: ${data['cityId']}');
    }
    print('');
    
    // 2. Buscar la ruta Quilicura de manera flexible
    print('🔍 Buscando la ruta Quilicura...');
    
    String? quilicuraId;
    String? quilicuraName;
    
              // OPCIÓN 1: Buscar por variaciones del nombre Quilicura
     final searchVariations = [
       'Quilicura',
       'quilicura', 
       'QUILICURA',
       'Quilicura ',
       ' Quilicura',
       'Quilícura',  // Con tilde
     ];
    
         // Buscar por variaciones del nombre Quilicura
     for (final variation in searchVariations) {
                final query = await firestore
             .collection('communes')
             .where('name', isEqualTo: variation)
             .get();
       
       if (query.docs.isNotEmpty) {
         quilicuraId = query.docs.first.id;
         quilicuraName = query.docs.first.data()['name'];
         print('✅ Ruta encontrada con variación "$variation": $quilicuraId');
         break;
       }
     }
    
    // OPCIÓN 3: Buscar que contenga "quilicura" en el nombre
    if (quilicuraId == null) {
      print('🔍 Buscando rutas que contengan "quilicura"...');
      for (final doc in allCommunesQuery.docs) {
        final name = (doc.data()['name'] as String? ?? '').toLowerCase();
        if (name.contains('quilicura')) {
          quilicuraId = doc.id;
          quilicuraName = doc.data()['name'];
          print('✅ Ruta encontrada por contenido: "$quilicuraName" (ID: $quilicuraId)');
          break;
        }
      }
    }
    
    if (quilicuraId == null) {
      print('❌ ERROR: No se encontró ninguna ruta relacionada con Quilicura');
      print('💡 Rutas disponibles arriba ☝️. ¿Podrías verificar el nombre exacto?');
      return;
    }
    
    // 2. Obtener sectores de Quilicura
    print('🔍 Obteniendo sectores de Quilicura...');
    final sectorsQuery = await firestore
        .collection('locations')
        .where('communeId', isEqualTo: quilicuraId)
        .get();
    
    final sectors = sectorsQuery.docs;
    print('✅ Encontrados ${sectors.length} sectores en Quilicura');
    
    if (sectors.isEmpty) {
      print('❌ ERROR: No hay sectores en Quilicura');
      return;
    }
    
    // 3. Usuario admin ficticio para crear datos
    const adminUserId = 'test-admin-quilicura';
    
    // 4. Crear eventos recurrentes básicos si no existen
    print('🔍 Verificando eventos recurrentes...');
    final eventsQuery = await firestore.collection('recurring_meetings').get();
    
    List<Map<String, dynamic>> events = [];
    if (eventsQuery.docs.isEmpty) {
      print('📅 Creando eventos recurrentes básicos...');
      
      final basicEvents = [
        {
          'name': 'Reunión de Miércoles',
          'daysOfWeek': ['Miércoles'],
          'time': '19:30',
          'locationId': sectors.first.id,
          'createdByUserId': adminUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
        {
          'name': 'Predicación Sábado',
          'daysOfWeek': ['Sábado'],
          'time': '10:00',
          'locationId': sectors.first.id,
          'createdByUserId': adminUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
        {
          'name': 'Reunión Domingo AM',
          'daysOfWeek': ['Domingo'],
          'time': '10:00',
          'locationId': sectors.first.id,
          'createdByUserId': adminUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
        {
          'name': 'Reunión Domingo PM',
          'daysOfWeek': ['Domingo'],
          'time': '16:00',
          'locationId': sectors.first.id,
          'createdByUserId': adminUserId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
      ];
      
      for (final event in basicEvents) {
        final docRef = await firestore.collection('recurring_meetings').add(event);
        events.add({...event, 'id': docRef.id});
      }
      print('✅ Creados ${events.length} eventos recurrentes');
    } else {
      // Usar eventos existentes
      events = eventsQuery.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      print('✅ Usando ${events.length} eventos existentes');
    }
    
    // 5. Generar asistentes TEST para cada sector
    print('👥 Generando asistentes TEST...');
    
    final nombres = [
      'Juan', 'María', 'Carlos', 'Ana', 'Pedro', 'Lucia', 'Miguel', 'Carmen',
      'Francisco', 'Elena', 'Antonio', 'Rosa', 'Manuel', 'Isabel', 'José',
      'Patricia', 'Javier', 'Teresa', 'Alejandro', 'Mónica'
    ];
    
    final apellidos = [
      'García', 'Rodríguez', 'González', 'Fernández', 'López', 'Martínez',
      'Sánchez', 'Pérez', 'Gómez', 'Martín', 'Jiménez', 'Ruiz', 'Hernández',
      'Díaz', 'Moreno', 'Muñoz', 'Álvarez', 'Romero', 'Alonso', 'Gutierrez'
    ];
    
    final tipos = ['member', 'listener'];
    int totalAttendees = 0;
    
    for (final sector in sectors) {
      final sectorId = sector.id;
      final sectorName = sector.data()['name'] ?? 'Sector';
      
      print('  📍 Creando asistentes para: $sectorName');
      
      for (int i = 1; i <= 10; i++) {
        final nombre = nombres[random.nextInt(nombres.length)];
        final apellido = apellidos[random.nextInt(apellidos.length)];
        final tipo = tipos[random.nextInt(tipos.length)];
        
        final attendee = {
          'name': '$nombre TEST',
          'lastName': '$apellido $i',
          'type': tipo,
          'sectorId': sectorId,
          'contactInfo': '+569${random.nextInt(90000000) + 10000000}',
          'createdAt': FieldValue.serverTimestamp(),
          'createdByUserId': adminUserId,
          'isActive': true,
        };
        
        await firestore.collection('attendees').add(attendee);
        totalAttendees++;
      }
    }
    
    print('✅ Creados $totalAttendees asistentes TEST');
    
    // 6. Generar registros de asistencia para junio y julio 2025
    print('📊 Generando registros de asistencia para junio y julio 2025...');
    
    // Obtener todos los asistentes recién creados
    final attendeesQuery = await firestore
        .collection('attendees')
        .where('createdByUserId', isEqualTo: adminUserId)
        .get();
    
    final allAttendees = attendeesQuery.docs;
    
    // Generar fechas para junio y julio 2025
    final meetingDates = <DateTime>[];
    
    // ============= JUNIO 2025 =============
    // Miércoles de junio 2025: 4, 11, 18, 25
    meetingDates.addAll([
      DateTime(2025, 6, 4, 19, 30),   // Miércoles 4
      DateTime(2025, 6, 11, 19, 30),  // Miércoles 11
      DateTime(2025, 6, 18, 19, 30),  // Miércoles 18
      DateTime(2025, 6, 25, 19, 30),  // Miércoles 25
    ]);
    
    // Sábados de junio 2025: 7, 14, 21, 28
    meetingDates.addAll([
      DateTime(2025, 6, 7, 10, 0),    // Sábado 7
      DateTime(2025, 6, 14, 10, 0),   // Sábado 14
      DateTime(2025, 6, 21, 10, 0),   // Sábado 21
      DateTime(2025, 6, 28, 10, 0),   // Sábado 28
    ]);
    
    // Domingos AM de junio 2025: 1, 8, 15, 22, 29
    meetingDates.addAll([
      DateTime(2025, 6, 1, 10, 0),    // Domingo 1 AM
      DateTime(2025, 6, 8, 10, 0),    // Domingo 8 AM
      DateTime(2025, 6, 15, 10, 0),   // Domingo 15 AM
      DateTime(2025, 6, 22, 10, 0),   // Domingo 22 AM
      DateTime(2025, 6, 29, 10, 0),   // Domingo 29 AM
    ]);
    
    // Domingos PM de junio 2025: 1, 8, 15, 22, 29
    meetingDates.addAll([
      DateTime(2025, 6, 1, 16, 0),    // Domingo 1 PM
      DateTime(2025, 6, 8, 16, 0),    // Domingo 8 PM
      DateTime(2025, 6, 15, 16, 0),   // Domingo 15 PM
      DateTime(2025, 6, 22, 16, 0),   // Domingo 22 PM
      DateTime(2025, 6, 29, 16, 0),   // Domingo 29 PM
    ]);
    
    // ============= JULIO 2025 =============
    // Miércoles de julio 2025: 2, 9, 16, 23, 30
    meetingDates.addAll([
      DateTime(2025, 7, 2, 19, 30),   // Miércoles 2
      DateTime(2025, 7, 9, 19, 30),   // Miércoles 9
      DateTime(2025, 7, 16, 19, 30),  // Miércoles 16
      DateTime(2025, 7, 23, 19, 30),  // Miércoles 23
      DateTime(2025, 7, 30, 19, 30),  // Miércoles 30
    ]);
    
    // Sábados de julio 2025: 5, 12, 19, 26
    meetingDates.addAll([
      DateTime(2025, 7, 5, 10, 0),    // Sábado 5
      DateTime(2025, 7, 12, 10, 0),   // Sábado 12
      DateTime(2025, 7, 19, 10, 0),   // Sábado 19
      DateTime(2025, 7, 26, 10, 0),   // Sábado 26
    ]);
    
    // Domingos AM de julio 2025: 6, 13, 20, 27
    meetingDates.addAll([
      DateTime(2025, 7, 6, 10, 0),    // Domingo 6 AM
      DateTime(2025, 7, 13, 10, 0),   // Domingo 13 AM
      DateTime(2025, 7, 20, 10, 0),   // Domingo 20 AM
      DateTime(2025, 7, 27, 10, 0),   // Domingo 27 AM
    ]);
    
    // Domingos PM de julio 2025: 6, 13, 20, 27
    meetingDates.addAll([
      DateTime(2025, 7, 6, 16, 0),    // Domingo 6 PM
      DateTime(2025, 7, 13, 16, 0),   // Domingo 13 PM
      DateTime(2025, 7, 20, 16, 0),   // Domingo 20 PM
      DateTime(2025, 7, 27, 16, 0),   // Domingo 27 PM
    ]);
    
    int totalRecords = 0;
    
    for (final sector in sectors) {
      final sectorId = sector.id;
      final sectorName = sector.data()['name'] ?? 'Sector';
      
      // Obtener asistentes de este sector
      final sectorAttendees = allAttendees
          .where((doc) => doc.data()['sectorId'] == sectorId)
          .toList();
      
      print('  📍 Generando asistencias para: $sectorName (${sectorAttendees.length} asistentes)');
      
      for (final date in meetingDates) {
        // Determinar tipo de reunión según día y hora
        String meetingType;
        if (date.weekday == DateTime.wednesday) {
          meetingType = 'Reunión de Miércoles';
        } else if (date.weekday == DateTime.saturday) {
          meetingType = 'Predicación Sábado';
        } else if (date.weekday == DateTime.sunday && date.hour < 14) {
          meetingType = 'Reunión Domingo AM';
        } else {
          meetingType = 'Reunión Domingo PM';
        }
        
        // Simular asistencia realista (60-85% de asistentes)
        final attendanceRate = 0.6 + (random.nextDouble() * 0.25); // 60-85%
        final numAttendees = (sectorAttendees.length * attendanceRate).round();
        
        // Seleccionar asistentes aleatoriamente
        final shuffledAttendees = List.from(sectorAttendees)..shuffle(random);
        final attendedIds = shuffledAttendees
            .take(numAttendees)
            .map((doc) => doc.id)
            .toList();
        
        // Simular visitas (0-5 por reunión)
        final visitorCount = random.nextInt(6);
        
        // Calcular número de semana
        final weekNumber = getWeekNumber(date);
        
        final attendanceRecord = {
          'sectorId': sectorId,
          'date': Timestamp.fromDate(date),
          'weekNumber': weekNumber,
          'year': date.year,
          'meetingType': meetingType,
          'attendedAttendeeIds': attendedIds,
          'visitorCount': visitorCount,
          'recordedByUserId': adminUserId,
        };
        
        await firestore.collection('attendanceRecords').add(attendanceRecord);
        totalRecords++;
      }
    }
    
    print('✅ Creados $totalRecords registros de asistencia para junio y julio 2025');
    
    // 7. Resumen final
    print('\n🎉 ¡GENERACIÓN DE DATOS COMPLETADA!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 RESUMEN:');
    print('  🏙️  Ruta: Quilicura (existente)');
    print('  📍 Sectores: ${sectors.length} (existentes)');
    print('  👥 Asistentes TEST: $totalAttendees');
    print('  📅 Eventos: ${events.length}');
    print('  📊 Registros de asistencia (jun-jul 2025): $totalRecords');
    print('  💰 Costo estimado Firebase: <\$0.001 USD');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Los datos están listos para la demo con el cliente 🎯');
    
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }
}

// Función para calcular número de semana (copiada de date_utils.dart)
int getWeekNumber(DateTime date) {
  DateTime jan4 = DateTime(date.year, 1, 4);
  int yearStartWeekday = jan4.weekday;

  DateTime week1Start;
  if (yearStartWeekday <= DateTime.thursday) {
    week1Start = jan4.subtract(Duration(days: yearStartWeekday - DateTime.monday));
  } else {
    week1Start = jan4.add(Duration(days: DateTime.monday - yearStartWeekday + 7));
  }

  if (date.isBefore(week1Start)) {
    return getWeekNumber(DateTime(date.year - 1, 12, 31));
  }

  int diffDays = date.difference(week1Start).inDays;
  return (diffDays / 7).floor() + 1;
} 