import 'package:flutter/material.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/presentation/screens/attendees/attendees_screen.dart';
import 'package:asistencias_app/presentation/screens/profile_screen.dart';
import 'package:asistencias_app/presentation/screens/about_screen.dart';
import 'package:asistencias_app/presentation/screens/admin/meetings/admin_events_tab.dart'; // Importar AdminEventsTab
import 'package:asistencias_app/presentation/screens/record_attendance/record_attendance_screen.dart'; // Importar RecordAttendanceScreen
import 'package:fl_chart/fl_chart.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    // 0: Contenido del Tab de Inicio (Dashboard actual)
    const _HomeDashboardContent(),
    // 1: Contenido del Tab de Eventos (para visualizar eventos creados por admin)
    const AdminEventsTab(isAdminView: false), // Reutilizar AdminEventsTab para vista de usuario
    // 2: Contenido del Tab de Ingresar Asistencias
    const RecordAttendanceScreen(), // La nueva pantalla para ingresar asistencias
    // 3: Contenido del Tab de Asistentes (Gestión de asistentes)
    const AttendeesScreen(),
    // La pantalla de Perfil se accede desde el Drawer, no desde la barra inferior
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

    if (!user.isApproved) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cuenta Pendiente'),
        ),
        body: const Center(
          child: Text('Tu cuenta está pendiente de aprobación por el administrador.'),
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
        title: const Text('Panel de Usuario'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // Icono de hamburguesa
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: const [
          // Este botón de cerrar sesión ahora está en el Drawer, lo podemos quitar de aquí si quieres
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () async {
          //     await userProvider.signOut();
          //   },
          // ),
        ],
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
                // Navega a la pantalla de Perfil - ahora el índice de Perfil es 4, pero no está en la BottomBar
                // Lo ideal sería que el Drawer tenga su propia navegación a ProfileScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Ingresar Asistencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Asistentes',
          ),
          // Eliminado: BottomNavigationBarItem para Perfil
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    ));
  }
}

// Extraer el contenido del dashboard original en un widget separado
class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user!;
    final attendanceRecordService = AttendanceRecordService();

    return StreamBuilder<List<AttendanceRecordModel>>(
      stream: user.sectorId != null
          ? attendanceRecordService.getAttendanceRecordsStreamBySector(user.sectorId!)
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        // Filtrar registros del mes actual
        final now = DateTime.now();
        final currentMonthRecords = records.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
        // KPIs
        int totalAttendance = 0;
        int totalWeeks = 0;
        Map<int, int> weekAttendance = {};
        for (final record in currentMonthRecords) {
          final week = record.weekNumber;
          final total = record.attendedAttendeeIds.length + record.visitorCount;
          weekAttendance[week] = (weekAttendance[week] ?? 0) + total;
          totalAttendance += total;
        }
        totalWeeks = weekAttendance.length;
        final averageAttendance = totalWeeks > 0 ? (totalAttendance / totalWeeks).round() : 0;
        // Asistencia última semana
        int lastWeek = weekAttendance.keys.isNotEmpty ? weekAttendance.keys.reduce((a, b) => a > b ? a : b) : 0;
        int lastWeekAttendance = weekAttendance[lastWeek] ?? 0;

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
                              'Asistencia Total (Mes)',
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
                              'Promedio por Semana',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia por Semana', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: weekAttendance.isEmpty
                            ? const Center(child: Text('No hay datos de asistencia para este mes.'))
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: weekAttendance.values.isNotEmpty ? (weekAttendance.values.reduce((a, b) => a > b ? a : b).toDouble() + 5) : 10,
                                  barGroups: weekAttendance.entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.blue)])).toList(),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text('S${value.toInt()}'))),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia Última Semana', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        lastWeekAttendance > 0 ? '$lastWeekAttendance asistentes' : 'No hay datos para la última semana.',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 