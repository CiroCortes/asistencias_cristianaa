import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';

class SectorTotalsReportScreen extends StatefulWidget {
  const SectorTotalsReportScreen({super.key});

  @override
  State<SectorTotalsReportScreen> createState() =>
      _SectorTotalsReportScreenState();
}

class _SectorTotalsReportScreenState extends State<SectorTotalsReportScreen> {
  int selectedYear = DateTime.now().year;
  int? selectedWeekNumber; // null = todas las semanas
  String? selectedCommuneId; // null = todas las rutas
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

    // Cargar todas las comunas y locaciones para filtros
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

  List<int> _availableYears() =>
      List.generate(5, (i) => DateTime.now().year - i);

  // Obtiene semanas disponibles a partir de los registros del año filtrado
  List<int> _availableWeeks(Iterable<AttendanceRecordModel> records) {
    final weekSet = <int>{};
    for (final r in records) {
      if (r.date.year == selectedYear) weekSet.add(r.weekNumber);
    }
    final list = weekSet.toList()..sort();
    return list;
  }

  Color _getCellColor(int value, int maxValue) {
    if (maxValue <= 0) return Colors.white;
    final intensity = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue.shade50, Colors.blue.shade200, intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecordService = AttendanceRecordService();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte de Totales por Sectores')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Totales por Sectores')),
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

          // Asegurar que la semana seleccionada esté en la lista (si cambió el año)
          final weeksOfYear = _availableWeeks(allRecords);
          if (selectedWeekNumber != null &&
              !weeksOfYear.contains(selectedWeekNumber)) {
            selectedWeekNumber = null; // reset si no existe
          }

          // Filtrar por año
          List<AttendanceRecordModel> recordsByYear =
              allRecords.where((r) => r.date.year == selectedYear).toList();

          // Filtrar por week opcional
          if (selectedWeekNumber != null) {
            recordsByYear = recordsByYear
                .where((r) => r.weekNumber == selectedWeekNumber)
                .toList();
          }

          // Filtrar por ruta (comuna) opcional
          List<AttendanceRecordModel> filteredRecords = recordsByYear;
          if (selectedCommuneId != null) {
            final communeSectorIds = locations
                .where((l) => l.communeId == selectedCommuneId)
                .map((l) => l.id)
                .toList();
            filteredRecords = recordsByYear
                .where((r) => communeSectorIds.contains(r.sectorId))
                .toList();
          }

          // Construir tabla por sector
          final sectorIds = <String>{};
          for (final r in filteredRecords) {
            sectorIds.add(r.sectorId);
          }

          // Si se filtró por comuna, usar sólo sus sectores aunque no tengan registros
          List<Location> sectorLocations;
          if (selectedCommuneId != null) {
            sectorLocations = locations
                .where((l) => l.communeId == selectedCommuneId)
                .toList();
          } else {
            // Todos los sectores que aparecen en registros del año
            sectorLocations =
                locations.where((l) => sectorIds.contains(l.id)).toList();
          }

          // Calcular métricas por sector
          final rows = <_SectorRow>[];
          int maxTtlReal = 0;

          for (final loc in sectorLocations) {
            final sectorRecs =
                filteredRecords.where((r) => r.sectorId == loc.id).toList();

            // Contar por día
            final mie = sectorRecs
                .where((r) => r.date.weekday == DateTime.wednesday)
                .fold<int>(0, (sum, r) => sum + r.attendedAttendeeIds.length);
            final sab = sectorRecs
                .where((r) => r.date.weekday == DateTime.saturday)
                .fold<int>(0, (sum, r) => sum + r.attendedAttendeeIds.length);
            final domAm = sectorRecs
                .where((r) =>
                    r.date.weekday == DateTime.sunday && r.date.hour < 14)
                .fold<int>(0, (sum, r) => sum + r.attendedAttendeeIds.length);
            final domPm = sectorRecs
                .where((r) =>
                    r.date.weekday == DateTime.sunday && r.date.hour >= 14)
                .fold<int>(0, (sum, r) => sum + r.attendedAttendeeIds.length);

            final ttlReal = mie + sab + domAm + domPm;

            // TTL Semana = suma por semana de asistentes únicos
            final Map<int, Set<String>> weekToUnique = {};
            for (final rec in sectorRecs) {
              weekToUnique.putIfAbsent(rec.weekNumber, () => <String>{});
              weekToUnique[rec.weekNumber]!.addAll(rec.attendedAttendeeIds);
            }
            final ttlSemana =
                weekToUnique.values.fold<int>(0, (sum, s) => sum + s.length);

            // Visitas totales
            final visitas =
                sectorRecs.fold<int>(0, (sum, r) => sum + r.visitorCount);

            // Última semana con actividad (para mostrar cuando no se filtra por semana)
            int? lastWeek;
            if (sectorRecs.isNotEmpty) {
              final weeks = sectorRecs.map((r) => r.weekNumber).toList()
                ..sort();
              lastWeek = weeks.isNotEmpty ? weeks.last : null;
            }

            maxTtlReal = ttlReal > maxTtlReal ? ttlReal : maxTtlReal;

            rows.add(
              _SectorRow(
                sectorName: loc.name,
                mie: mie,
                sab: sab,
                domAm: domAm,
                domPm: domPm,
                ttlReal: ttlReal,
                ttlSemana: ttlSemana,
                semana: selectedWeekNumber ?? lastWeek,
                visitas: visitas,
              ),
            );
          }

          // Totales
          final totalRow = _SectorRow(
            sectorName: 'TOTAL',
            mie: rows.fold(0, (s, r) => s + r.mie),
            sab: rows.fold(0, (s, r) => s + r.sab),
            domAm: rows.fold(0, (s, r) => s + r.domAm),
            domPm: rows.fold(0, (s, r) => s + r.domPm),
            ttlReal: rows.fold(0, (s, r) => s + r.ttlReal),
            ttlSemana: rows.fold(0, (s, r) => s + r.ttlSemana),
            semana: null,
            visitas: rows.fold(0, (s, r) => s + r.visitas),
          );

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
                        Row(
                          children: [
                            // Año
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Año:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  DropdownButtonFormField<int>(
                                    value: selectedYear,
                                    items: _availableYears()
                                        .map((y) => DropdownMenuItem(
                                            value: y,
                                            child: Text(y.toString())))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedYear = value!;
                                        selectedWeekNumber =
                                            null; // reset semana al cambiar año
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Semana (opcional)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Semanas (opcional):',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  DropdownButtonFormField<int>(
                                    value: selectedWeekNumber,
                                    hint: const Text('Todas las semanas'),
                                    items: [
                                      const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text('Todas las semanas')),
                                      ...weeksOfYear.map((w) =>
                                          DropdownMenuItem<int>(
                                              value: w,
                                              child: Text(w.toString())))
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedWeekNumber = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Ruta (comuna)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ruta (Comuna):',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButtonFormField<String>(
                              value: selectedCommuneId,
                              hint: const Text('Todas las rutas'),
                              items: [
                                const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Todas las rutas')),
                                ...communes.map((c) => DropdownMenuItem<String>(
                                    value: c.id, child: Text(c.name)))
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedCommuneId = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Resumen
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Mostrando totales para ${selectedWeekNumber != null ? 'semana $selectedWeekNumber de' : 'todas las semanas de'} $selectedYear' +
                                (selectedCommuneId != null
                                    ? ' - ${communes.firstWhere((c) => c.id == selectedCommuneId).name}'
                                    : ''),
                            style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tabla
                if (rows.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildTable(rows, totalRow, maxTtlReal),
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

  Widget _buildTable(
      List<_SectorRow> rows, _SectorRow totalRow, int maxTtlReal) {
    // Ordenar por TTL REAL descendente para mejor lectura
    rows.sort((a, b) => b.ttlReal.compareTo(a.ttlReal));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith(
          (states) => Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        columnSpacing: 12,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 36,
        columns: const [
          DataColumn(
              label: Text('Sector',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('MIE', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('SÁBADO',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('DOM AM',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('DOM PM',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('TTL REAL',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('TTL SEMANA',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('SEMANA',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('VISITAS',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: [
          ...rows.map((r) => DataRow(cells: [
                DataCell(Text(r.sectorName,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(_valueCell(r.mie, maxTtlReal)),
                DataCell(_valueCell(r.sab, maxTtlReal)),
                DataCell(_valueCell(r.domAm, maxTtlReal)),
                DataCell(_valueCell(r.domPm, maxTtlReal)),
                DataCell(_valueCell(r.ttlReal, maxTtlReal, emphasize: true)),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(r.ttlSemana.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
                DataCell(Text(r.semana?.toString() ?? '-')),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(r.visitas.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
              ])),
          // Fila de totales
          DataRow(cells: [
            const DataCell(
                Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(totalRow.mie.toString())),
            DataCell(Text(totalRow.sab.toString())),
            DataCell(Text(totalRow.domAm.toString())),
            DataCell(Text(totalRow.domPm.toString())),
            DataCell(Text(totalRow.ttlReal.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(totalRow.ttlSemana.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold))),
            const DataCell(Text('-')),
            DataCell(Text(totalRow.visitas.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ],
      ),
    );
  }

  Widget _valueCell(int value, int max, {bool emphasize = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getCellColor(value, max),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500),
      ),
    );
  }
}

class _SectorRow {
  final String sectorName;
  final int mie;
  final int sab;
  final int domAm;
  final int domPm;
  final int ttlReal;
  final int ttlSemana;
  final int? semana;
  final int visitas;

  _SectorRow({
    required this.sectorName,
    required this.mie,
    required this.sab,
    required this.domAm,
    required this.domPm,
    required this.ttlReal,
    required this.ttlSemana,
    required this.semana,
    required this.visitas,
  });
}
