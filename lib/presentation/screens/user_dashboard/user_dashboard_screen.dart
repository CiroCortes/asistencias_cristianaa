import 'package:flutter/material.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/presentation/screens/attendees/attendees_screen.dart';
import 'package:asistencias_app/presentation/screens/profile_screen.dart';
import 'package:asistencias_app/presentation/screens/about_screen.dart';
import 'package:asistencias_app/presentation/screens/admin/meetings/admin_events_tab.dart'; // Importar AdminEventsTab
import 'package:asistencias_app/presentation/screens/record_attendance/record_attendance_screen.dart'; // Importar RecordAttendanceScreen
import 'package:fl_chart/fl_chart.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/core/utils/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
class _HomeDashboardContent extends StatefulWidget {
  const _HomeDashboardContent();

  @override
  State<_HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<_HomeDashboardContent> {
  String? _sectorName;
  bool _loadingSectorName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      if (user?.sectorId != null) {
        _fetchSectorName(user!.sectorId!);
      }
    });
  }

  Future<void> _fetchSectorName(String sectorId) async {
    setState(() { _loadingSectorName = true; });
    try {
      final doc = await FirebaseFirestore.instance.collection('locations').doc(sectorId).get();
      if (doc.exists && mounted) {
        setState(() {
          _sectorName = doc.data()!["name"] ?? sectorId;
        });
      } else if (mounted) {
        setState(() { _sectorName = sectorId; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _sectorName = sectorId; });
      }
    } finally {
      if (mounted) {
        setState(() { _loadingSectorName = false; });
      }
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
      stream: user.sectorId != null
          ? attendanceRecordService.getAttendanceRecordsStreamBySector(user.sectorId!)
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        
        // Calcular semana actual y anterior
        final now = DateTime.now();
        final currentWeek = getWeekNumber(now);
        final previousWeek = currentWeek - 1;
        final currentYear = now.year;
        
        // Filtrar registros por semanas
        final currentWeekRecords = records.where((r) => r.weekNumber == currentWeek && r.year == currentYear).toList();
        final previousWeekRecords = records.where((r) => r.weekNumber == previousWeek && r.year == currentYear).toList();
        
        // Calcular asistencia semanal
        final currentWeekAttendance = currentWeekRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
        final previousWeekAttendance = previousWeekRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
        
        // Calcular promedio de la semana actual (solo días con reuniones)
        final daysWithMeetings = currentWeekRecords.map((r) => r.date.weekday).toSet().length;
        final weeklyAverage = daysWithMeetings > 0 ? (currentWeekAttendance / daysWithMeetings).round() : 0;
        
        // Calcular TTL por días específicos de la semana actual
        final ttlMiercoles = currentWeekRecords
            .where((r) => r.date.weekday == DateTime.wednesday)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
            
        final ttlSabados = currentWeekRecords
            .where((r) => r.date.weekday == DateTime.saturday)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
            
        final ttlDomingoAM = currentWeekRecords
            .where((r) => r.date.weekday == DateTime.sunday && r.date.hour < 14)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);
            
        final ttlDomingoPM = currentWeekRecords
            .where((r) => r.date.weekday == DateTime.sunday && r.date.hour >= 14)
            .fold(0, (sum, r) => sum + r.attendedAttendeeIds.length + r.visitorCount);

        // Calcular TTL semanal por tipo (miembros, oyentes, visitas)
        int weeklyMembers = 0;
        int weeklyListeners = 0;
        int weeklyVisitors = 0;
        
        for (final record in currentWeekRecords) {
          // Contar visitas directas
          weeklyVisitors += record.visitorCount;
          
          // Contar miembros y oyentes por attendeeId
          for (final attendeeId in record.attendedAttendeeIds) {
            final attendee = attendees.firstWhere(
              (a) => a.id == attendeeId,
              orElse: () => AttendeeModel(
                type: 'member', // Default fallback
                sectorId: user.sectorId!,
                createdAt: DateTime.now(),
                createdByUserId: user.uid,
              ),
            );
            
            if (attendee.type == 'member') {
              weeklyMembers++;
            } else if (attendee.type == 'listener') {
              weeklyListeners++;
            }
          }
        }
        
        // Calcular suma total para gráficos
        final totalByType = weeklyMembers + weeklyListeners + weeklyVisitors;

        // Filtrar registros del mes actual para el gráfico
        final currentMonthRecords = records.where((r) => r.date.month == now.month && r.date.year == now.year).toList();
        Map<int, int> weekAttendance = {};
        for (final record in currentMonthRecords) {
          final week = record.weekNumber;
          final total = record.attendedAttendeeIds.length + record.visitorCount;
          weekAttendance[week] = (weekAttendance[week] ?? 0) + total;
        }
        
        // Calcular suma total del mes
        final monthlyTotal = weekAttendance.values.fold(0, (sum, value) => sum + value);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loadingSectorName 
                    ? 'RESUMEN' 
                    : _sectorName != null 
                        ? 'RESUMEN ($_sectorName)' 
                        : 'RESUMEN',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                              'Asistencia Total - Semana $currentWeek',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$currentWeekAttendance',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Promedio: $weeklyAverage',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600]),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia por Semana', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Total mensual: $monthlyTotal',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: weekAttendance.isEmpty
                            ? const Center(child: Text('No hay datos de asistencia para este mes.'))
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: weekAttendance.values.isNotEmpty ? (weekAttendance.values.reduce((a, b) => a > b ? a : b).toDouble() + 20) : 10,
                                  barTouchData: BarTouchData(
                                    enabled: false, // Desactivado porque tooltips están siempre visibles
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBgColor: Colors.transparent, // Sin fondo
                                      tooltipRoundedRadius: 0,
                                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final value = weekAttendance[group.x.toInt()] ?? 0;
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
                                  barGroups: weekAttendance.entries.map((e) => BarChartGroupData(
                                    x: e.key, 
                                    showingTooltipIndicators: [0], // Siempre mostrar tooltip
                                    barRods: [BarChartRodData(
                                      toY: e.value.toDouble(), 
                                      color: Colors.blue,
                                      width: 40,
                                      borderRadius: BorderRadius.circular(4),
                                    )]
                                  )).toList(),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              // Nuevo gráfico TTL Semanal por Tipo
              Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    'TTL Semanal por Tipo - Semana $currentWeek',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                      Text(
                    'Total: $totalByType',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: [weeklyMembers, weeklyListeners, weeklyVisitors].reduce((a, b) => a > b ? a : b).toDouble() + 25,
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
                              value = '$weeklyMembers';
                              break;
                            case 1:
                              value = '$weeklyListeners';
                              break;
                            case 2:
                              value = '$weeklyVisitors';
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
                          toY: weeklyMembers.toDouble(), 
                          color: Colors.blue,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        )]
                      ),
                      BarChartGroupData(
                        x: 1, 
                        showingTooltipIndicators: [0], // Siempre mostrar tooltip
                        barRods: [BarChartRodData(
                          toY: weeklyListeners.toDouble(), 
                          color: Colors.green,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        )]
                      ),
                      BarChartGroupData(
                        x: 2, 
                        showingTooltipIndicators: [0], // Siempre mostrar tooltip
                        barRods: [BarChartRodData(
                          toY: weeklyVisitors.toDouble(), 
                          color: Colors.orange,
                          width: 40,
                          borderRadius: BorderRadius.circular(4),
                        )]
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