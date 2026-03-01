import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/core/utils/date_utils.dart';
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
      throw Exception(
          'Acceso denegado: Usuario no autorizado para utilidades de administrador');
    }
  }

  // Crear solo asistentes TEST (10 por sector)
  Future<Map<String, int>> createTestAttendees({
    required Function(String) onProgress,
    String? userEmail,
  }) async {
    _validateAccess(userEmail);

    try {
      onProgress('🔍 Paso 1: Verificando ruta Quilicura...');

      final quilicuraDoc =
          await _firestore.collection('communes').doc(_quilicuraId).get();
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
        throw Exception(
            'Ya existen ${existingAttendeesQuery.docs.length} asistentes TEST. Use primero "Limpiar Datos" si desea recrearlos.');
      }

      onProgress('👥 Paso 4: Creando asistentes TEST...');

      final nombres = [
        'Juan',
        'María',
        'Carlos',
        'Ana',
        'Pedro',
        'Lucia',
        'Miguel',
        'Carmen',
        'Francisco',
        'Elena',
        'Antonio',
        'Rosa',
        'Manuel',
        'Isabel',
        'José',
        'Patricia',
        'Javier',
        'Teresa',
        'Alejandro',
        'Mónica'
      ];

      final apellidos = [
        'García',
        'Rodríguez',
        'González',
        'Fernández',
        'López',
        'Martínez',
        'Sánchez',
        'Pérez',
        'Gómez',
        'Martín',
        'Jiménez',
        'Ruiz',
        'Hernández',
        'Díaz',
        'Moreno',
        'Muñoz',
        'Álvarez',
        'Romero',
        'Alonso',
        'Gutierrez'
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
        throw Exception(
            'No se encontraron asistentes TEST. Debe crear asistentes primero.');
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
        throw Exception(
            'Ya existen $existingJunJulRecords registros para jun-jul 2025. Use "Limpiar Datos" si desea recrearlos.');
      }

      onProgress('📅 Paso 3: Generando fechas de reuniones...');

      // Fechas específicas para las 16 semanas de jun-jul 2025
      final meetingDates = <DateTime>[
        // JUNIO 2025 (4 semanas completas + días extra)
        DateTime(2025, 6, 4, 19, 30),
        DateTime(2025, 6, 11, 19, 30),
        DateTime(2025, 6, 18, 19, 30),
        DateTime(2025, 6, 25, 19, 30), // Miércoles
        DateTime(2025, 6, 7, 10, 0), DateTime(2025, 6, 14, 10, 0),
        DateTime(2025, 6, 21, 10, 0), DateTime(2025, 6, 28, 10, 0), // Sábados
        DateTime(2025, 6, 1, 10, 0),
        DateTime(2025, 6, 8, 10, 0),
        DateTime(2025, 6, 15, 10, 0),
        DateTime(2025, 6, 22, 10, 0),
        DateTime(2025, 6, 29, 10, 0), // Domingos AM
        DateTime(2025, 6, 1, 16, 0),
        DateTime(2025, 6, 8, 16, 0),
        DateTime(2025, 6, 15, 16, 0),
        DateTime(2025, 6, 22, 16, 0),
        DateTime(2025, 6, 29, 16, 0), // Domingos PM

        // JULIO 2025 (4 semanas completas + días extra)
        DateTime(2025, 7, 2, 19, 30),
        DateTime(2025, 7, 9, 19, 30),
        DateTime(2025, 7, 16, 19, 30),
        DateTime(2025, 7, 23, 19, 30),
        DateTime(2025, 7, 30, 19, 30), // Miércoles
        DateTime(2025, 7, 5, 10, 0), DateTime(2025, 7, 12, 10, 0),
        DateTime(2025, 7, 19, 10, 0), DateTime(2025, 7, 26, 10, 0), // Sábados
        DateTime(2025, 7, 6, 10, 0),
        DateTime(2025, 7, 13, 10, 0),
        DateTime(2025, 7, 20, 10, 0),
        DateTime(2025, 7, 27, 10, 0), // Domingos AM
        DateTime(2025, 7, 6, 16, 0),
        DateTime(2025, 7, 13, 16, 0),
        DateTime(2025, 7, 20, 16, 0),
        DateTime(2025, 7, 27, 16, 0), // Domingos PM
      ];

      onProgress('📊 Fechas programadas: ${meetingDates.length} reuniones');

      // Obtener sectores para validación
      final sectorsQuery = await _firestore
          .collection('locations')
          .where('communeId', isEqualTo: _quilicuraId)
          .get();
      final sectors = sectorsQuery.docs;

      // VALIDACIÓN DE SEGURIDAD: Calcular registros máximos esperados
      final maxExpectedRecords = sectors.length *
          meetingDates.length *
          10; // sectores × fechas × max_asistentes_por_sector
      onProgress('🛡️ Máximo registros esperados: $maxExpectedRecords');

      onProgress('📝 Paso 4: Generando registros de asistencia...');

      int totalRecords = 0;
      int sectorIndex = 0;

      for (final sector in sectors) {
        sectorIndex++;
        final sectorId = sector.id;
        final sectorName = sector.data()['name'] ?? 'Sector';
        final sectorAttendees = allAttendees
            .where((doc) => doc.data()['sectorId'] == sectorId)
            .toList();

        onProgress(
            '📍 Sector $sectorIndex/${sectors.length}: $sectorName (${sectorAttendees.length} asistentes)');

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
          final numAttendees =
              (sectorAttendees.length * attendanceRate).round();
          final shuffledAttendees = List.from(sectorAttendees)
            ..shuffle(_random);
          final attendedIds = shuffledAttendees
              .take(numAttendees)
              .map((doc) => doc.id)
              .toList();
          final visitorCount = _random.nextInt(6);
          final weekNumber = getWeekNumber(date);

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

          await _firestore
              .collection('attendanceRecords')
              .add(attendanceRecord);
          totalRecords++;

          // VALIDACIÓN DE SEGURIDAD: No exceder el máximo
          if (totalRecords > maxExpectedRecords) {
            throw Exception(
                'SEGURIDAD: Se excedió el máximo de registros esperados ($maxExpectedRecords). Deteniendo operación.');
          }
        }
      }

      onProgress('✅ Registros de asistencia creados exitosamente');

      // Validación final
      final expectedRecordsPerSector = meetingDates.length;
      final totalExpectedRecords = sectors.length * expectedRecordsPerSector;

      if (totalRecords != totalExpectedRecords) {
        onProgress(
            '⚠️ ADVERTENCIA: Se crearon $totalRecords registros, esperados $totalExpectedRecords');
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
        final recordsQuery =
            await _firestore.collection('attendanceRecords').get();
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

        final allTestRecords =
            <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
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

  // 🔍 NUEVA FUNCIÓN: Analizar discrepancias en asistencia semanal
  Future<Map<String, dynamic>> analyzeWeeklyAttendanceDiscrepancies({
    required Function(String) onProgress,
    String? userEmail,
    int? specificWeekNumber,
  }) async {
    _validateAccess(userEmail);

    try {
      onProgress('🔍 Iniciando análisis de discrepancias de asistencia...');

      final now = DateTime.now();
      final targetWeek = specificWeekNumber ?? getWeekNumber(now);
      final currentYear = now.year;

      onProgress('📅 Analizando Semana $targetWeek del año $currentYear');

      // Obtener TODOS los registros de la semana específica
      final allRecordsQuery = await _firestore
          .collection('attendanceRecords')
          .where('weekNumber', isEqualTo: targetWeek)
          .where('year', isEqualTo: currentYear)
          .get();

      final allRecords = allRecordsQuery.docs;
      onProgress('📊 Total registros encontrados: ${allRecords.length}');

      if (allRecords.isEmpty) {
        return {
          'error': 'No se encontraron registros para la semana $targetWeek',
          'totalRecords': 0,
          'correctDayRecords': 0,
          'incorrectDayRecords': 0,
          'discrepancy': 0,
        };
      }

      // Analizar registros por días
      int totalAttendance = 0;
      int correctDayAttendance = 0;

      final correctDayRecords = <Map<String, dynamic>>[];
      final incorrectDayRecords = <Map<String, dynamic>>[];
      final dayBreakdown = <String, int>{
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
        'Saturday': 0,
        'Sunday': 0,
      };
      final hourBreakdown = <int, int>{};

      for (final doc in allRecords) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final attendedCount = (data['attendedAttendeeIds'] as List).length;
        final visitorCount = (data['visitorCount'] as num?)?.toInt() ?? 0;
        final recordTotal = attendedCount + visitorCount;

        totalAttendance += recordTotal;

        // Información del registro
        final recordInfo = {
          'id': doc.id,
          'date': date,
          'weekday': date.weekday,
          'weekdayName': _getWeekdayName(date.weekday),
          'hour': date.hour,
          'minute': date.minute,
          'meetingType': data['meetingType'] ?? 'Sin tipo',
          'attendees': attendedCount,
          'visitors': visitorCount,
          'total': recordTotal,
          'sectorId': data['sectorId'] ?? 'Sin sector',
        };

        // Contar por día de la semana
        final dayName = _getWeekdayName(date.weekday);
        dayBreakdown[dayName] = (dayBreakdown[dayName] ?? 0) + recordTotal;

        // Contar por hora
        hourBreakdown[date.hour] =
            (hourBreakdown[date.hour] ?? 0) + recordTotal;

        // Verificar si es un día "correcto" (miércoles, sábado, domingo)
        final isCorrectDay = date.weekday == DateTime.wednesday ||
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;

        if (isCorrectDay) {
          correctDayAttendance += recordTotal;
          correctDayRecords.add(recordInfo);
        } else {
          incorrectDayRecords.add(recordInfo);
        }
      }

      final discrepancy = totalAttendance - correctDayAttendance;

      // Logging detallado
      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📊 RESUMEN DE ANÁLISIS:');
      onProgress('   🔢 Total asistencia: $totalAttendance personas');
      onProgress('   ✅ Días correctos: $correctDayAttendance personas');
      onProgress('   ❌ Discrepancia: $discrepancy personas');
      onProgress('   📋 Registros totales: ${allRecords.length}');
      onProgress('   ✅ Registros días correctos: ${correctDayRecords.length}');
      onProgress(
          '   ❌ Registros días incorrectos: ${incorrectDayRecords.length}');

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📅 ASISTENCIA POR DÍA DE LA SEMANA:');
      for (final entry in dayBreakdown.entries) {
        if (entry.value > 0) {
          final emoji = entry.key == 'Wednesday'
              ? '✅'
              : entry.key == 'Saturday'
                  ? '✅'
                  : entry.key == 'Sunday'
                      ? '✅'
                      : '❌';
          onProgress('   $emoji ${entry.key}: ${entry.value} personas');
        }
      }

      if (hourBreakdown.isNotEmpty) {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('🕐 ASISTENCIA POR HORA:');
        final sortedHours = hourBreakdown.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (final entry in sortedHours) {
          onProgress(
              '   ${entry.key.toString().padLeft(2, '0')}:00 → ${entry.value} personas');
        }
      }

      if (incorrectDayRecords.isNotEmpty) {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('❌ REGISTROS EN DÍAS INCORRECTOS:');
        for (final record in incorrectDayRecords) {
          final date = record['date'] as DateTime;
          onProgress(
              '   🗓️ ${date.day}/${date.month}/${date.year} ${record['weekdayName']} ${date.hour}:${date.minute.toString().padLeft(2, '0')}');
          onProgress('      📍 Sector: ${record['sectorId']}');
          onProgress(
              '      👥 ${record['attendees']} asistentes + ${record['visitors']} visitas = ${record['total']} total');
          onProgress('      📝 Tipo: ${record['meetingType']}');
        }
      }

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('🎯 CONCLUSIÓN:');
      if (discrepancy == 0) {
        onProgress(
            '   ✅ No hay discrepancias. Todos los registros están en días correctos.');
      } else {
        onProgress(
            '   ⚠️ Se encontraron $discrepancy personas en días incorrectos.');
        onProgress(
            '   💡 Estos registros deberían estar en miércoles, sábado o domingo.');
      }

      return {
        'weekNumber': targetWeek,
        'year': currentYear,
        'totalRecords': allRecords.length,
        'totalAttendance': totalAttendance,
        'correctDayAttendance': correctDayAttendance,
        'discrepancy': discrepancy,
        'correctDayRecords': correctDayRecords.length,
        'incorrectDayRecords': incorrectDayRecords.length,
        'dayBreakdown': dayBreakdown,
        'hourBreakdown': hourBreakdown,
        'incorrectRecordsDetails': incorrectDayRecords,
      };
    } catch (e) {
      throw Exception('Error analizando discrepancias: $e');
    }
  }

  // Función auxiliar para obtener nombre del día de la semana
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // 🧹 NUEVA FUNCIÓN: Limpiar registros en días incorrectos
  Future<Map<String, dynamic>> cleanupIncorrectDayRecords({
    required Function(String) onProgress,
    String? userEmail,
    int? specificWeekNumber,
    bool dryRun = true, // Por defecto solo simula, no elimina
  }) async {
    _validateAccess(userEmail);

    try {
      onProgress('🧹 Iniciando limpieza de registros en días incorrectos...');
      onProgress(
          '${dryRun ? '🔍 MODO SIMULACIÓN' : '⚠️ MODO ELIMINACIÓN REAL'}');

      final now = DateTime.now();
      final targetWeek = specificWeekNumber ?? getWeekNumber(now);
      final currentYear = now.year;

      onProgress('📅 Analizando Semana $targetWeek del año $currentYear');

      // Obtener TODOS los registros de la semana específica
      final allRecordsQuery = await _firestore
          .collection('attendanceRecords')
          .where('weekNumber', isEqualTo: targetWeek)
          .where('year', isEqualTo: currentYear)
          .get();

      final allRecords = allRecordsQuery.docs;
      onProgress('📊 Total registros encontrados: ${allRecords.length}');

      if (allRecords.isEmpty) {
        return {
          'error': 'No se encontraron registros para la semana $targetWeek',
          'totalRecords': 0,
          'incorrectDayRecords': 0,
          'deletedRecords': 0,
          'deletedAttendance': 0,
        };
      }

      // Identificar registros en días incorrectos
      final incorrectDayRecords = <DocumentSnapshot>[];
      int totalIncorrectAttendance = 0;

      for (final doc in allRecords) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final attendedCount = (data['attendedAttendeeIds'] as List).length;
        final visitorCount = (data['visitorCount'] as num?)?.toInt() ?? 0;
        final recordTotal = attendedCount + visitorCount;

        // Verificar si es un día "incorrecto" (lunes, martes, jueves, viernes)
        final isIncorrectDay = date.weekday == DateTime.monday ||
            date.weekday == DateTime.tuesday ||
            date.weekday == DateTime.thursday ||
            date.weekday == DateTime.friday;

        if (isIncorrectDay) {
          incorrectDayRecords.add(doc);
          totalIncorrectAttendance += recordTotal;
        }
      }

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('❌ REGISTROS EN DÍAS INCORRECTOS ENCONTRADOS:');
      onProgress('   📋 Total registros: ${incorrectDayRecords.length}');
      onProgress('   👥 Total asistencia: $totalIncorrectAttendance personas');

      if (incorrectDayRecords.isNotEmpty) {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('📝 DETALLES DE REGISTROS A ELIMINAR:');

        for (final doc in incorrectDayRecords) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final date = (data['date'] as Timestamp).toDate();
          final attendedCount = (data['attendedAttendeeIds'] as List).length;
          final visitorCount = (data['visitorCount'] as num?)?.toInt() ?? 0;
          final recordTotal = attendedCount + visitorCount;
          final meetingType = data['meetingType'] ?? 'Sin tipo';
          final sectorId = data['sectorId'] ?? 'Sin sector';

          onProgress(
              '   🗓️ ${date.day}/${date.month}/${date.year} ${_getWeekdayName(date.weekday)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}');
          onProgress('      📍 Sector: $sectorId');
          onProgress(
              '      👥 $attendedCount asistentes + $visitorCount visitas = $recordTotal total');
          onProgress('      📝 Tipo: $meetingType');
          onProgress('      🆔 ID: ${doc.id}');
        }

        if (!dryRun) {
          onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          onProgress('⚠️ ELIMINANDO REGISTROS...');

          int deletedCount = 0;
          for (final doc in incorrectDayRecords) {
            try {
              await doc.reference.delete();
              deletedCount++;
              onProgress('   ✅ Eliminado: ${doc.id}');
            } catch (e) {
              onProgress('   ❌ Error eliminando ${doc.id}: $e');
            }
          }

          onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          onProgress('🎉 LIMPIEZA COMPLETADA:');
          onProgress('   ✅ Registros eliminados: $deletedCount');
          onProgress(
              '   👥 Asistencia eliminada: $totalIncorrectAttendance personas');

          return {
            'weekNumber': targetWeek,
            'year': currentYear,
            'totalRecords': allRecords.length,
            'incorrectDayRecords': incorrectDayRecords.length,
            'deletedRecords': deletedCount,
            'deletedAttendance': totalIncorrectAttendance,
            'dryRun': false,
          };
        } else {
          onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          onProgress('🔍 SIMULACIÓN COMPLETADA:');
          onProgress(
              '   📋 Registros que se eliminarían: ${incorrectDayRecords.length}');
          onProgress(
              '   👥 Asistencia que se eliminaría: $totalIncorrectAttendance personas');
          onProgress('   💡 Ejecuta sin dryRun=true para eliminar realmente');

          return {
            'weekNumber': targetWeek,
            'year': currentYear,
            'totalRecords': allRecords.length,
            'incorrectDayRecords': incorrectDayRecords.length,
            'deletedRecords': 0,
            'deletedAttendance': totalIncorrectAttendance,
            'dryRun': true,
          };
        }
      } else {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('✅ No se encontraron registros en días incorrectos');
        onProgress(
            '   Todos los registros están en días válidos (miércoles, sábado, domingo)');

        return {
          'weekNumber': targetWeek,
          'year': currentYear,
          'totalRecords': allRecords.length,
          'incorrectDayRecords': 0,
          'deletedRecords': 0,
          'deletedAttendance': 0,
          'dryRun': dryRun,
        };
      }
    } catch (e) {
      throw Exception('Error durante limpieza de registros incorrectos: $e');
    }
  }

  /// Elimina asistentes de forma segura, verificando que no estén referenciados en registros de asistencia
  Future<Map<String, int>> deleteAttendeesSafely({
    required Function(String) onProgress,
    String? userEmail,
    List<String>?
        attendeeIds, // IDs específicos a eliminar, si es null elimina todos los TEST
    bool dryRun = true, // Si es true, solo simula la eliminación
  }) async {
    _validateAccess(userEmail);

    try {
      onProgress('🔍 Paso 1: Verificando asistentes a eliminar...');

      List<String> attendeesToDelete = [];

      if (attendeeIds != null && attendeeIds.isNotEmpty) {
        // Eliminar IDs específicos
        attendeesToDelete = attendeeIds;
        onProgress(
            '📋 Eliminación específica: ${attendeeIds.length} asistentes');
      } else {
        // Eliminar todos los asistentes TEST
        final testAttendeesQuery = await _firestore
            .collection('attendees')
            .where('createdByUserId', isEqualTo: _adminUserId)
            .get();

        attendeesToDelete =
            testAttendeesQuery.docs.map((doc) => doc.id).toList();
        onProgress(
            '📋 Eliminación TEST: ${attendeesToDelete.length} asistentes encontrados');
      }

      if (attendeesToDelete.isEmpty) {
        return {
          'totalAttendees': 0,
          'referencedAttendees': 0,
          'safeToDelete': 0,
          'deletedAttendees': 0,
          'dryRun': dryRun ? 1 : 0,
        };
      }

      onProgress(
          '🔍 Paso 2: Verificando referencias en registros de asistencia...');

      // Buscar todos los registros de asistencia que referencian estos asistentes
      final allRecordsQuery =
          await _firestore.collection('attendanceRecords').get();
      final allRecords = allRecordsQuery.docs;

      final Set<String> referencedAttendeeIds = {};
      final Map<String, List<String>> attendeeReferences =
          {}; // attendeeId -> [recordIds]

      for (final recordDoc in allRecords) {
        final data = recordDoc.data();
        final attendedIds =
            List<String>.from(data['attendedAttendeeIds'] ?? []);

        for (final attendeeId in attendedIds) {
          if (attendeesToDelete.contains(attendeeId)) {
            referencedAttendeeIds.add(attendeeId);

            if (!attendeeReferences.containsKey(attendeeId)) {
              attendeeReferences[attendeeId] = [];
            }
            attendeeReferences[attendeeId]!.add(recordDoc.id);
          }
        }
      }

      final safeToDelete = attendeesToDelete
          .where((id) => !referencedAttendeeIds.contains(id))
          .toList();
      final referencedCount = referencedAttendeeIds.length;

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📊 ANÁLISIS DE SEGURIDAD:');
      onProgress(
          '   📋 Total asistentes a eliminar: ${attendeesToDelete.length}');
      onProgress('   🔗 Referenciados en registros: $referencedCount');
      onProgress('   ✅ Seguros para eliminar: ${safeToDelete.length}');
      onProgress('   ❌ No se pueden eliminar: $referencedCount');

      if (referencedCount > 0) {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('⚠️ ASISTENTES REFERENCIADOS (NO SE PUEDEN ELIMINAR):');

        for (final attendeeId in referencedAttendeeIds) {
          final recordIds = attendeeReferences[attendeeId] ?? [];
          onProgress('   👤 ID: $attendeeId');
          onProgress(
              '      📝 Referenciado en ${recordIds.length} registros: ${recordIds.join(', ')}');
        }
      }

      if (safeToDelete.isNotEmpty) {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('✅ ASISTENTES SEGUROS PARA ELIMINAR:');

        for (final attendeeId in safeToDelete) {
          onProgress('   👤 ID: $attendeeId');
        }

        if (!dryRun) {
          onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          onProgress('🗑️ ELIMINANDO ASISTENTES...');

          int deletedCount = 0;
          for (final attendeeId in safeToDelete) {
            try {
              await _firestore.collection('attendees').doc(attendeeId).delete();
              deletedCount++;
              onProgress('   ✅ Eliminado: $attendeeId');
            } catch (e) {
              onProgress('   ❌ Error eliminando $attendeeId: $e');
            }
          }

          onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          onProgress('🎉 ELIMINACIÓN COMPLETADA:');
          onProgress('   ✅ Asistentes eliminados: $deletedCount');
          onProgress('   🔗 Referenciados (no eliminados): $referencedCount');

          return {
            'totalAttendees': attendeesToDelete.length,
            'referencedAttendees': referencedCount,
            'safeToDelete': safeToDelete.length,
            'deletedAttendees': deletedCount,
            'dryRun': 0,
          };
        } else {
          onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          onProgress('🔍 SIMULACIÓN COMPLETADA:');
          onProgress(
              '   📋 Asistentes que se eliminarían: ${safeToDelete.length}');
          onProgress(
              '   🔗 Referenciados (no se eliminarían): $referencedCount');
          onProgress('   💡 Ejecuta sin dryRun=true para eliminar realmente');

          return {
            'totalAttendees': attendeesToDelete.length,
            'referencedAttendees': referencedCount,
            'safeToDelete': safeToDelete.length,
            'deletedAttendees': 0,
            'dryRun': 1,
          };
        }
      } else {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('⚠️ NO HAY ASISTENTES SEGUROS PARA ELIMINAR');
        onProgress(
            '   Todos los asistentes están referenciados en registros de asistencia');
        onProgress(
            '   💡 Primero elimina los registros de asistencia que los referencian');

        return {
          'totalAttendees': attendeesToDelete.length,
          'referencedAttendees': referencedCount,
          'safeToDelete': 0,
          'deletedAttendees': 0,
          'dryRun': dryRun ? 1 : 0,
        };
      }
    } catch (e) {
      throw Exception('Error durante eliminación segura de asistentes: $e');
    }
  }

  /// Elimina registros de asistencia específicos de forma segura
  Future<Map<String, int>> deleteAttendanceRecordsSafely({
    required Function(String) onProgress,
    String? userEmail,
    DateTime? specificDate, // Fecha específica a eliminar
    String? sectorId, // Sector específico (si es null, todos los sectores)
    String?
        meetingType, // Tipo de reunión específico (si es null, todos los tipos)
    bool dryRun = true, // Si es true, solo simula la eliminación
  }) async {
    _validateAccess(userEmail);

    try {
      onProgress('🔍 Paso 1: Buscando registros de asistencia...');

      // Construir query base
      Query query = _firestore.collection('attendanceRecords');

      // Aplicar filtros si se especifican
      if (sectorId != null) {
        query = query.where('sectorId', isEqualTo: sectorId);
        onProgress('📍 Filtro: Sector $sectorId');
      }

      if (meetingType != null) {
        query = query.where('meetingType', isEqualTo: meetingType);
        onProgress('📅 Filtro: Tipo de reunión $meetingType');
      }

      final querySnapshot = await query.get();
      final allRecords = querySnapshot.docs;

      onProgress('📋 Total registros encontrados: ${allRecords.length}');

      // Filtrar por fecha si se especifica
      List<QueryDocumentSnapshot> recordsToDelete = [];
      if (specificDate != null) {
        final targetDate =
            DateTime(specificDate.year, specificDate.month, specificDate.day);

        for (final doc in allRecords) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final recordDate = (data['date'] as Timestamp).toDate();
          final recordNormalizedDate =
              DateTime(recordDate.year, recordDate.month, recordDate.day);

          if (recordNormalizedDate.isAtSameMomentAs(targetDate)) {
            recordsToDelete.add(doc);
          }
        }

        onProgress(
            '📅 Filtro: Fecha ${targetDate.day}/${targetDate.month}/${targetDate.year}');
      } else {
        recordsToDelete = allRecords;
      }

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📊 ANÁLISIS DE REGISTROS:');
      onProgress('   📋 Total registros a eliminar: ${recordsToDelete.length}');

      if (recordsToDelete.isEmpty) {
        onProgress(
            'ℹ️ No se encontraron registros que coincidan con los criterios');
        return {
          'totalRecords': 0,
          'deletedRecords': 0,
          'deletedAttendance': 0,
          'dryRun': dryRun ? 1 : 0,
        };
      }

      // Analizar registros a eliminar
      int totalAttendance = 0;
      final Map<String, int> sectorBreakdown = {};
      final Map<String, int> meetingTypeBreakdown = {};

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📝 DETALLES DE REGISTROS A ELIMINAR:');

      for (final doc in recordsToDelete) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final date = (data['date'] as Timestamp).toDate();
        final attendedCount = (data['attendedAttendeeIds'] as List).length;
        final visitorCount = (data['visitorCount'] as num?)?.toInt() ?? 0;
        final recordTotal = attendedCount + visitorCount;
        final recordSectorId = data['sectorId'] ?? 'Sin sector';
        final recordMeetingType = data['meetingType'] ?? 'Sin tipo';

        totalAttendance += recordTotal;

        // Contar por sector
        sectorBreakdown[recordSectorId] =
            (sectorBreakdown[recordSectorId] ?? 0) + recordTotal;

        // Contar por tipo de reunión
        meetingTypeBreakdown[recordMeetingType] =
            (meetingTypeBreakdown[recordMeetingType] ?? 0) + recordTotal;

        onProgress(
            '   🗓️ ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}');
        onProgress('      📍 Sector: $recordSectorId');
        onProgress('      📝 Tipo: $recordMeetingType');
        onProgress(
            '      👥 $attendedCount asistentes + $visitorCount visitas = $recordTotal total');
        onProgress('      🆔 ID: ${doc.id}');
      }

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📊 RESUMEN POR SECTOR:');
      for (final entry in sectorBreakdown.entries) {
        onProgress('   📍 ${entry.key}: ${entry.value} personas');
      }

      onProgress('📊 RESUMEN POR TIPO DE REUNIÓN:');
      for (final entry in meetingTypeBreakdown.entries) {
        onProgress('   📝 ${entry.key}: ${entry.value} personas');
      }

      onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      onProgress('📊 RESUMEN FINAL:');
      onProgress('   📋 Registros a eliminar: ${recordsToDelete.length}');
      onProgress(
          '   👥 Total asistencia a eliminar: $totalAttendance personas');

      if (!dryRun) {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('🗑️ ELIMINANDO REGISTROS...');

        int deletedCount = 0;
        for (final doc in recordsToDelete) {
          try {
            await doc.reference.delete();
            deletedCount++;
            onProgress('   ✅ Eliminado: ${doc.id}');
          } catch (e) {
            onProgress('   ❌ Error eliminando ${doc.id}: $e');
          }
        }

        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('🎉 ELIMINACIÓN COMPLETADA:');
        onProgress('   ✅ Registros eliminados: $deletedCount');
        onProgress('   👥 Asistencia eliminada: $totalAttendance personas');

        return {
          'totalRecords': recordsToDelete.length,
          'deletedRecords': deletedCount,
          'deletedAttendance': totalAttendance,
          'dryRun': 0,
        };
      } else {
        onProgress('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        onProgress('🔍 SIMULACIÓN COMPLETADA:');
        onProgress(
            '   📋 Registros que se eliminarían: ${recordsToDelete.length}');
        onProgress(
            '   👥 Asistencia que se eliminaría: $totalAttendance personas');
        onProgress('   💡 Ejecuta sin dryRun=true para eliminar realmente');

        return {
          'totalRecords': recordsToDelete.length,
          'deletedRecords': 0,
          'deletedAttendance': totalAttendance,
          'dryRun': 1,
        };
      }
    } catch (e) {
      throw Exception(
          'Error durante eliminación de registros de asistencia: $e');
    }
  }
}
