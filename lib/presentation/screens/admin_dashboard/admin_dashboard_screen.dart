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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

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
        // Mapear attendedAttendeeIds a tipo
        int totalMembers = 0;
        int totalListeners = 0;
        int totalVisitors = 0;
        for (final record in currentMonthRecords) {
          final ids = record.attendedAttendeeIds;
          for (final id in ids) {
            final attendee = attendees.firstWhere(
              (a) => a.id == id,
              orElse: () => AttendeeModel(id: '', type: '', sectorId: '', createdAt: DateTime.now(), createdByUserId: ''),
            );
            if (attendee.type == 'member') totalMembers++;
            if (attendee.type == 'listener') totalListeners++;
          }
          totalVisitors += record.visitorCount;
        }
        final totalAttendance = totalMembers + totalListeners + totalVisitors;
        final averageAttendance = currentMonthRecords.isNotEmpty ? (totalAttendance / currentMonthRecords.length).round() : 0;

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
                            const Text(
                              'Asistencia Total',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalAttendance',
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
                              'Asistencia Promedio',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$averageAttendance',
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
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: [totalMembers, totalListeners, totalVisitors].reduce((a, b) => a > b ? a : b).toDouble() + 5,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles:  SideTitles(showTitles: true, reservedSize: 28),
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
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalMembers.toDouble(), color: Colors.blue)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalListeners.toDouble(), color: Colors.orange)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: totalVisitors.toDouble(), color: Colors.green)]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _ComunaSectorAttendanceChart(records: records),
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
  const _ComunaSectorAttendanceChart({required this.records});

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

    // Calcular asistencia por sector
    final Map<String, int> sectorAttendance = {};
    for (final sector in sectors) {
      final sectorRecords = widget.records.where((r) => r.sectorId == sector.id);
      int total = 0;
      for (final record in sectorRecords) {
        total += record.attendedAttendeeIds.length + record.visitorCount;
      }
      sectorAttendance[sector.name] = total;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text(
          'Asistencia Total por Sector',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sectorAttendance.values.isNotEmpty 
                    ? (sectorAttendance.values.reduce((a, b) => a > b ? a : b).toDouble() + 5) 
                    : 10,
                barGroups: sectorAttendance.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [BarChartRodData(toY: entry.value.value.toDouble(), color: Colors.purple)],
                        ))
                    .toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sectorAttendance.keys.length) return const SizedBox.shrink();
                        return Transform.rotate(
                          angle: -0.7,
                          child: Text(
                            sectorAttendance.keys.elementAt(index),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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