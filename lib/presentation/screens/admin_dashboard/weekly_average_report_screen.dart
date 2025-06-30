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
  int selectedYear = DateTime.now().year;
  int? selectedMonth; // null significa "Todos los meses"
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

    // Seleccionar automáticamente la primera ruta si no hay ninguna seleccionada
    if (allCommunes.isNotEmpty && selectedCommuneId == null) {
      selectedCommuneId = allCommunes.first.id;
    }

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

  // Lista de años disponibles (últimos 5 años)
  List<int> get _availableYears => List.generate(5, (index) => DateTime.now().year - index);

  // Lista de meses
  List<Map<String, dynamic>> get _months => [
    {'value': 1, 'name': 'Enero'},
    {'value': 2, 'name': 'Febrero'},
    {'value': 3, 'name': 'Marzo'},
    {'value': 4, 'name': 'Abril'},
    {'value': 5, 'name': 'Mayo'},
    {'value': 6, 'name': 'Junio'},
    {'value': 7, 'name': 'Julio'},
    {'value': 8, 'name': 'Agosto'},
    {'value': 9, 'name': 'Septiembre'},
    {'value': 10, 'name': 'Octubre'},
    {'value': 11, 'name': 'Noviembre'},
    {'value': 12, 'name': 'Diciembre'},
  ];

  // Filtrar registros por año y mes
  List<AttendanceRecordModel> _filterRecordsByDate(List<AttendanceRecordModel> records) {
    return records.where((record) {
      final matchesYear = record.date.year == selectedYear;
      final matchesMonth = selectedMonth == null || record.date.month == selectedMonth;
      return matchesYear && matchesMonth;
    }).toList();
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

          final allRecords = snapshot.data!;
          final communes = locationProvider.communes;
          final locations = locationProvider.locations;

          // Filtrar registros por año y mes
          final filteredRecords = _filterRecordsByDate(allRecords);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtros
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filtros:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // Primera fila: Año y Mes
                        Row(
                          children: [
                            // Selector de Año
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Año:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<int>(
                                    value: selectedYear,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: _availableYears.map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    )).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedYear = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Selector de Mes
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Mes (Opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<int>(
                                    value: selectedMonth,
                                    hint: const Text('Todos los meses'),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('Todos los meses'),
                                      ),
                                      ..._months.map((month) => DropdownMenuItem<int>(
                                        value: month['value'],
                                        child: Text(month['name']),
                                      )),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedMonth = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Segunda fila: Selector de Ruta
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ruta (Comuna):', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: selectedCommuneId,
                              hint: const Text('Selecciona una ruta'),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
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
                        
                        // Resumen de filtros aplicados
                        if (selectedCommuneId != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '📊 Mostrando promedios para ${selectedMonth != null ? _months.firstWhere((m) => m['value'] == selectedMonth)['name'] : 'todos los meses'} de $selectedYear - ${communes.firstWhere((c) => c.id == selectedCommuneId).name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                      child: _buildAverageTable(filteredRecords, locations, selectedCommuneId!),
                    ),
                  ),
                ] else ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Por favor selecciona una ruta para ver los promedios',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
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

    // Verificar si hay registros después del filtrado
    if (records.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay registros de asistencia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Para ${selectedMonth != null ? _months.firstWhere((m) => m['value'] == selectedMonth)['name'] : 'el período seleccionado'} de $selectedYear en esta ruta.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes cambiar los filtros en la parte superior para ver más datos.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
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

    // Obtener información de la ruta seleccionada
    final communeName = context.read<LocationProvider>().communes
        .firstWhere((c) => c.id == communeId, orElse: () => 
            Commune(id: '', name: 'Ruta Desconocida', cityId: '', locationIds: [], createdAt: DateTime.now(), updatedAt: DateTime.now())).name;
    
    // Calcular estadísticas de los registros
    final totalRecords = records.length;
    final uniqueDates = records.map((r) => '${r.date.year}-${r.date.month}-${r.date.day}').toSet().length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con filtros aplicados
        Text(
          'Promedios por Día de la Semana',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedMonth != null ? _months.firstWhere((m) => m['value'] == selectedMonth)['name'] : 'Todos los meses'} de $selectedYear - $communeName',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalRecords registros',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$uniqueDates fechas únicas',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
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