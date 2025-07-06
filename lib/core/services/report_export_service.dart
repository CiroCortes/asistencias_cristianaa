import 'dart:io';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:excel/excel.dart';

class ReportExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera y exporta un reporte en formato Excel (.xlsx) según los filtros especificados
  Future<String> generateAndExportReport({
    required String reportType,
    String? cityId,
    String? communeId,
    DateTimeRange? dateRange,
  }) async {
    try {
      // Obtener datos filtrados
      final data = await _getFilteredData(
        reportType: reportType,
        cityId: cityId,
        communeId: communeId,
        dateRange: dateRange,
      );

      // Generar archivo Excel
      final filePath = await _generateExcelReport(data, reportType);

      // Solicitar permisos y guardar archivo
      await _requestPermissions();
      final savedPath = await _saveFile(filePath, reportType);
      
      // Compartir archivo
      await _shareFile(savedPath);
      
      return savedPath;
    } catch (e) {
      throw Exception('Error al generar reporte: $e');
    }
  }

  /// Obtiene datos filtrados de Firestore
  Future<Map<String, dynamic>> _getFilteredData({
    required String reportType,
    String? cityId,
    String? communeId,
    DateTimeRange? dateRange,
  }) async {
    // Obtener ubicaciones filtradas
    List<Location> locations = await _getFilteredLocations(cityId, communeId);
    List<String> sectorIds = locations.map((l) => l.id).toList();

    // Obtener registros de asistencia filtrados
    Query query = _firestore.collection('attendanceRecords');
    
    if (sectorIds.isNotEmpty) {
      query = query.where('sectorId', whereIn: sectorIds);
    }
    
    if (dateRange != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
                   .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
    }

    final attendanceSnapshot = await query.get();
    final attendanceRecords = attendanceSnapshot.docs
        .map((doc) => AttendanceRecordModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null))
        .toList();

    // Obtener asistentes
    final attendeesSnapshot = await _firestore.collection('attendees').get();
    final attendees = attendeesSnapshot.docs
        .map((doc) => AttendeeModel.fromFirestore(doc, null))
        .toList();

    // Obtener información de ubicaciones
    final locationMap = <String, Location>{};
    for (var location in locations) {
      locationMap[location.id] = location;
    }

    return {
      'attendanceRecords': attendanceRecords,
      'attendees': attendees,
      'locations': locationMap,
      'reportType': reportType,
    };
  }

  /// Obtiene ubicaciones filtradas
  Future<List<Location>> _getFilteredLocations(String? cityId, String? communeId) async {
    List<Location> allLocations = [];

    if (communeId != null) {
      // Filtrar por comuna específica
      final locationSnapshot = await _firestore
          .collection('locations')
          .where('communeId', isEqualTo: communeId)
          .get();
      
      allLocations = locationSnapshot.docs
          .map((doc) => Location.fromFirestore(doc))
          .toList();
    } else if (cityId != null) {
      // Filtrar por ciudad
      final communeSnapshot = await _firestore
          .collection('communes')
          .where('cityId', isEqualTo: cityId)
          .get();
      
      final communeIds = communeSnapshot.docs.map((doc) => doc.id).toList();
      
      if (communeIds.isNotEmpty) {
        final locationSnapshot = await _firestore
            .collection('locations')
            .where('communeId', whereIn: communeIds)
            .get();
        
        allLocations = locationSnapshot.docs
            .map((doc) => Location.fromFirestore(doc))
            .toList();
      }
    } else {
      // Obtener todas las ubicaciones
      final locationSnapshot = await _firestore.collection('locations').get();
      allLocations = locationSnapshot.docs
          .map((doc) => Location.fromFirestore(doc))
          .toList();
    }

    return allLocations;
  }

  /// Genera reporte en formato Excel (.xlsx)
  Future<String> _generateExcelReport(Map<String, dynamic> data, String reportType) async {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte'];

    // Configurar encabezados según el tipo de reporte
    List<List<String>> headers = _getHeadersForReportType(reportType);
    
    // Escribir encabezados
    for (int i = 0; i < headers[0].length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[0][i];
    }

    // Generar datos según el tipo de reporte
    List<List<String>> rows = await _generateDataRows(data, reportType);
    
    // Escribir datos
    for (int i = 0; i < rows.length; i++) {
      for (int j = 0; j < rows[i].length; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            ..value = rows[i][j];
      }
    }

    // Guardar archivo temporal
    final tempDir = await pp.getTemporaryDirectory();
    final fileName = 'reporte_${reportType}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    
    return filePath;
  }

  /// Obtiene encabezados según el tipo de reporte
  List<List<String>> _getHeadersForReportType(String reportType) {
    switch (reportType) {
      case 'asistencia_general':
        // Reporte detallado por asistente
        return [[
          'Fecha',
          'Sector',
          'Tipo de Reunión',
          'Nombre',
          'Apellido',
          'Tipo de Miembro',
          'Contacto',
        ]];
      case 'asistencia_sectores':
        return [['Sector', 'Ciudad', 'Comuna', 'Total Asistentes', 'Promedio Semanal', 'Última Reunión']];
      case 'ttl_semanal':
        return [['Semana', 'Año', 'Total Asistentes', 'Promedio Diario', 'Sectores Activos']];
      case 'visitas':
        return [['Fecha', 'Sector', 'Nombre Visitante', 'Tipo', 'Contacto']];
      default:
        return [['Datos']];
    }
  }

  /// Genera filas de datos según el tipo de reporte
  Future<List<List<String>>> _generateDataRows(Map<String, dynamic> data, String reportType) async {
    final attendanceRecords = data['attendanceRecords'] as List<AttendanceRecordModel>;
    final attendees = data['attendees'] as List<AttendeeModel>;
    final locations = data['locations'] as Map<String, Location>;

    switch (reportType) {
      case 'asistencia_general':
        return _generateDetailedAttendanceRows(attendanceRecords, attendees, locations);
      case 'asistencia_sectores':
        return _generateSectorAttendanceRows(attendanceRecords, attendees, locations);
      case 'ttl_semanal':
        return _generateWeeklyTTLRows(attendanceRecords);
      case 'visitas':
        return _generateVisitorsRows(attendanceRecords, attendees, locations);
      default:
        return [['No hay datos disponibles']];
    }
  }

  /// Genera filas detalladas para reporte de asistencia general
  List<List<String>> _generateDetailedAttendanceRows(
    List<AttendanceRecordModel> records,
    List<AttendeeModel> attendees,
    Map<String, Location> locations,
  ) {
    List<List<String>> rows = [];
    final attendeeMap = {for (var a in attendees) a.id: a};

    for (var record in records) {
      final location = locations[record.sectorId];
      // Para cada asistente registrado
      for (var attendeeId in record.attendedAttendeeIds) {
        final attendee = attendeeMap[attendeeId];
        rows.add([
          DateFormat('dd/MM/yyyy').format(record.date),
          location?.name ?? 'Sector no encontrado',
          record.meetingType,
          attendee?.name ?? '',
          attendee?.lastName ?? '',
          attendee?.type ?? '',
          attendee?.contactInfo ?? '',
        ]);
      }
      // Para las visitas (si solo hay número, no nombre)
      if (record.visitorCount > 0) {
        for (int i = 1; i <= record.visitorCount; i++) {
          rows.add([
            DateFormat('dd/MM/yyyy').format(record.date),
            location?.name ?? 'Sector no encontrado',
            record.meetingType,
            'Visita $i',
            '',
            'visitante',
            '',
          ]);
        }
      }
    }
    return rows;
  }

  /// Genera filas para reporte de asistencia por sectores
  List<List<String>> _generateSectorAttendanceRows(
    List<AttendanceRecordModel> records,
    List<AttendeeModel> attendees,
    Map<String, Location> locations,
  ) {
    Map<String, List<AttendanceRecordModel>> sectorRecords = {};
    
    // Agrupar registros por sector
    for (var record in records) {
      sectorRecords.putIfAbsent(record.sectorId, () => []).add(record);
    }
    
    List<List<String>> rows = [];
    
    for (var entry in sectorRecords.entries) {
      final location = locations[entry.key];
      final sectorRecords = entry.value;
      final totalAttendees = sectorRecords.fold<int>(0, (sum, record) => sum + record.attendedAttendeeIds.length);
      final averageWeekly = sectorRecords.isNotEmpty ? (totalAttendees / sectorRecords.length).toStringAsFixed(1) : '0';
      final lastMeeting = sectorRecords.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').format(sectorRecords.last.date)
          : 'N/A';
      
      rows.add([
        location?.name ?? 'Sector no encontrado',
        'Ciudad', // TODO: Obtener nombre de ciudad
        'Comuna', // TODO: Obtener nombre de comuna
        totalAttendees.toString(),
        averageWeekly,
        lastMeeting,
      ]);
    }
    
    return rows;
  }

  /// Genera filas para reporte TTL semanal
  List<List<String>> _generateWeeklyTTLRows(List<AttendanceRecordModel> records) {
    Map<String, List<AttendanceRecordModel>> weeklyRecords = {};
    
    // Agrupar registros por semana
    for (var record in records) {
      final weekKey = '${record.year}-W${record.weekNumber.toString().padLeft(2, '0')}';
      weeklyRecords.putIfAbsent(weekKey, () => []).add(record);
    }
    
    List<List<String>> rows = [];
    
    for (var entry in weeklyRecords.entries) {
      final weekRecords = entry.value;
      final totalAttendees = weekRecords.fold<int>(0, (sum, record) => sum + record.attendedAttendeeIds.length);
      final averageDaily = weekRecords.isNotEmpty ? (totalAttendees / weekRecords.length).toStringAsFixed(1) : '0';
      final activeSectors = weekRecords.map((r) => r.sectorId).toSet().length;
      
      final weekParts = entry.key.split('-W');
      final year = weekParts[0];
      final week = weekParts[1];
      
      rows.add([
        week,
        year,
        totalAttendees.toString(),
        averageDaily,
        activeSectors.toString(),
      ]);
    }
    
    return rows;
  }

  /// Genera filas para reporte de visitas
  List<List<String>> _generateVisitorsRows(
    List<AttendanceRecordModel> records,
    List<AttendeeModel> attendees,
    Map<String, Location> locations,
  ) {
    List<List<String>> rows = [];
    
    // Obtener asistentes que son visitantes
    final visitorAttendees = attendees.where((a) => a.type == 'visitor').toList();
    final visitorMap = <String, AttendeeModel>{};
    for (var attendee in visitorAttendees) {
      visitorMap[attendee.id!] = attendee;
    }
    
    for (var record in records) {
      if (record.visitorCount > 0) {
        final location = locations[record.sectorId];
        
        rows.add([
          DateFormat('dd/MM/yyyy').format(record.date),
          location?.name ?? 'Sector no encontrado',
          '${record.visitorCount} visitante(s)',
          'Visita',
          'N/A',
        ]);
      }
    }
    
    return rows;
  }

  /// Solicita permisos necesarios
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  /// Guarda el archivo en la carpeta pública de descargas (Downloads) en Android
  Future<String> _saveFile(String tempPath, String reportType) async {
    String filePath;
    final fileName = 'reporte_${reportType}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    if (Platform.isAndroid) {
      // Carpeta pública de descargas (Downloads)
      final downloadsPath = '/storage/emulated/0/Download';
      filePath = '$downloadsPath/$fileName';
    } else {
      // iOS y otros: documentos de la app
      final directory = await pp.getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    }

    final tempFile = File(tempPath);
    final savedFile = await tempFile.copy(filePath);
    return savedFile.path;
  }

  /// Comparte el archivo
  Future<void> _shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Reporte generado desde la aplicación de asistencias');
  }
} 