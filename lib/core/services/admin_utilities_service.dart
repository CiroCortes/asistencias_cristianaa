import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AdminUtilitiesService {
  static const String _adminUserId = 'test-admin-quilicura';
  static const String _quilicuraId = 'QsszuqTZk0QDKHN8iTj6';
  static const String _authorizedEmail = 'ciro.720@gmail.com';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Validar acceso de usuario
  void _validateAccess(String? userEmail) {
    if (userEmail != _authorizedEmail) {
      throw Exception('Acceso denegado: Usuario no autorizado para utilidades de administrador');
    }
  }

  // Función para calcular número de semana
  int _getWeekNumber(DateTime date) {
    DateTime jan4 = DateTime(date.year, 1, 4);
    int yearStartWeekday = jan4.weekday;

    DateTime week1Start;
    if (yearStartWeekday <= DateTime.thursday) {
      week1Start = jan4.subtract(Duration(days: yearStartWeekday - DateTime.monday));
    } else {
      week1Start = jan4.add(Duration(days: DateTime.monday - yearStartWeekday + 7));
    }

    if (date.isBefore(week1Start)) {
      return _getWeekNumber(DateTime(date.year - 1, 12, 31));
    }

    int diffDays = date.difference(week1Start).inDays;
    return (diffDays / 7).floor() + 1;
  }

  // Crear solo asistentes TEST (10 por sector)
  Future<Map<String, int>> createTestAttendees({
    required Function(String) onProgress,
    String? userEmail,
  }) async {
    _validateAccess(userEmail);
    
    try {
      onProgress('🔍 Paso 1: Verificando ruta Quilicura...');
      
      final quilicuraDoc = await _firestore.collection('communes').doc(_quilicuraId).get();
      if (!quilicuraDoc.exists) {
        throw Exception('El documento Quilicura no existe en Firebase');
      }
      
      onProgress('🔍 Paso 2: Buscando sectores de Quilicura...');
      final sectorsQuery = await _firestore
          .collection('locations')
          .where('communeId', isEqualTo: _quilicuraId)
          .get();
      
      final sectors = sectorsQuery.docs;
      if (sectors.isEmpty) {
        throw Exception('No se encontraron sectores en Quilicura');
      }
      
      onProgress('🔍 Paso 3: Verificando asistentes TEST existentes...');
      
      // Verificar si ya existen asistentes TEST
      final existingAttendeesQuery = await _firestore
          .collection('attendees')
          .where('createdByUserId', isEqualTo: _adminUserId)
          .get();
      
      if (existingAttendeesQuery.docs.isNotEmpty) {
        throw Exception('Ya existen ${existingAttendeesQuery.docs.length} asistentes TEST. Use primero "Limpiar Datos" si desea recrearlos.');
      }
      
      onProgress('👥 Paso 4: Creando asistentes TEST...');
      
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
        
        onProgress('👤 Creando asistentes para sector: $sectorName');
        
        for (int i = 1; i <= 10; i++) {
          final nombre = nombres[_random.nextInt(nombres.length)];
          final apellido = apellidos[_random.nextInt(apellidos.length)];
          final tipo = tipos[_random.nextInt(tipos.length)];
          
          final attendee = {
            'name': '$nombre TEST',
            'lastName': '$apellido $i',
            'type': tipo,
            'sectorId': sectorId,
            'contactInfo': '+569${_random.nextInt(90000000) + 10000000}',
            'createdAt': FieldValue.serverTimestamp(),
            'createdByUserId': _adminUserId,
            'isActive': true,
          };
          
          await _firestore.collection('attendees').add(attendee);
          totalAttendees++;
        }
      }
      
      onProgress('✅ Asistentes TEST creados exitosamente');
      
      return {
        'attendees': totalAttendees,
        'sectors': sectors.length,
      };
      
    } catch (e) {
      throw Exception('Error creando asistentes: $e');
    }
  }

  // Crear registros de asistencia para junio-julio 2025 (con validación de 16 semanas)
  Future<Map<String, int>> createAttendanceRecords({
    required Function(String) onProgress,
    String? userEmail,
  }) async {
    _validateAccess(userEmail);
    
    try {
      onProgress('🔍 Paso 1: Verificando asistentes TEST...');
      
      // Verificar que existan asistentes TEST
      final attendeesQuery = await _firestore
          .collection('attendees')
          .where('createdByUserId', isEqualTo: _adminUserId)
          .get();
      
      if (attendeesQuery.docs.isEmpty) {
        throw Exception('No se encontraron asistentes TEST. Debe crear asistentes primero.');
      }
      
      final allAttendees = attendeesQuery.docs;
      onProgress('✅ Encontrados ${allAttendees.length} asistentes TEST');
      
      onProgress('🔍 Paso 2: Verificando registros existentes...');
      
      // Verificar registros existentes para jun-jul 2025
      final existingRecordsQuery = await _firestore
          .collection('attendanceRecords')
          .where('recordedByUserId', isEqualTo: _adminUserId)
          .where('year', isEqualTo: 2025)
          .get();
      
      final existingJunJulRecords = existingRecordsQuery.docs.where((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        return (date.month == 6 || date.month == 7) && date.year == 2025;
      }).length;
      
      if (existingJunJulRecords > 0) {
        throw Exception('Ya existen $existingJunJulRecords registros para jun-jul 2025. Use "Limpiar Datos" si desea recrearlos.');
      }
      
      onProgress('📅 Paso 3: Generando fechas de reuniones...');
      
      // Fechas específicas para las 16 semanas de jun-jul 2025
      final meetingDates = <DateTime>[
        // JUNIO 2025 (4 semanas completas + días extra)
        DateTime(2025, 6, 4, 19, 30), DateTime(2025, 6, 11, 19, 30), DateTime(2025, 6, 18, 19, 30), DateTime(2025, 6, 25, 19, 30), // Miércoles
        DateTime(2025, 6, 7, 10, 0), DateTime(2025, 6, 14, 10, 0), DateTime(2025, 6, 21, 10, 0), DateTime(2025, 6, 28, 10, 0), // Sábados
        DateTime(2025, 6, 1, 10, 0), DateTime(2025, 6, 8, 10, 0), DateTime(2025, 6, 15, 10, 0), DateTime(2025, 6, 22, 10, 0), DateTime(2025, 6, 29, 10, 0), // Domingos AM
        DateTime(2025, 6, 1, 16, 0), DateTime(2025, 6, 8, 16, 0), DateTime(2025, 6, 15, 16, 0), DateTime(2025, 6, 22, 16, 0), DateTime(2025, 6, 29, 16, 0), // Domingos PM
        
        // JULIO 2025 (4 semanas completas + días extra)
        DateTime(2025, 7, 2, 19, 30), DateTime(2025, 7, 9, 19, 30), DateTime(2025, 7, 16, 19, 30), DateTime(2025, 7, 23, 19, 30), DateTime(2025, 7, 30, 19, 30), // Miércoles
        DateTime(2025, 7, 5, 10, 0), DateTime(2025, 7, 12, 10, 0), DateTime(2025, 7, 19, 10, 0), DateTime(2025, 7, 26, 10, 0), // Sábados
        DateTime(2025, 7, 6, 10, 0), DateTime(2025, 7, 13, 10, 0), DateTime(2025, 7, 20, 10, 0), DateTime(2025, 7, 27, 10, 0), // Domingos AM
        DateTime(2025, 7, 6, 16, 0), DateTime(2025, 7, 13, 16, 0), DateTime(2025, 7, 20, 16, 0), DateTime(2025, 7, 27, 16, 0), // Domingos PM
      ];
      
      onProgress('📊 Fechas programadas: ${meetingDates.length} reuniones');
      
      // Obtener sectores para validación
      final sectorsQuery = await _firestore
          .collection('locations')
          .where('communeId', isEqualTo: _quilicuraId)
          .get();
      final sectors = sectorsQuery.docs;
      
      // VALIDACIÓN DE SEGURIDAD: Calcular registros máximos esperados
      final maxExpectedRecords = sectors.length * meetingDates.length * 10; // sectores × fechas × max_asistentes_por_sector
      onProgress('🛡️ Máximo registros esperados: $maxExpectedRecords');
      
      onProgress('📝 Paso 4: Generando registros de asistencia...');
      
      int totalRecords = 0;
      int sectorIndex = 0;
      
      for (final sector in sectors) {
        sectorIndex++;
        final sectorId = sector.id;
        final sectorName = sector.data()['name'] ?? 'Sector';
        final sectorAttendees = allAttendees.where((doc) => doc.data()['sectorId'] == sectorId).toList();
        
        onProgress('📍 Sector $sectorIndex/${sectors.length}: $sectorName (${sectorAttendees.length} asistentes)');
        
        for (final date in meetingDates) {
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
          
          // Simular asistencia realista (60-85%)
          final attendanceRate = 0.6 + (_random.nextDouble() * 0.25);
          final numAttendees = (sectorAttendees.length * attendanceRate).round();
          final shuffledAttendees = List.from(sectorAttendees)..shuffle(_random);
          final attendedIds = shuffledAttendees.take(numAttendees).map((doc) => doc.id).toList();
          final visitorCount = _random.nextInt(6);
          final weekNumber = _getWeekNumber(date);
          
          final attendanceRecord = {
            'sectorId': sectorId,
            'date': Timestamp.fromDate(date),
            'weekNumber': weekNumber,
            'year': date.year,
            'meetingType': meetingType,
            'attendedAttendeeIds': attendedIds,
            'visitorCount': visitorCount,
            'recordedByUserId': _adminUserId,
          };
          
          await _firestore.collection('attendanceRecords').add(attendanceRecord);
          totalRecords++;
          
          // VALIDACIÓN DE SEGURIDAD: No exceder el máximo
          if (totalRecords > maxExpectedRecords) {
            throw Exception('SEGURIDAD: Se excedió el máximo de registros esperados ($maxExpectedRecords). Deteniendo operación.');
          }
        }
      }
      
      onProgress('✅ Registros de asistencia creados exitosamente');
      
      // Validación final
      final expectedRecordsPerSector = meetingDates.length;
      final totalExpectedRecords = sectors.length * expectedRecordsPerSector;
      
      if (totalRecords != totalExpectedRecords) {
        onProgress('⚠️ ADVERTENCIA: Se crearon $totalRecords registros, esperados $totalExpectedRecords');
      }
      
      return {
        'records': totalRecords,
        'sectors': sectors.length,
        'dates': meetingDates.length,
        'expectedRecords': totalExpectedRecords,
      };
      
    } catch (e) {
      throw Exception('Error creando registros: $e');
    }
  }

  // Ejemplo de función para análisis de datos
  Future<Map<String, int>> analyzeData({String? userEmail}) async {
    _validateAccess(userEmail);
    
    final records = await _firestore.collection('attendanceRecords').get();
    final attendees = await _firestore.collection('attendees').get();
    
    return {
      'totalRecords': records.docs.length,
      'totalAttendees': attendees.docs.length,
    };
  }

  // Limpiar datos
  Future<Map<String, int>> cleanupData({
    required String cleanupType,
    required Function(String) onProgress,
    String? userEmail,
  }) async {
    _validateAccess(userEmail);
    
    try {
      int deletedRecords = 0;
      int deletedAttendees = 0;
      int deletedMeetings = 0;
      
      if (cleanupType == 'analyze') {
        return await analyzeData(userEmail: userEmail);
      }
      
      // Limpieza de registros de asistencia
      onProgress('🗑️ Paso 1: Limpiando registros de asistencia...');
      
      if (cleanupType == 'full') {
        final recordsQuery = await _firestore.collection('attendanceRecords').get();
        for (final doc in recordsQuery.docs) {
          await doc.reference.delete();
          deletedRecords++;
        }
      } else {
        final testRecords1 = await _firestore
            .collection('attendanceRecords')
            .where('recordedByUserId', isEqualTo: _adminUserId)
            .get();
        
        final testRecords2 = await _firestore
            .collection('attendanceRecords')
            .where('createdByUserId', isEqualTo: _adminUserId)
            .get();
        
        final allTestRecords = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
        for (final doc in testRecords1.docs) {
          allTestRecords[doc.id] = doc;
        }
        for (final doc in testRecords2.docs) {
          allTestRecords[doc.id] = doc;
        }
        
        for (final doc in allTestRecords.values) {
          await doc.reference.delete();
          deletedRecords++;
        }
      }
      
      onProgress('✅ Eliminados $deletedRecords registros de asistencia');
      
      // Limpieza de asistentes
      onProgress('👥 Paso 2: Limpiando asistentes...');
      
      if (cleanupType == 'full') {
        final allAttendees = await _firestore.collection('attendees').get();
        for (final doc in allAttendees.docs) {
          await doc.reference.delete();
          deletedAttendees++;
        }
      } else {
        final testAttendees = await _firestore
            .collection('attendees')
            .where('createdByUserId', isEqualTo: _adminUserId)
            .get();
        
        for (final doc in testAttendees.docs) {
          await doc.reference.delete();
          deletedAttendees++;
        }
      }
      
      onProgress('✅ Eliminados $deletedAttendees asistentes');
      
      // Limpieza de meetings TEST
      onProgress('📅 Paso 3: Limpiando meetings recurrentes TEST...');
      
      final testMeetings = await _firestore
          .collection('recurring_meetings')
          .where('createdByUserId', isEqualTo: _adminUserId)
          .get();
      
      for (final doc in testMeetings.docs) {
        await doc.reference.delete();
        deletedMeetings++;
      }
      
      onProgress('✅ Eliminados $deletedMeetings meetings TEST');
      onProgress('🎉 Limpieza completada');
      
      return {
        'deletedRecords': deletedRecords,
        'deletedAttendees': deletedAttendees,
        'deletedMeetings': deletedMeetings,
      };
      
    } catch (e) {
      throw Exception('Error durante limpieza: $e');
    }
  }
} 