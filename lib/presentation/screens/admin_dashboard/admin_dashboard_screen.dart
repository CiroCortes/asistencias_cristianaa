import 'package:flutter/material.dart';
import 'package:asistencias_app/core/utils/permission_utils.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/presentation/screens/admin/locations/locations_screen.dart';
import 'package:asistencias_app/presentation/screens/admin/user_management_screen.dart';
import 'package:asistencias_app/presentation/screens/admin/meetings/admin_events_tab.dart';
import 'package:asistencias_app/presentation/screens/profile_screen.dart';
import 'package:asistencias_app/presentation/screens/about_screen.dart';
import 'package:asistencias_app/presentation/screens/attendees/attendees_screen.dart';
import 'package:asistencias_app/presentation/screens/record_attendance/record_attendance_screen.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/detailed_reports_screen.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/weekly_average_report_screen.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/ttl_weekly_report_screen.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/quarterly_ttl_report_screen.dart';
import 'package:asistencias_app/data/models/user_model.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/core/utils/date_utils.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  
  // Método para mostrar debug en tiempo real (pantalla + terminal)
  void _showDebugSnackBar(String message) {
    // Imprimir en terminal/consola
    print('🔷 DEBUG: $message');
    
    // Mostrar en pantalla
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  // Método para generar datos de prueba (solo para ciro.720@gmail.com)
  Future<void> _generateTestData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generando datos de prueba..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      await _executeTestDataScript();
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos de prueba generados exitosamente para Quilicura'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Método para limpiar datos inconsistentes de Firestore
  Future<void> _cleanupData(BuildContext context, String cleanupType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Ejecutando limpieza..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      await _executeCleanupScript(cleanupType);
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Limpieza completada exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en limpieza: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Ejecutar script de limpieza con diferentes opciones
  Future<void> _executeCleanupScript(String cleanupType) async {
    print('\n🧹 ===== INICIANDO LIMPIEZA DE DATOS =====');
    print('📋 Tipo de limpieza: $cleanupType');
    
    final firestore = FirebaseFirestore.instance;
    int deletedRecords = 0;
    int deletedAttendees = 0;
    int deletedMeetings = 0;
    
    try {
      if (cleanupType == 'analyze') {
        // ANÁLISIS: Solo contar y mostrar información sin eliminar
        _showDebugSnackBar('🔍 Analizando datos...');
        
        // Analizar registros de asistencia
        final allRecords = await firestore.collection('attendanceRecords').get();
        final testRecords = allRecords.docs.where((doc) {
          final data = doc.data();
          return data['recordedByUserId'] == 'test-admin-quilicura' ||
                 (data['createdByUserId'] != null && data['createdByUserId'] == 'test-admin-quilicura');
        }).toList();
        
        // Analizar asistentes
        final allAttendees = await firestore.collection('attendees').get();
        final testAttendees = allAttendees.docs.where((doc) {
          final data = doc.data();
          final name = data['name'] ?? '';
          return data['createdByUserId'] == 'test-admin-quilicura' ||
                 name.contains('TEST') ||
                 name.contains('test');
        }).toList();
        
        // Analizar meetings
        final allMeetings = await firestore.collection('recurring_meetings').get();
        final testMeetings = allMeetings.docs.where((doc) {
          final data = doc.data();
          return data['createdByUserId'] == 'test-admin-quilicura';
        }).toList();
        
        print('\n📊 ===== ANÁLISIS DE DATOS =====');
        print('📋 Registros de asistencia:');
        print('   • Total: ${allRecords.docs.length}');
        print('   • TEST/Problemáticos: ${testRecords.length}');
        print('👥 Asistentes:');
        print('   • Total: ${allAttendees.docs.length}');
        print('   • TEST/Problemáticos: ${testAttendees.length}');
        print('📅 Meetings recurrentes:');
        print('   • Total: ${allMeetings.docs.length}');
        print('   • TEST/Problemáticos: ${testMeetings.length}');
        
        _showDebugSnackBar('📊 Análisis completado - Ver consola para detalles');
        return;
      }
      
      // LIMPIEZA DE REGISTROS DE ASISTENCIA
      _showDebugSnackBar('🗑️ Paso 1: Limpiando registros de asistencia...');
      
      if (cleanupType == 'full') {
        // Eliminar TODOS los registros de asistencia
        final recordsQuery = await firestore.collection('attendanceRecords').get();
        for (final doc in recordsQuery.docs) {
          await doc.reference.delete();
          deletedRecords++;
        }
        _showDebugSnackBar('✅ Eliminados $deletedRecords registros de asistencia');
      } else {
        // Solo eliminar registros TEST (buscar por ambos campos para compatibilidad)
        final testRecords1 = await firestore
            .collection('attendanceRecords')
            .where('recordedByUserId', isEqualTo: 'test-admin-quilicura')
            .get();
        
        final testRecords2 = await firestore
            .collection('attendanceRecords')
            .where('createdByUserId', isEqualTo: 'test-admin-quilicura')
            .get();
        
        // Combinar resultados evitando duplicados
        final allTestRecords = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
        for (final doc in testRecords1.docs) {
          allTestRecords[doc.id] = doc;
        }
        for (final doc in testRecords2.docs) {
          allTestRecords[doc.id] = doc;
        }
        
        print('📊 Registros TEST encontrados: ${allTestRecords.length}');
        
        for (final doc in allTestRecords.values) {
          await doc.reference.delete();
          deletedRecords++;
        }
        
        _showDebugSnackBar('✅ Eliminados $deletedRecords registros de asistencia TEST');
      }
      
      // LIMPIEZA DE ASISTENTES (solo para 'test' y 'full')
      if (cleanupType != 'analyze') {
        _showDebugSnackBar('👥 Paso 2: Limpiando asistentes...');
        
        if (cleanupType == 'full') {
          // Eliminar TODOS los asistentes (¡CUIDADO!)
          final allAttendees = await firestore.collection('attendees').get();
          for (final doc in allAttendees.docs) {
            await doc.reference.delete();
            deletedAttendees++;
          }
        } else {
          // Solo eliminar asistentes TEST
          final testAttendees = await firestore
              .collection('attendees')
              .where('createdByUserId', isEqualTo: 'test-admin-quilicura')
              .get();
          
          for (final doc in testAttendees.docs) {
            await doc.reference.delete();
            deletedAttendees++;
          }
        }
        
        _showDebugSnackBar('✅ Eliminados $deletedAttendees asistentes');
      }
      
      // LIMPIEZA DE MEETINGS RECURRENTES (solo TEST)
      if (cleanupType != 'analyze') {
        _showDebugSnackBar('📅 Paso 3: Limpiando meetings recurrentes TEST...');
        
        final testMeetings = await firestore
            .collection('recurring_meetings')
            .where('createdByUserId', isEqualTo: 'test-admin-quilicura')
            .get();
        
        for (final doc in testMeetings.docs) {
          await doc.reference.delete();
          deletedMeetings++;
        }
        
        _showDebugSnackBar('✅ Eliminados $deletedMeetings meetings TEST');
      }
      
      // RESUMEN FINAL
      print('\n🎉 ===== LIMPIEZA COMPLETADA =====');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 ELIMINADOS:');
      print('  📋 Registros de asistencia: $deletedRecords');
      print('  👥 Asistentes: $deletedAttendees');
      print('  📅 Meetings recurrentes: $deletedMeetings');
      print('  💰 Costo Firebase: ~\$${(deletedRecords + deletedAttendees + deletedMeetings) * 0.0001} USD');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ Base de datos limpia. Los gráficos deberían funcionar correctamente.');
      
    } catch (e) {
      print('❌ ERROR durante limpieza: $e');
      throw e;
    }
  }

  // Ejecutar el script de generación de datos de prueba con debug
  Future<void> _executeTestDataScript() async {
    print('\n📋 ===== INICIANDO GENERACIÓN DE DATOS DE PRUEBA =====');
    
    final firestore = FirebaseFirestore.instance;
    final random = Random();
    const adminUserId = 'test-admin-quilicura';
    
    try {
      // DEBUG: Mostrar información paso a paso
      _showDebugSnackBar('🔍 Paso 1: Buscando ruta Quilicura...');
      
      // 1. Usar directamente el ID conocido de Quilicura
      const quilicuraId = 'QsszuqTZk0QDKHN8iTj6';
      print('🎯 Buscando commune con ID: $quilicuraId');
      
      final quilicuraDoc = await firestore.collection('communes').doc(quilicuraId).get();
      print('📄 Documento obtenido. Existe: ${quilicuraDoc.exists}');
      
      if (!quilicuraDoc.exists) {
        print('❌ ERROR: El documento no existe en Firebase');
        throw Exception('El documento Quilicura no existe en Firebase');
      }
      
      final quilicuraData = quilicuraDoc.data()!;
      print('📊 Datos del documento: $quilicuraData');
      
      final quilicuraName = quilicuraData['name'] ?? 'Sin nombre';
      final cityId = quilicuraData['cityId'] ?? 'Sin ciudad';
      final locationIds = List<String>.from(quilicuraData['locationIds'] ?? []);
      
      print('✅ Quilicura procesada:');
      print('   - Nombre: "$quilicuraName"');
      print('   - CityId: $cityId');
      print('   - LocationIds: $locationIds');
      print('   - Total sectores en array: ${locationIds.length}');
      
      _showDebugSnackBar('✅ Quilicura encontrada: "$quilicuraName" (${locationIds.length} sectores)');
      
      await Future.delayed(const Duration(seconds: 1));
      
      // 2. Obtener sectores de Quilicura
      print('\n🗺️ ===== PASO 2: BUSCANDO SECTORES =====');
      _showDebugSnackBar('🔍 Paso 2: Buscando sectores de Quilicura...');
      
      print('🔍 Consultando collection "locations" con communeId = $quilicuraId');
      
      final sectorsQuery = await firestore
          .collection('locations')
          .where('communeId', isEqualTo: quilicuraId)
          .get();
      
      print('📊 Query ejecutada. Documentos encontrados: ${sectorsQuery.docs.length}');
      
      if (sectorsQuery.docs.isEmpty) {
        print('❌ ERROR: No se encontraron sectores para communeId: $quilicuraId');
        
        // DEBUG: Listar todos los sectores disponibles
        print('🔍 Investigando todos los sectores disponibles...');
        final allLocationsQuery = await firestore.collection('locations').get();
        print('📋 Total sectores en DB: ${allLocationsQuery.docs.length}');
        
        for (final doc in allLocationsQuery.docs) {
          final data = doc.data();
          print('   • ID: ${doc.id} | CommuneId: "${data['communeId']}" | Name: "${data['name']}"');
        }
        
        throw Exception('No se encontraron sectores en Quilicura');
      }
      
      final sectors = sectorsQuery.docs;
      print('✅ Sectores encontrados: ${sectors.length}');
      
      // DEBUG: Mostrar todos los sectores encontrados
      for (int i = 0; i < sectors.length; i++) {
        final sectorData = sectors[i].data();
        final sectorName = sectorData['name'] ?? 'Sin nombre';
        final sectorId = sectors[i].id;
        print('   📍 Sector ${i + 1}: "$sectorName" (ID: $sectorId)');
      }
      
      int totalAttendees = 0;
      
      // 3. Generar 10 asistentes por sector
      print('\n👥 ===== PASO 3: GENERANDO ASISTENTES =====');
      _showDebugSnackBar('👥 Paso 3: Generando asistentes TEST...');
      await Future.delayed(const Duration(seconds: 1));
      
      int sectorCount = 0;
      
      for (final sector in sectors) {
        sectorCount++;
        final sectorId = sector.id;
        final sectorName = sector.data()['name'] ?? 'Sector ${sector.id}';
        
        print('📝 Sector $sectorCount/${sectors.length}: "$sectorName" (ID: $sectorId)');
        _showDebugSnackBar('📝 Creando 10 asistentes para: $sectorName');
        
        for (int i = 1; i <= 10; i++) {
          final attendeeData = {
            'firstName': 'TEST Nombre$i',
            'lastName': 'TEST Apellido$i $sectorName',
            'phone': '+569${1000 + random.nextInt(9000)}${1000 + random.nextInt(9000)}',
            'address': 'TEST Dirección $i, $sectorName, Quilicura',
            'sectorId': sectorId,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdByUserId': adminUserId,
          };
          
          print('   👤 Creando asistente $i/10: ${attendeeData['firstName']} ${attendeeData['lastName']}');
          
          await firestore.collection('attendees').add(attendeeData);
          totalAttendees++;
        }
        
        print('✅ Completado sector "$sectorName": 10 asistentes creados');
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      print('🎉 TOTAL ASISTENTES CREADOS: $totalAttendees');
      _showDebugSnackBar('✅ Creados $totalAttendees asistentes TEST');
      await Future.delayed(const Duration(seconds: 1));
      
      // 4. Generar registros de asistencia para junio y julio 2025
      print('\n📊 ===== PASO 4: GENERANDO REGISTROS DE ASISTENCIA =====');
      _showDebugSnackBar('📊 Paso 4: Generando registros de asistencia...');
      await Future.delayed(const Duration(seconds: 1));
      
      print('🔍 Buscando asistentes TEST creados (createdByUserId = $adminUserId)');
      
      final attendeesQuery = await firestore
          .collection('attendees')
          .where('createdByUserId', isEqualTo: adminUserId)
          .get();
      
      final allAttendees = attendeesQuery.docs;
      print('👥 Asistentes TEST encontrados: ${allAttendees.length}');
      _showDebugSnackBar('👥 Encontrados ${allAttendees.length} asistentes TEST');
      
      if (allAttendees.isEmpty) {
        throw Exception('No se encontraron asistentes TEST creados previamente');
      }
      
      // Fechas para junio y julio 2025
      final meetingDates = <DateTime>[];
      
      // Junio 2025
      meetingDates.addAll([
        DateTime(2025, 6, 4, 19, 30), DateTime(2025, 6, 11, 19, 30),
        DateTime(2025, 6, 18, 19, 30), DateTime(2025, 6, 25, 19, 30),
      ]);
      meetingDates.addAll([
        DateTime(2025, 6, 7, 10, 0), DateTime(2025, 6, 14, 10, 0),
        DateTime(2025, 6, 21, 10, 0), DateTime(2025, 6, 28, 10, 0),
      ]);
      meetingDates.addAll([
        DateTime(2025, 6, 1, 10, 0), DateTime(2025, 6, 8, 10, 0),
        DateTime(2025, 6, 15, 10, 0), DateTime(2025, 6, 22, 10, 0), DateTime(2025, 6, 29, 10, 0),
      ]);
      meetingDates.addAll([
        DateTime(2025, 6, 1, 16, 0), DateTime(2025, 6, 8, 16, 0),
        DateTime(2025, 6, 15, 16, 0), DateTime(2025, 6, 22, 16, 0), DateTime(2025, 6, 29, 16, 0),
      ]);
      
      // Julio 2025
      meetingDates.addAll([
        DateTime(2025, 7, 2, 19, 30), DateTime(2025, 7, 9, 19, 30),
        DateTime(2025, 7, 16, 19, 30), DateTime(2025, 7, 23, 19, 30), DateTime(2025, 7, 30, 19, 30),
      ]);
      meetingDates.addAll([
        DateTime(2025, 7, 5, 10, 0), DateTime(2025, 7, 12, 10, 0),
        DateTime(2025, 7, 19, 10, 0), DateTime(2025, 7, 26, 10, 0),
      ]);
      meetingDates.addAll([
        DateTime(2025, 7, 6, 10, 0), DateTime(2025, 7, 13, 10, 0),
        DateTime(2025, 7, 20, 10, 0), DateTime(2025, 7, 27, 10, 0),
      ]);
      meetingDates.addAll([
        DateTime(2025, 7, 6, 16, 0), DateTime(2025, 7, 13, 16, 0),
        DateTime(2025, 7, 20, 16, 0), DateTime(2025, 7, 27, 16, 0),
      ]);
      
      int totalRecords = 0;
      int processedSectors = 0;
      
      // 5. Generar registros de asistencia
      print('\n📅 ===== PASO 5: GENERANDO REGISTROS DE ASISTENCIA =====');
      print('📊 Total fechas de reuniones jun-jul 2025: ${meetingDates.length}');
      _showDebugSnackBar('📅 Generando registros para jun-jul 2025...');
      
      for (final sector in sectors) {
        final sectorId = sector.id;
        final sectorName = sector.data()['name'] ?? 'Sector';
        final sectorAttendees = allAttendees.where(
          (attendee) => attendee.data()['sectorId'] == sectorId
        ).toList();
        
        processedSectors++;
        print('⏳ Sector $processedSectors/${sectors.length}: "$sectorName" (${sectorAttendees.length} asistentes)');
        _showDebugSnackBar('⏳ Procesando sector $processedSectors/${sectors.length}: $sectorName');
        
        int sectorRecords = 0;
        
        for (final date in meetingDates) {
          String meetingType;
          if (date.weekday == 3 && date.hour == 19) {
            meetingType = 'culto_miercoles';
          } else if (date.weekday == 6 && date.hour == 10) {
            meetingType = 'ttl_sabado';
          } else if (date.weekday == 7 && date.hour == 10) {
            meetingType = 'culto_domingo_manana';
          } else {
            meetingType = 'culto_domingo_tarde';
          }
          
          // Seleccionar asistentes (70-90% asistencia)
          final attendanceRate = 0.7 + (random.nextDouble() * 0.2);
          final attendingCount = (sectorAttendees.length * attendanceRate).round();
          final attendingAttendees = sectorAttendees.take(attendingCount).toList();
          
          for (final attendee in attendingAttendees) {
            final recordData = {
              'attendeeId': attendee.id,
              'meetingType': meetingType,
              'attendanceDate': Timestamp.fromDate(date),
              'sectorId': sectorId,
              'notes': 'Registro de prueba generado automáticamente',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'createdByUserId': adminUserId,
            };
            
            await firestore.collection('attendanceRecords').add(recordData);
            totalRecords++;
            sectorRecords++;
          }
        }
        
        print('   ✅ Sector "$sectorName" completado: $sectorRecords registros creados');
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Debug final
      print('\n🎉 ===== PROCESO COMPLETADO =====');
      print('📊 RESUMEN FINAL:');
      print('   👥 Asistentes TEST creados: $totalAttendees');
      print('   📅 Registros de asistencia: $totalRecords');
      print('   🏙️  Ruta: Quilicura');
      print('   📍 Sectores procesados: ${sectors.length}');
      print('   💰 Costo estimado Firebase: < \$0.002 USD');
      
      _showDebugSnackBar('🎉 ¡COMPLETADO! Asistentes: $totalAttendees | Registros: $totalRecords');
    } catch (e) {
      print('❌ ERROR GENERAL en generación de datos: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      _showDebugSnackBar('❌ ERROR: $e');
      rethrow;
    }
  }

  static final List<Widget> _widgetOptions = <Widget>[
    // Contenido del Tab de Inicio (Dashboard actual)
    const _HomeDashboardContent(),
    // Contenido del Tab de Asistencia (Ahora RecordAttendanceScreen)
    const RecordAttendanceScreen(),
    // Contenido del Tab de Eventos (AdminEventsTab con permisos de administrador)
    const AdminEventsTab(isAdminView: true),
    // Contenido del Tab de Asistentes
    const AttendeesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!PermissionUtils.isAdmin(user)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
        ),
        body: const Center(
          child: Text('No tienes permisos para acceder a esta sección'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Salida'),
            content: const Text('¿Estás seguro de que quieres salir de la aplicación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  // Cierra la app
                  // SystemNavigator.pop();
                },
                child: const Text('Salir'),
              ),
            ],
          ),
        ).then((exit) {
          if (exit ?? false) {
             // Cierra la app
             // SystemNavigator.pop();
          }
        });
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(user.displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            
            if (PermissionUtils.canManageUsers(user))
              ListTile(
                leading: const Icon(Icons.people_alt),
                title: const Text('Gestionar Usuarios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
            if (PermissionUtils.canManageLocations(user))
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Gestionar Ubicaciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationsScreen(),
                    ),
                  );
                },
              ),
            if (PermissionUtils.canViewReports(user))
              ListTile(
                leading: const Icon(Icons.description, color: Colors.grey),
                title: const Text('Reportes Detallados (En mantenimiento)', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Esta función está temporalmente deshabilitada. Próximamente nueva versión.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            // Nuevo reporte de promedios por días de la semana
            if (PermissionUtils.canViewReports(user))
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Reporte de Promedios por Días'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeeklyAverageReportScreen(),
                    ),
                  );
                },
              ),
            // Reporte TTLs por mes y semana
            if (PermissionUtils.canViewReports(user))
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Reporte TTLs por Mes y Semana'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TTLWeeklyReportScreen(),
                    ),
                  );
                },
              ),
            // Reporte Trimestral TTLs
            if (PermissionUtils.canViewReports(user))
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Reporte Trimestral TTLs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuarterlyTTLReportScreen(),
                    ),
                  );
                },
              ),
            // Opción de datos de prueba (solo para ciro.720@gmail.com)
            if (user.email == 'ciro.720@gmail.com')
              ListTile(
                leading: const Icon(Icons.science, color: Colors.orange),
                title: const Text('🧪 Generar Datos de Prueba'),
                subtitle: const Text('Quilicura - Jun/Jul 2025'),
                onTap: () async {
                  Navigator.pop(context);
                  
                  // Mostrar confirmación
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('🧪 Generar Datos de Prueba'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Esto generará en la ruta QUILICURA:'),
                          SizedBox(height: 8),
                          Text('• 80 asistentes TEST (10 por sector)'),
                          Text('• ~800 registros de asistencia jun-jul 2025'),
                          Text('• Datos realistas para dashboards'),
                          SizedBox(height: 16),
                          Text('💰 Costo Firebase: < \$0.002 USD'),
                          SizedBox(height: 8),
                          Text('🔍 Verás el progreso paso a paso', 
                               style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('⚠️ Solo usar para demo con cliente', 
                               style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('🚀 Generar'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await _generateTestData(context);
                  }
                },
              ),
            // Opción de limpieza de datos (solo para administradores)
            if (PermissionUtils.canManageUsers(user))
              ListTile(
                leading: const Icon(Icons.cleaning_services, color: Colors.red),
                title: const Text('🧹 Limpiar Datos Inconsistentes'),
                subtitle: const Text('Eliminar registros malformados'),
                onTap: () async {
                  Navigator.pop(context);
                  
                  // Mostrar confirmación con opciones
                  final option = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('🧹 Limpiar Datos Inconsistentes'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selecciona qué tipo de limpieza realizar:'),
                          SizedBox(height: 12),
                          Text('• Limpieza Completa: Elimina TODOS los registros de asistencia'),
                          Text('• Limpieza de Prueba: Solo registros TEST y malformados'),
                          Text('• Análisis: Revisar datos sin eliminar'),
                          SizedBox(height: 16),
                          Text('⚠️ Esta acción no se puede deshacer', 
                               style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'analyze'),
                          child: const Text('📊 Analizar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'test'),
                          child: const Text('🧪 Solo TEST'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, 'full'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('🗑️ Completa'),
                        ),
                      ],
                    ),
                  );
                  
                  if (option != null) {
                    await _cleanupData(context, option);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                // Cierra el drawer
                Navigator.pop(context);

                // Muestra un diálogo de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Dialog(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("Cerrando sesión..."),
                          ],
                        ),
                      ),
                    );
                  },
                );

                // Espera 2 segundos para la animación
                await Future.delayed(const Duration(seconds: 2));

                // Cierra el diálogo antes de desloguear
                if (mounted) {
                  Navigator.pop(context);
                }

                // Ejecuta el cierre de sesión
                await userProvider.signOut();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Asistencia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Asistentes',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    ));
  }
}

