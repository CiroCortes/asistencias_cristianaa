import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';

class TTLWeeklyReportScreen extends StatefulWidget {
  const TTLWeeklyReportScreen({super.key});

  @override
  State<TTLWeeklyReportScreen> createState() => _TTLWeeklyReportScreenState();
}

class _TTLWeeklyReportScreenState extends State<TTLWeeklyReportScreen> {
  int selectedYear = DateTime.now().year;
  String? selectedMonth;
  String? selectedCommuneId; // null significa "Todas las rutas"
  String? selectedSectorId; // null significa "Todos los sectores"
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

    // Cargar todas las comunas/rutas para el filtro
    final allCommunes = await locationProvider.loadAllCommunes();
    locationProvider.setCommunes = allCommunes;

    // Cargar todas las ubicaciones
    final allLocations = await locationProvider.loadAllLocations(allCommunes);
    locationProvider.setLocations = allLocations;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateWeekData(
      List<AttendanceRecordModel> weekRecords) {
    // Separar por días
    final mieRecords =
        weekRecords.where((r) => r.date.weekday == DateTime.wednesday).toList();
    final sabRecords =
        weekRecords.where((r) => r.date.weekday == DateTime.saturday).toList();
    final domAmRecords = weekRecords
        .where((r) => r.date.weekday == DateTime.sunday && r.date.hour < 14)
        .toList();
    final domPmRecords = weekRecords
        .where((r) => r.date.weekday == DateTime.sunday && r.date.hour >= 14)
        .toList();

    // Contar asistencias por día
    int mieCount =
        mieRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length);
    int sabCount =
        sabRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length);
    int domAmCount =
        domAmRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length);
    int domPmCount =
        domPmRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length);

    // TTL REAL: Suma total de asistencias
    int ttlReal = mieCount + sabCount + domAmCount + domPmCount;

    // TTL SEMANA: Asistentes únicos
    Set<String> uniqueAttendees = {};
    for (final record in weekRecords) {
      uniqueAttendees.addAll(record.attendedAttendeeIds);
    }
    int ttlSemana = uniqueAttendees.length;

    // VISITAS: Total de visitantes
    int totalVisitas = weekRecords.fold(0, (sum, r) => sum + r.visitorCount);

    return {
      'mie': mieCount,
      'sab': sabCount,
      'domAm': domAmCount,
      'domPm': domPmCount,
      'ttlReal': ttlReal,
      'ttlSemana': ttlSemana,
      'visitas': totalVisitas,
    };
  }

  List<Map<String, dynamic>> _processRecordsToWeeks(
      List<AttendanceRecordModel> records) {
    final Map<int, List<AttendanceRecordModel>> weekGroups = {};

    // Agrupar registros por número de semana
    for (final record in records) {
      final weekNum = record.weekNumber ?? _getWeekNumber(record.date);
      if (!weekGroups.containsKey(weekNum)) {
        weekGroups[weekNum] = [];
      }
      weekGroups[weekNum]!.add(record);
    }

    // Procesar cada semana
    final List<Map<String, dynamic>> weeklyData = [];
    final sortedWeeks = weekGroups.keys.toList()..sort();

    for (final weekNum in sortedWeeks) {
      final weekRecords = weekGroups[weekNum]!;
      final firstDate = weekRecords.first.date;
      final weekData = _calculateWeekData(weekRecords);

      weeklyData.add({
        'weekNumber': weekNum,
        'month': DateFormat('MMMM', 'es').format(firstDate).toUpperCase(),
        'monthNumber': firstDate.month,
        'year': firstDate.year,
        ...weekData,
      });
    }

    return weeklyData;
  }

  int _getWeekNumber(DateTime date) {
    // SISTEMA NO ISO: Usar la misma lógica que date_utils.dart
    // La semana 1 empieza el 1 de enero, sin importar el día de la semana
    DateTime week1Start = DateTime(date.year, 1, 1);

    // Si la fecha es anterior al 1 de enero, usar el 1 de enero del año anterior
    if (date.isBefore(week1Start)) {
      week1Start = DateTime(date.year - 1, 1, 1);
    }

    // Calcular días desde el 1 de enero
    int diffDays = date.difference(week1Start).inDays;

    // El número de semana es (días / 7) + 1
    return (diffDays / 7).floor() + 1;
  }

  List<String> get _months => [
        'ENERO',
        'FEBRERO',
        'MARZO',
        'ABRIL',
        'MAYO',
        'JUNIO',
        'JULIO',
        'AGOSTO',
        'SEPTIEMBRE',
        'OCTUBRE',
        'NOVIEMBRE',
        'DICIEMBRE'
      ];

  Color _getCellColor(int value, int maxValue) {
    if (maxValue == 0 || value == 0) return Colors.white;

    final intensity = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue.shade50, Colors.blue.shade200, intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecordService = AttendanceRecordService();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte TTLs por Mes y Semana')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte TTLs por Mes y Semana'),
      ),
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: attendanceRecordService.getAllAttendanceRecordsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecords = snapshot.data!;
          final locationProvider = context.watch<LocationProvider>();
          final communes = locationProvider.communes;
          final locations = locationProvider.locations;

          // Filtrar por año seleccionado
          final yearRecords =
              allRecords.where((r) => r.date.year == selectedYear).toList();

          // Filtrar por ruta si está seleccionada
          List<AttendanceRecordModel> routeFilteredRecords = yearRecords;
          if (selectedCommuneId != null) {
            final communeSectorIds = locations
                .where((l) => l.communeId == selectedCommuneId)
                .map((l) => l.id)
                .toList();
            routeFilteredRecords = yearRecords
                .where((r) => communeSectorIds.contains(r.sectorId))
                .toList();
          }

          // Filtrar por sector si está seleccionado
          List<AttendanceRecordModel> sectorFilteredRecords =
              routeFilteredRecords;
          if (selectedSectorId != null) {
            sectorFilteredRecords = routeFilteredRecords
                .where((r) => r.sectorId == selectedSectorId)
                .toList();
          }

          final weeklyData = _processRecordsToWeeks(sectorFilteredRecords);

          // Filtrar por mes si está seleccionado
          final filteredData = selectedMonth != null
              ? weeklyData.where((w) => w['month'] == selectedMonth).toList()
              : weeklyData;

          // Calcular máximos para colores
          int maxTtlReal = 0;
          if (filteredData.isNotEmpty) {
            final values =
                filteredData.map((w) => w['ttlReal'] as int).toList();
            if (values.any((v) => v > 0)) {
              maxTtlReal = values.reduce((a, b) => a > b ? a : b);
            }
          }

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
                        const Text('Filtros:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        // Primera fila: Año y Mes
                        Row(
                          children: [
                            // Selector de Año
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Año:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  DropdownButtonFormField<int>(
                                    value: selectedYear,
                                    items: List.generate(
                                            5,
                                            (index) =>
                                                DateTime.now().year - index)
                                        .map((year) => DropdownMenuItem(
                                              value: year,
                                              child: Text(year.toString()),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedYear = value!;
                                        selectedMonth =
                                            null; // Reset month filter
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
                                  const Text('Mes (Opcional):',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  DropdownButtonFormField<String>(
                                    value: selectedMonth,
                                    hint: const Text('Todos los meses'),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Todos los meses'),
                                      ),
                                      ..._months
                                          .map((month) => DropdownMenuItem(
                                                value: month,
                                                child: Text(month),
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
                            const Text('Ruta:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButtonFormField<String>(
                              value: selectedCommuneId,
                              hint: const Text('Todas las rutas'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todas las rutas'),
                                ),
                                ...communes.map((commune) => DropdownMenuItem(
                                      value: commune.id,
                                      child: Text(commune.name),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedCommuneId = value;
                                  selectedSectorId =
                                      null; // Reset sector cuando cambia la ruta
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Tercera fila: Selector de Sector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sector:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButtonFormField<String>(
                              value: selectedSectorId,
                              hint: const Text('Todos los sectores'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todos los sectores'),
                                ),
                                // Filtrar sectores según la ruta seleccionada
                                ...locations
                                    .where((location) =>
                                        selectedCommuneId == null ||
                                        location.communeId == selectedCommuneId)
                                    .map((location) => DropdownMenuItem(
                                          value: location.id,
                                          child: Text(location.name),
                                        )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedSectorId = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tabla de TTLs
                if (filteredData.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildTTLTable(filteredData, maxTtlReal),
                    ),
                  ),
                ] else ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay registros para el período seleccionado',
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

  Widget _buildTTLTable(List<Map<String, dynamic>> data, int maxTtlReal) {
    final locationProvider = context.read<LocationProvider>();
    final selectedRouteName = selectedCommuneId != null
        ? locationProvider.communes
            .firstWhere((c) => c.id == selectedCommuneId,
                orElse: () => Commune(
                    id: '',
                    name: 'Ruta Desconocida',
                    cityId: '',
                    locationIds: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now()))
            .name
        : 'Todas las rutas';

    final selectedSectorName = selectedSectorId != null
        ? locationProvider.locations
            .firstWhere((l) => l.id == selectedSectorId,
                orElse: () => Location(
                    id: '',
                    name: 'Sector Desconocido',
                    communeId: '',
                    address: '',
                    attendeeIds: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now()))
            .name
        : 'Todos los sectores';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporte TTLs - Año $selectedYear${selectedMonth != null ? " - $selectedMonth" : ""} - $selectedRouteName - $selectedSectorName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith(
                (states) => Theme.of(context).primaryColor.withOpacity(0.1)),
            headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
            columnSpacing: 12,
            dataRowMinHeight: 35,
            dataRowMaxHeight: 35,
            columns: const [
              DataColumn(label: Text('MES')),
              DataColumn(label: Text('SEMANAS')),
              DataColumn(label: Text('MIE')),
              DataColumn(label: Text('SÁBADO')),
              DataColumn(label: Text('DOM AM')),
              DataColumn(label: Text('DOM PM')),
              DataColumn(label: Text('TTL REAL')),
              DataColumn(label: Text('TTL SEMANA')),
              DataColumn(label: Text('SEMANA')),
              DataColumn(label: Text('VISITAS')),
            ],
            rows: [
              ...data.map((weekData) => DataRow(
                    cells: [
                      DataCell(Text(
                        weekData['month'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      DataCell(Text(weekData['weekNumber'].toString())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCellColor(weekData['mie'], maxTtlReal),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['mie'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCellColor(weekData['sab'], maxTtlReal),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['sab'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCellColor(weekData['domAm'], maxTtlReal),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['domAm'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCellColor(weekData['domPm'], maxTtlReal),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['domPm'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['ttlReal'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['ttlSemana'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(Text(weekData['weekNumber'].toString())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            weekData['visitas'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )),
              // Fila de totales
              DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                    (states) => Colors.grey.shade100),
                cells: [
                  const DataCell(Text('TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataCell(Text('-')),
                  DataCell(Text(
                      data
                          .fold<int>(0, (sum, w) => sum + (w['mie'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(
                      data
                          .fold<int>(0, (sum, w) => sum + (w['sab'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(
                      data
                          .fold<int>(0, (sum, w) => sum + (w['domAm'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(
                      data
                          .fold<int>(0, (sum, w) => sum + (w['domPm'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(
                      data
                          .fold<int>(0, (sum, w) => sum + (w['ttlReal'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(
                      data
                          .fold<int>(
                              0, (sum, w) => sum + (w['ttlSemana'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  const DataCell(Text('-')),
                  DataCell(Text(
                      data
                          .fold<int>(0, (sum, w) => sum + (w['visitas'] as int))
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Leyenda de colores
        Wrap(
          spacing: 16,
          children: [
            _buildLegendItem('TTL Real', Colors.blue.shade100),
            _buildLegendItem('TTL Semana', Colors.grey.shade200),
            _buildLegendItem('Visitas', Colors.grey.shade300),
            _buildLegendItem('Días', Colors.grey.shade100),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
