import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';

class WeeklyAverageReportScreen extends StatefulWidget {
  const WeeklyAverageReportScreen({super.key});

  @override
  State<WeeklyAverageReportScreen> createState() => _WeeklyAverageReportScreenState();
}

class _WeeklyAverageReportScreenState extends State<WeeklyAverageReportScreen> {
  String? selectedCommuneId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final locationProvider = context.read<LocationProvider>();
    
    if (locationProvider.cities.isEmpty) {
      await locationProvider.loadCities();
    }
    
    final allCommunes = await locationProvider.loadAllCommunes();
    locationProvider.setCommunes = allCommunes;
    
    final allLocations = await locationProvider.loadAllLocations(allCommunes);
    locationProvider.setLocations = allLocations;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, double> _calculateDayAverages(List<AttendanceRecordModel> records, String sectorId, String day) {
    final sectorRecords = records.where((r) => r.sectorId == sectorId).toList();
    
    List<AttendanceRecordModel> dayRecords = [];
    
    switch (day.toLowerCase()) {
      case 'mie':
        dayRecords = sectorRecords.where((r) => r.date.weekday == DateTime.wednesday).toList();
        break;
      case 'sab':
        dayRecords = sectorRecords.where((r) => r.date.weekday == DateTime.saturday).toList();
        break;
      case 'dom_am':
        dayRecords = sectorRecords.where((r) => 
          r.date.weekday == DateTime.sunday && 
          r.date.hour < 14 // Antes de las 2 PM
        ).toList();
        break;
      case 'dom_pm':
        dayRecords = sectorRecords.where((r) => 
          r.date.weekday == DateTime.sunday && 
          r.date.hour >= 14 // Después de las 2 PM
        ).toList();
        break;
    }

    if (dayRecords.isEmpty) return {'average': 0.0, 'total': 0.0};

    double total = 0;
    for (final record in dayRecords) {
      total += record.attendedAttendeeIds.length + record.visitorCount;
    }

    return {
      'average': total / dayRecords.length,
      'total': total,
    };
  }

  Color _getBackgroundColor(double value, double maxValue) {
    if (maxValue == 0) return Colors.blue.shade50;
    
    final intensity = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue.shade50, Colors.blue.shade300, intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final attendanceRecordService = AttendanceRecordService();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte de Promedios por Días')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Promedios por Días')),
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: attendanceRecordService.getAllAttendanceRecordsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!;
          final communes = locationProvider.communes;
          final locations = locationProvider.locations;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de Comuna
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seleccionar Ruta (Comuna)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCommuneId,
                          hint: const Text('Selecciona una ruta'),
                          items: communes.map((commune) => DropdownMenuItem(
                            value: commune.id,
                            child: Text(commune.name),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCommuneId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tabla de Promedios
                if (selectedCommuneId != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildAverageTable(records, locations, selectedCommuneId!),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAverageTable(List<AttendanceRecordModel> records, List<Location> locations, String communeId) {
    final communeLocations = locations.where((l) => l.communeId == communeId).toList();
    
    if (communeLocations.isEmpty) {
      return const Center(child: Text('No hay sectores en esta ruta.'));
    }

    // Calcular datos para todos los sectores
    final tableData = <Map<String, dynamic>>[];
    double totalMie = 0, totalSab = 0, totalDomAm = 0, totalDomPm = 0, totalSemana = 0;

    for (final location in communeLocations) {
      final mie = _calculateDayAverages(records, location.id, 'mie')['average']!;
      final sab = _calculateDayAverages(records, location.id, 'sab')['average']!;
      final domAm = _calculateDayAverages(records, location.id, 'dom_am')['average']!;
      final domPm = _calculateDayAverages(records, location.id, 'dom_pm')['average']!;
      final semana = mie + sab + domAm + domPm;

      tableData.add({
        'sector': location.name,
        'mie': mie,
        'sab': sab,
        'domAm': domAm,
        'domPm': domPm,
        'semana': semana,
      });

      totalMie += mie;
      totalSab += sab;
      totalDomAm += domAm;
      totalDomPm += domPm;
      totalSemana += semana;
    }

    // Encontrar valor máximo para el degradado de colores
    double maxValue = 0;
    for (final row in tableData) {
      for (final key in ['mie', 'sab', 'domAm', 'domPm', 'semana']) {
        if (row[key] > maxValue) maxValue = row[key];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Promedios por Día de la Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith((states) => Theme.of(context).primaryColor.withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Sector', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Promedio MIE', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Promedio SÁB', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Promedio DOM AM', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Promedio DOM', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Promedio Semana', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              // Filas de datos
              ...tableData.map((row) => DataRow(
                cells: [
                  DataCell(Text(row['sector'], style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(row['mie'], maxValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(row['mie'].round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(row['sab'], maxValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(row['sab'].round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(row['domAm'], maxValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(row['domAm'].round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(row['domPm'], maxValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(row['domPm'].round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(row['semana'], maxValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(row['semana'].round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )),
              // Fila de totales
              DataRow(
                color: MaterialStateColor.resolveWith((states) => Theme.of(context).primaryColor.withOpacity(0.05)),
                cells: [
                  const DataCell(Text('Total general', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalMie.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalSab.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalDomAm.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalDomPm.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalSemana.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 