// Extraer el contenido del dashboard original en un widget separado
class _HomeDashboardContent extends StatefulWidget {
  const _HomeDashboardContent();

  @override
  State<_HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<_HomeDashboardContent> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    final locationProvider = context.read<LocationProvider>();
    
    // Cargar datos de ubicación necesarios para ambos gráficos
    if (locationProvider.cities.isEmpty) {
      await locationProvider.loadCities();
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user!;
    final attendeeProvider = context.watch<AttendeeProvider>();
    final attendees = attendeeProvider.attendees;
    final attendanceRecordService = AttendanceRecordService();

    return StreamBuilder<List<AttendanceRecordModel>>(
      stream: attendanceRecordService.getAllAttendanceRecordsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || !_isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!.where((r) => r != null).toList();
        // Filtrar registros del mes actual
        final now = DateTime.now();
        final currentMonthRecords = records.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
        
        // Formatear el nombre del mes actual
        final monthNames = [
          '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        final currentMonthName = monthNames[now.month];
        
        // Calcular semana actual y anterior
        final currentWeek = getWeekNumber(now);
        final previousWeek = currentWeek - 1;
        final currentYear = now.year;
        
        // Filtrar registros por semanas
        final currentWeekRecords = records.where((r) => r.weekNumber == currentWeek && r.year == currentYear).toList();
        final previousWeekRecords = records.where((r) => r.weekNumber == previousWeek && r.year == currentYear).toList();
        
        // Calcular asistencia mensual
        int totalMonthlyMembers = 0;
        int totalMonthlyListeners = 0;
        int totalMonthlyVisitors = 0;
        for (final record in currentMonthRecords) {
          final ids = record.attendedAttendeeIds;
          for (final id in ids) {
            final attendee = attendees.firstWhere(
              (a) => a.id == id,
              orElse: () => AttendeeModel(id: '', type: '', sectorId: '', createdAt: DateTime.now(), createdByUserId: ''),
            );
            if (attendee.type == 'member') totalMonthlyMembers++;
            if (attendee.type == 'listener') totalMonthlyListeners++;
          }
          totalMonthlyVisitors += record.visitorCount;
        }
        final totalMonthlyAttendance = totalMonthlyMembers + totalMonthlyListeners + totalMonthlyVisitors;
        
        // Calcular asistencia semanal actual
        int currentWeekAttendance = 0;
        for (final record in currentWeekRecords) {
          currentWeekAttendance += record.attendedAttendeeIds.length + record.visitorCount;
        }
        
        // Calcular asistencia semanal anterior
        int previousWeekAttendance = 0;
        for (final record in previousWeekRecords) {
          previousWeekAttendance += record.attendedAttendeeIds.length + record.visitorCount;
        }
        
        // Calcular TTL por días específicos de la semana actual
        final currentWeekRecordsFiltered = records.where((r) => r.weekNumber == currentWeek && r.year == currentYear).toList();
        
        // TTL Miércoles
        final ttlMiercoles = currentWeekRecordsFiltered
            .where((r) => r.date.weekday == DateTime.wednesday)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
            
        // TTL Sábados  
        final ttlSabados = currentWeekRecordsFiltered
            .where((r) => r.date.weekday == DateTime.saturday)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
            
        // TTL Domingo AM (antes de las 2 PM)
        final ttlDomingoAM = currentWeekRecordsFiltered
            .where((r) => r.date.weekday == DateTime.sunday && r.date.hour < 14)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
            
        // TTL Domingo PM (después de las 2 PM)
        final ttlDomingoPM = currentWeekRecordsFiltered
            .where((r) => r.date.weekday == DateTime.sunday && r.date.hour >= 14)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistencia Total - $currentMonthName $currentYear',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalMonthlyAttendance',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Asistencia Semanal',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                  'Semana $currentWeek: $currentWeekAttendance',
                              style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Semana $previousWeek: $previousWeekAttendance',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Diferencia: ${currentWeekAttendance - previousWeekAttendance}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: currentWeekAttendance >= previousWeekAttendance 
                                              ? Colors.green 
                                              : Colors.red),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      currentWeekAttendance >= previousWeekAttendance 
                                          ? Icons.trending_up 
                                          : Icons.trending_down,
                                      size: 16,
                                      color: currentWeekAttendance >= previousWeekAttendance 
                                          ? Colors.green 
                                          : Colors.red,
                            ),
                          ],
                        ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cards TTL Semanal por Días
              const Text(
                'TTL Semanal por Días',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'TTL MIERC',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Semana $currentWeek',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ttlMiercoles',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'TTL SABADO',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Semana $currentWeek',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ttlSabados',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'TTL DOM AM',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Semana $currentWeek',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ttlDomingoAM',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'TTL DOM PM',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Semana $currentWeek',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ttlDomingoPM',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (PermissionUtils.canViewReports(user)) ...[
                const Text(
                  'Asistencia Mensual por Tipo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                          alignment: BarChartAlignment.spaceEvenly,
                          maxY: [totalMonthlyMembers, totalMonthlyListeners, totalMonthlyVisitors].reduce((a, b) => a > b ? a : b).toDouble() + 25,
                          barTouchData: BarTouchData(
                            enabled: false, // Desactivado porque tooltips están siempre visibles
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.transparent, // Sin fondo
                              tooltipRoundedRadius: 0,
                              tooltipPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                String value = '';
                                switch (group.x) {
                                  case 0:
                                    value = '$totalMonthlyMembers';
                                    break;
                                  case 1:
                                    value = '$totalMonthlyListeners';
                                    break;
                                  case 2:
                                    value = '$totalMonthlyVisitors';
                                    break;
                                }
                                return BarTooltipItem(
                                  value,
                                  const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text('Miembros');
                                case 1:
                                  return const Text('Oyentes');
                                case 2:
                                  return const Text('Visitas');
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                            BarChartGroupData(
                              x: 0, 
                              showingTooltipIndicators: [0], // Siempre mostrar tooltip
                              barRods: [BarChartRodData(
                                toY: totalMonthlyMembers.toDouble(), 
                                color: Colors.blue,
                                width: 40,
                                borderRadius: BorderRadius.circular(4),
                              )]
                            ),
                            BarChartGroupData(
                              x: 1, 
                              showingTooltipIndicators: [0], // Siempre mostrar tooltip
                              barRods: [BarChartRodData(
                                toY: totalMonthlyListeners.toDouble(), 
                                color: Colors.orange,
                                width: 40,
                                borderRadius: BorderRadius.circular(4),
                              )]
                            ),
                            BarChartGroupData(
                              x: 2, 
                              showingTooltipIndicators: [0], // Siempre mostrar tooltip
                              barRods: [BarChartRodData(
                                toY: totalMonthlyVisitors.toDouble(), 
                                color: Colors.green,
                                width: 40,
                                borderRadius: BorderRadius.circular(4),
                              )]
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Calcular total semanal para el subtítulo
                Builder(
                  builder: (context) {
                    int totalSemanal = 0;
                    for (final record in currentWeekRecordsFiltered) {
                      totalSemanal += record.attendedAttendeeIds.length + record.visitorCount;
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asistencia Semanal por Rutas',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Semana: $currentWeek, total: $totalSemanal',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: _WeeklyRouteAttendanceChart(records: currentWeekRecordsFiltered),
                ),
                const SizedBox(height: 32),
                _ComunaSectorAttendanceChart(
                  records: currentWeekRecordsFiltered,
                  currentWeek: currentWeek,
                  currentYear: currentYear,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// --- NUEVO WIDGET: _ComunaSectorAttendanceChart ---
class _ComunaSectorAttendanceChart extends StatefulWidget {
  final List<AttendanceRecordModel> records;
  final int currentWeek;
  final int currentYear;
  
  const _ComunaSectorAttendanceChart({
    required this.records,
    required this.currentWeek,
    required this.currentYear,
  });

  @override
  State<_ComunaSectorAttendanceChart> createState() => _ComunaSectorAttendanceChartState();
}

class _ComunaSectorAttendanceChartState extends State<_ComunaSectorAttendanceChart> {
  String? selectedCityId;
  String? selectedCommuneId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaultSelections();
    });
  }

  void _initializeDefaultSelections() {
    final locationProvider = context.read<LocationProvider>();
    
    // Seleccionar la primera ciudad por defecto si no hay selección
    if (locationProvider.cities.isNotEmpty && selectedCityId == null) {
      setState(() {
        selectedCityId = locationProvider.cities.first.id;
      });
      _loadCommunesAndLocations();
    }
  }

  Future<void> _loadCommunesAndLocations() async {
    if (selectedCityId == null) return;

    final locationProvider = context.read<LocationProvider>();
    
    // Cargar todas las rutas
    final allCommunes = await locationProvider.loadAllCommunes();
    locationProvider.setCommunes = allCommunes;
    
    // Filtrar rutas por ciudad seleccionada
    final cityCommunes = allCommunes.where((c) => c.cityId == selectedCityId).toList();
    
    // Cargar locaciones para las rutas de la ciudad seleccionada
    final allLocations = await locationProvider.loadAllLocations(cityCommunes);
    locationProvider.setLocations = allLocations;

    // Seleccionar la primera ruta que tenga sectores si no hay una seleccionada
    if (selectedCommuneId == null && cityCommunes.isNotEmpty) {
      final communesWithSectors = cityCommunes
          .where((c) => allLocations.any((l) => l.communeId == c.id))
          .toList();
      
      if (communesWithSectors.isNotEmpty && mounted) {
        setState(() {
          selectedCommuneId = communesWithSectors.first.id;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final cities = locationProvider.cities;
    final communes = locationProvider.communes;
    final locations = locationProvider.locations;

    // Filtrar rutas por ciudad seleccionada
    final filteredCommunes = communes.where((c) => c.cityId == selectedCityId).toList();
    final communesWithSectors = filteredCommunes
        .where((c) => locations.any((l) => l.communeId == c.id))
        .toList();

    // Validar que selectedCityId existe en las ciudades disponibles
    if (selectedCityId != null && !cities.any((city) => city.id == selectedCityId)) {
      selectedCityId = null;
    }

    // Validar que selectedCommuneId existe en las comunas disponibles
    if (selectedCommuneId != null && !communesWithSectors.any((commune) => commune.id == selectedCommuneId)) {
      selectedCommuneId = null;
    }

    // Obtener sectores de la ruta seleccionada
    final sectors = selectedCommuneId != null
        ? locations.where((l) => l.communeId == selectedCommuneId).toList()
        : [];

    // Calcular asistencia por sector (solo semana actual)
    final Map<String, int> sectorAttendance = {};
    
    // Inicializar TODOS los sectores con 0 (para mostrar incluso sectores sin asistencias)
    for (final sector in sectors) {
      sectorAttendance[sector.name] = 0;
    }
    
    // Sumar asistencias reales
    for (final sector in sectors) {
      final sectorRecords = widget.records.where((r) => r.sectorId == sector.id);
      int total = 0;
      for (final record in sectorRecords) {
        total += record.attendedAttendeeIds.length + record.visitorCount;
      }
      sectorAttendance[sector.name] = total;
    }

    // Calcular total semanal para el título
    final int totalSemanal = sectorAttendance.values.fold(0, (sum, value) => sum + value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text(
          'Asistencia Total por Sector',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Semana: ${widget.currentWeek}, total: $totalSemanal',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Selector de Ciudad
        DropdownButtonFormField<String>(
          value: selectedCityId,
          decoration: const InputDecoration(
            labelText: 'Selecciona una Ciudad',
            border: OutlineInputBorder(),
          ),
          items: cities.map((city) => DropdownMenuItem(
            value: city.id,
            child: Text(city.name),
          )).toList(),
          onChanged: (value) async {
            setState(() {
              selectedCityId = value;
              selectedCommuneId = null;
            });
            if (value != null) {
              await _loadCommunesAndLocations();
            }
          },
        ),
        const SizedBox(height: 16),
        // Selector de Ruta
        if (communesWithSectors.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: selectedCommuneId,
            decoration: const InputDecoration(
              labelText: 'Selecciona una Ruta',
              border: OutlineInputBorder(),
            ),
            items: communesWithSectors.map((commune) => DropdownMenuItem(
              value: commune.id,
              child: Text(commune.name),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedCommuneId = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ] else if (selectedCityId != null) ...[
          const Text('No hay rutas con sectores en esta ciudad.'),
          const SizedBox(height: 16),
        ],
        // Gráfico de barras
        if (selectedCommuneId != null && sectorAttendance.isNotEmpty) ...[
          SizedBox(
            height: 260,
            child: Builder(
              builder: (context) {
                final entries = sectorAttendance.entries.toList();
                final hasValidData = entries.isNotEmpty;
                
                return BarChart(
              BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                maxY: sectorAttendance.values.isNotEmpty 
                        ? (sectorAttendance.values.reduce((a, b) => a > b ? a : b).toDouble() + 20) 
                    : 10,
                    barTouchData: BarTouchData(
                      enabled: false, // Tooltips siempre visibles
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.transparent,
                        tooltipRoundedRadius: 0,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final index = group.x.toInt();
                          
                          if (!hasValidData || index < 0 || index >= entries.length) {
                            return null;
                          }
                          
                          final value = entries[index].value;
                          return BarTooltipItem(
                            '$value',
                            const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: entries
                    .asMap()
                    .entries
                    .map((entry) => BarChartGroupData(
                          x: entry.key,
                              showingTooltipIndicators: hasValidData ? [0] : [], // Siempre mostrar tooltip
                              barRods: [BarChartRodData(
                                toY: entry.value.value.toDouble(), 
                                color: Colors.purple[700],
                                width: 40,
                                borderRadius: BorderRadius.circular(4),
                              )],
                        ))
                    .toList(),
                titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                          reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                            
                            if (!hasValidData || index < 0 || index >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -0.5,
                          child: Text(
                                  entries[index].key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                            overflow: TextOverflow.ellipsis,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
                );
              },
            ),
          ),
        ] else if (selectedCommuneId != null) ...[
          const Center(
            child: Text('No hay datos de asistencia para los sectores de esta ruta.'),
          ),
        ],
      ],
    );
  }
}

// --- NUEVO WIDGET: _WeeklyRouteAttendanceChart ---
class _WeeklyRouteAttendanceChart extends StatelessWidget {
  final List<AttendanceRecordModel> records;
  
  const _WeeklyRouteAttendanceChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final communes = locationProvider.communes;
    final locations = locationProvider.locations;

    if (communes.isEmpty || locations.isEmpty) {
      return const Center(child: Text('Cargando datos de rutas...'));
    }

    // Agrupar asistencias por comuna
    final Map<String, int> communeAttendance = {};
    final Map<String, String> communeNames = {};

    // Inicializar comunas con sus nombres
    for (final commune in communes) {
      communeAttendance[commune.id] = 0;
      communeNames[commune.id] = commune.name;
    }

    // Calcular asistencias por comuna
    for (final record in records) {
      // Buscar la comuna del sector
      final location = locations.firstWhere(
        (loc) => loc.id == record.sectorId,
        orElse: () => Location(
          id: '',
          name: '',
          communeId: '',
          address: '',
          attendeeIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (location.communeId.isNotEmpty && communeAttendance.containsKey(location.communeId)) {
        communeAttendance[location.communeId] = 
            (communeAttendance[location.communeId] ?? 0) + 
            record.attendedAttendeeIds.length + 
            record.visitorCount;
      }
    }

    // Mostrar TODAS las comunas (incluso con 0 asistencias)
    final allCommuneEntries = communeAttendance.entries.toList();

    if (allCommuneEntries.isEmpty) {
      return const Center(child: Text('No hay rutas configuradas'));
    }

    // Preparar datos para el gráfico
    final maxValue = allCommuneEntries.map((e) => e.value).isNotEmpty 
        ? allCommuneEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxValue.toDouble() + 20,
        barTouchData: BarTouchData(
          enabled: false, // Tooltips siempre visibles
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.transparent, // Sin fondo
            tooltipRoundedRadius: 0,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final communeId = allCommuneEntries[group.x.toInt()].key;
              final value = communeAttendance[communeId] ?? 0;
              return BarTooltipItem(
                '$value',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= allCommuneEntries.length) {
                  return const SizedBox.shrink();
                }
                final communeId = allCommuneEntries[index].key;
                final communeName = communeNames[communeId] ?? 'Ruta $index';
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Transform.rotate(
                    angle: -0.5, // Títulos ladeados
                    child: Text(
                      communeName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: allCommuneEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final communeData = entry.value;
          return BarChartGroupData(
            x: index,
            showingTooltipIndicators: [0], // Siempre mostrar tooltip
            barRods: [
              BarChartRodData(
                toY: communeData.value.toDouble(),
                color: Colors.purple[700], // Barras púrpuras
                width: 30,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
} 