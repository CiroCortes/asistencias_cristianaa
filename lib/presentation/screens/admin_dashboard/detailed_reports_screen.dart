import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';

import 'package:asistencias_app/data/models/location_models.dart';

class DetailedReportsScreen extends StatefulWidget {
  const DetailedReportsScreen({Key? key}) : super(key: key);

  @override
  State<DetailedReportsScreen> createState() => _DetailedReportsScreenState();
}

class _DetailedReportsScreenState extends State<DetailedReportsScreen> {
  String? selectedCityId;
  String? selectedCommuneId;
  String? selectedSectorId;
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final attendeeProvider = context.watch<AttendeeProvider>();
    final attendanceRecordService = AttendanceRecordService();

    // Cargar comunas y sectores al seleccionar ciudad
    Future<void> onCityChanged(String? cityId) async {
      setState(() {
        selectedCityId = cityId;
        selectedCommuneId = null;
        selectedSectorId = null;
      });
      if (cityId != null) {
        await locationProvider.loadCommunes(cityId);
        // Cargar todos los sectores de las comunas de la ciudad
        final cityCommunes = locationProvider.communes.where((c) => c.cityId == cityId).toList();
        for (final commune in cityCommunes) {
          await locationProvider.loadLocations(commune.id);
        }
      }
    }
    // Cargar sectores al seleccionar comuna
    Future<void> onCommuneChanged(String? communeId) async {
      setState(() {
        selectedCommuneId = communeId;
        selectedSectorId = null;
      });
      if (communeId != null) {
        await locationProvider.loadLocations(communeId);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes Detallados')),
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: attendanceRecordService.getAllAttendanceRecordsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final attendees = attendeeProvider.attendees;
          final cities = locationProvider.cities;
          final communes = locationProvider.communes;
          final sectors = locationProvider.locations;

          // Mostrar loader solo si aún se están cargando comunas o sectores tras seleccionar ciudad
          if (selectedCityId != null) {
            final cityCommunes = communes.where((c) => c.cityId == selectedCityId).toList();
            // Si aún no se han cargado las comunas de la ciudad seleccionada
            if (locationProvider.isLoading || cityCommunes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            // Si no hay ningún sector cargado para la ciudad seleccionada, pero solo después de cargar
            final citySectorCount = sectors.where((s) => cityCommunes.any((c) => c.id == s.communeId)).length;
            if (!locationProvider.isLoading && citySectorCount == 0) {
              return const Center(child: Text('No hay sectores registrados para la ciudad seleccionada.'));
            }
          }

          // Filtros dinámicos
          List<AttendanceRecordModel> filteredRecords = records;
          if (selectedDateRange != null) {
            filteredRecords = filteredRecords.where((r) =>
              r.date.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              r.date.isBefore(selectedDateRange!.end.add(const Duration(days: 1)))
            ).toList();
          }
          if (selectedCityId != null) {
            // Filtrar por sectores de todas las comunas de la ciudad seleccionada
            final cityCommunes = communes.where((c) => c.cityId == selectedCityId).toList();
            final citySectorIds = <String>[];
            for (final commune in cityCommunes) {
              citySectorIds.addAll(sectors.where((s) => s.communeId == commune.id).map((s) => s.id));
            }
            filteredRecords = filteredRecords.where((r) => citySectorIds.contains(r.sectorId)).toList();
          }
          if (selectedCommuneId != null) {
            final communeSectorIds = sectors.where((s) => s.communeId == selectedCommuneId).map((s) => s.id).toList();
            filteredRecords = filteredRecords.where((r) => communeSectorIds.contains(r.sectorId)).toList();
          }
          if (selectedSectorId != null) {
            filteredRecords = filteredRecords.where((r) => r.sectorId == selectedSectorId).toList();
          }

          // --- KPI 0: Asistencia total por número de semana (todas las semanas del año) ---
          final Map<int, int> yearWeekAttendance = {};
          for (final record in filteredRecords) {
            final week = record.weekNumber;
            final total = record.attendedAttendeeIds.length + record.visitorCount;
            yearWeekAttendance[week] = (yearWeekAttendance[week] ?? 0) + total;
          }

          // --- KPI 1: Asistencia por semana ---
          final Map<int, int> weekAttendance = {};
          for (final record in filteredRecords) {
            final week = record.weekNumber;
            final total = record.attendedAttendeeIds.length + record.visitorCount;
            weekAttendance[week] = (weekAttendance[week] ?? 0) + total;
          }

          // --- KPI 2: Asistencia por ciudad y comuna ---
          final Map<String, Map<String, int>> cityCommuneAttendance = {};
          for (final record in filteredRecords) {
            final sector = sectors.firstWhere((s) => s.id == record.sectorId, orElse: () => Location(id: '', name: '', communeId: '', address: '', attendeeIds: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
            final commune = communes.firstWhere((c) => c.id == sector.communeId, orElse: () => Commune(id: '', name: '', cityId: '', locationIds: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
            final city = cities.firstWhere((ci) => ci.id == commune.cityId, orElse: () => City(id: '', name: '', communeIds: [], createdAt: DateTime.now(), updatedAt: DateTime.now(), isActive: true));
            if (city.id.isEmpty || commune.id.isEmpty) continue;
            cityCommuneAttendance[city.name] ??= {};
            cityCommuneAttendance[city.name]![commune.name] = (cityCommuneAttendance[city.name]![commune.name] ?? 0) + record.attendedAttendeeIds.length + record.visitorCount;
          }

          // --- KPI 3: Asistencia por comuna y sector ---
          final Map<String, Map<String, int>> communeSectorAttendance = {};
          for (final record in filteredRecords) {
            final sector = sectors.firstWhere((s) => s.id == record.sectorId, orElse: () => Location(id: '', name: '', communeId: '', address: '', attendeeIds: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
            final commune = communes.firstWhere((c) => c.id == sector.communeId, orElse: () => Commune(id: '', name: '', cityId: '', locationIds: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
            if (commune.id.isEmpty || sector.id.isEmpty) continue;
            communeSectorAttendance[commune.name] ??= {};
            communeSectorAttendance[commune.name]![sector.name] = (communeSectorAttendance[commune.name]![sector.name] ?? 0) + record.attendedAttendeeIds.length + record.visitorCount;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Filtros
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCityId,
                        hint: const Text('Ciudad'),
                        items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => onCityChanged(v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCommuneId,
                        hint: const Text('Comuna'),
                        items: communes.where((c) => selectedCityId == null || c.cityId == selectedCityId).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => onCommuneChanged(v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedSectorId,
                        hint: const Text('Sector'),
                        items: sectors.where((s) => selectedCommuneId == null || s.communeId == selectedCommuneId).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (v) => setState(() { selectedSectorId = v; }),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(selectedDateRange == null ? 'Rango de fechas' : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month}/${selectedDateRange!.start.year} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}/${selectedDateRange!.end.year}'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => selectedDateRange = picked);
                        },
                      ),
                      if (selectedDateRange != null)
                        TextButton(
                          onPressed: () => setState(() => selectedDateRange = null),
                          child: const Text('Limpiar rango de fechas'),
                        ),
                    ],
                  ),
                ),
              ),
              // KPI 0: Asistencia total por número de semana (todas las semanas del año)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia Total por Semana (Año)', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: yearWeekAttendance.isEmpty
                            ? const Center(child: Text('No hay datos de asistencia por semana.'))
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: yearWeekAttendance.values.isNotEmpty ? (yearWeekAttendance.values.reduce((a, b) => a > b ? a : b).toDouble() + 5) : 10,
                                  barGroups: yearWeekAttendance.entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.purple)])).toList(),
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
              // KPI 1: Asistencia por semana
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia por Semana', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: BarChart(
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
              // KPI 2: Asistencia por ciudad y comuna
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia por Ciudad y Comuna', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...cityCommuneAttendance.entries.map((cityEntry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cityEntry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: cityEntry.value.values.isNotEmpty ? (cityEntry.value.values.reduce((a, b) => a > b ? a : b).toDouble() + 5) : 10,
                                barGroups: cityEntry.value.entries.map((e) => BarChartGroupData(x: cityEntry.value.keys.toList().indexOf(e.key), barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.orange)])).toList(),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(cityEntry.value.keys.elementAt(value.toInt())))),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
              // KPI 3: Asistencia por comuna y sector
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistencia por Comuna y Sector', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...communeSectorAttendance.entries.map((communeEntry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(communeEntry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: communeEntry.value.values.isNotEmpty ? (communeEntry.value.values.reduce((a, b) => a > b ? a : b).toDouble() + 5) : 10,
                                barGroups: communeEntry.value.entries.map((e) => BarChartGroupData(x: communeEntry.value.keys.toList().indexOf(e.key), barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.green)])).toList(),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(communeEntry.value.keys.elementAt(value.toInt())))),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 