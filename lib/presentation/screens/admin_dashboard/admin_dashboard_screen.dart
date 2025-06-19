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

import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/presentation/screens/admin_dashboard/detailed_reports_screen.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    // Contenido del Tab de Inicio (Dashboard actual)
    _HomeDashboardContent(),
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

    return Scaffold(
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
                            style: TextStyle(fontSize: 24, color: Colors.white))
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    user.displayName,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                leading: const Icon(Icons.description),
                title: const Text('Reportes Detallados'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DetailedReportsScreen(),
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
                Navigator.pop(context);
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
    );
  }
}

// Extraer el contenido del dashboard original en un widget separado
class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent({super.key});

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
        if (!snapshot.hasData || snapshot.data == null) {
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
  String? selectedCommuneId;
  bool _initialized = false;
  bool _loadingSectors = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDataIfNeeded();
    });
  }

  Future<void> _initDataIfNeeded() async {
    if (_initialized) return;
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.cities.isEmpty) {
      await locationProvider.loadCities();
    }
    if (locationProvider.communes.isEmpty && locationProvider.cities.isNotEmpty) {
      await locationProvider.loadCommunes(locationProvider.cities.first.id);
    }
    if (locationProvider.locations.isEmpty && locationProvider.communes.isNotEmpty) {
      await locationProvider.loadLocations(locationProvider.communes.first.id);
    }
    setState(() {
      _initialized = true;
      if (selectedCommuneId == null && locationProvider.communes.isNotEmpty) {
        final communesWithSectors = locationProvider.communes.where((c) => locationProvider.locations.any((l) => l.communeId == c.id)).toList();
        if (communesWithSectors.isNotEmpty) {
          selectedCommuneId = communesWithSectors.first.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final communes = locationProvider.communes;
    final locations = locationProvider.locations;

    if (!_initialized || _loadingSectors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (communes.isEmpty) {
      return const Text('No hay comunas registradas.');
    }

    final communesWithSectors = communes.where((c) => locations.any((l) => l.communeId == c.id)).toList();
    if (communesWithSectors.isEmpty) {
      return const Text('No hay comunas con sectores registrados.');
    }

    final sectors = locations.where((l) => l.communeId == selectedCommuneId).toList();

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
          'Asistencia Total por Sector (Comuna)',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedCommuneId,
          decoration: const InputDecoration(
            labelText: 'Selecciona una comuna',
            border: OutlineInputBorder(),
          ),
          items: communesWithSectors.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.name),
          )).toList(),
          onChanged: (value) async {
            setState(() {
              selectedCommuneId = value;
              _loadingSectors = true;
            });
            final commune = communesWithSectors.firstWhere((c) => c.id == value);
            await context.read<LocationProvider>().loadLocations(commune.id);
            setState(() {
              _loadingSectors = false;
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: sectorAttendance.isEmpty
              ? const Center(child: Text('No hay datos de asistencia para los sectores de esta comuna.'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: sectorAttendance.values.isNotEmpty ? (sectorAttendance.values.reduce((a, b) => a > b ? a : b).toDouble() + 5) : 10,
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
      ],
    );
  }
} 