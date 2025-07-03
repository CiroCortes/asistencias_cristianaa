import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';

class QuarterlyTTLReportScreen extends StatefulWidget {
  const QuarterlyTTLReportScreen({super.key});

  @override
  State<QuarterlyTTLReportScreen> createState() => _QuarterlyTTLReportScreenState();
}

class _QuarterlyTTLReportScreenState extends State<QuarterlyTTLReportScreen> {
  int selectedYear = DateTime.now().year;
  int selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
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

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getQuarterMonths(int quarter) {
    switch (quarter) {
      case 1:
        return ['ENERO', 'FEBRERO', 'MARZO'];
      case 2:
        return ['ABRIL', 'MAYO', 'JUNIO'];
      case 3:
        return ['JULIO', 'AGOSTO', 'SEPTIEMBRE'];
      case 4:
        return ['OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'];
      default:
        return ['ENERO', 'FEBRERO', 'MARZO'];
    }
  }

  List<int> _getQuarterMonthNumbers(int quarter) {
    switch (quarter) {
      case 1:
        return [1, 2, 3];
      case 2:
        return [4, 5, 6];
      case 3:
        return [7, 8, 9];
      case 4:
        return [10, 11, 12];
      default:
        return [1, 2, 3];
    }
  }

  String _getQuarterOrdinal(int quarter) {
    switch (quarter) {
      case 1:
        return '1er';
      case 2:
        return '2do';
      case 3:
        return '3er';
      case 4:
        return '4to';
      default:
        return '1er';
    }
  }

  Map<String, dynamic> _calculateMonthTTLs(List<AttendanceRecordModel> monthRecords) {
    // Agrupar por semana
    final Map<int, List<AttendanceRecordModel>> weekGroups = {};
    for (final record in monthRecords) {
      final weekNum = record.weekNumber ?? _getWeekNumber(record.date);
      if (!weekGroups.containsKey(weekNum)) {
        weekGroups[weekNum] = [];
      }
      weekGroups[weekNum]!.add(record);
    }

    // Calcular TTLs por semana y luego sumar
    int totalTtlReal = 0;
    int totalTtlSemana = 0;
    int totalVisitas = 0;
    List<int> weeklyTtlReal = [];
    List<int> weeklyTtlSemana = [];
    List<int> weeklyVisitas = [];

    for (final weekRecords in weekGroups.values) {
      // TTL REAL: Suma de todas las asistencias
      final weekTtlReal = weekRecords.fold(0, (sum, r) => sum + r.attendedAttendeeIds.length);
      
      // TTL SEMANA: Asistentes únicos
      final Set<String> uniqueAttendees = {};
      for (final record in weekRecords) {
        uniqueAttendees.addAll(record.attendedAttendeeIds);
      }
      final weekTtlSemana = uniqueAttendees.length;
      
      // VISITAS: Total de visitantes
      final weekVisitas = weekRecords.fold(0, (sum, r) => sum + r.visitorCount);

      weeklyTtlReal.add(weekTtlReal);
      weeklyTtlSemana.add(weekTtlSemana);
      weeklyVisitas.add(weekVisitas);

      totalTtlReal += weekTtlReal;
      totalTtlSemana += weekTtlSemana;
      totalVisitas += weekVisitas;
    }

    final weekCount = weekGroups.length;

    return {
      'sumaTtlReal': totalTtlReal,
      'sumaTtlSemana': totalTtlSemana,
      'sumaVisitas': totalVisitas,
      'promedioTtlReal': weekCount > 0 ? (totalTtlReal / weekCount).round() : 0,
      'promedioTtlSemana': weekCount > 0 ? (totalTtlSemana / weekCount).round() : 0,
      'promedioVisitas': weekCount > 0 ? (totalVisitas / weekCount).round() : 0,
      'weekCount': weekCount,
    };
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecordService = AttendanceRecordService();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte Trimestral TTLs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Trimestral TTLs'),
      ),
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: attendanceRecordService.getAllAttendanceRecordsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecords = snapshot.data!;
          final quarterMonths = _getQuarterMonthNumbers(selectedQuarter);
          final quarterMonthNames = _getQuarterMonths(selectedQuarter);

          // Filtrar y procesar datos por mes
          final Map<String, Map<String, dynamic>> monthlyData = {};
          for (int i = 0; i < quarterMonths.length; i++) {
            final monthNum = quarterMonths[i];
            final monthName = quarterMonthNames[i];
            
            final monthRecords = allRecords.where((r) => 
              r.date.year == selectedYear && r.date.month == monthNum
            ).toList();
            
            monthlyData[monthName] = _calculateMonthTTLs(monthRecords);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtros
                _buildFilters(),
                const SizedBox(height: 24),
                
                // Sección SUMAS
                _buildSumasSection(monthlyData, quarterMonthNames),
                const SizedBox(height: 32),
                
                // Sección PROMEDIOS
                _buildPromediosSection(monthlyData, quarterMonthNames),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Selector de Año
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Año:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    items: List.generate(5, (index) => DateTime.now().year - index)
                        .map((year) => DropdownMenuItem(
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
            // Selector de Trimestre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trimestre:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    value: selectedQuarter,
                    items: [
                      const DropdownMenuItem(value: 1, child: Text('1er Trimestre')),
                      const DropdownMenuItem(value: 2, child: Text('2do Trimestre')),
                      const DropdownMenuItem(value: 3, child: Text('3er Trimestre')),
                      const DropdownMenuItem(value: 4, child: Text('4to Trimestre')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedQuarter = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSumasSection(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUMAS - ${_getQuarterOrdinal(selectedQuarter)} Trimestre $selectedYear',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tabla de Sumas
            _buildSumasTable(monthlyData, monthNames),
            const SizedBox(height: 24),
            
            // Gráfico de Sumas
            const SizedBox(height: 8), // Más espacio para el título
            _buildSumasChart(monthlyData, monthNames),
          ],
        ),
      ),
    );
  }

  Widget _buildPromediosSection(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROMEDIOS - ${_getQuarterOrdinal(selectedQuarter)} Trimestre $selectedYear',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tabla de Promedios
            _buildPromediosTable(monthlyData, monthNames),
            const SizedBox(height: 24),
            
            // Gráfico de Promedios
            const SizedBox(height: 8), // Más espacio para el título
            _buildPromediosChart(monthlyData, monthNames),
          ],
        ),
      ),
    );
  }

  Widget _buildSumasTable(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames) {
    // Calcular totales generales
    int totalTtlReal = 0;
    int totalTtlSemana = 0;
    int totalVisitas = 0;

    for (final monthName in monthNames) {
      final data = monthlyData[monthName] ?? {};
      totalTtlReal += (data['sumaTtlReal'] ?? 0) as int;
      totalTtlSemana += (data['sumaTtlSemana'] ?? 0) as int;
      totalVisitas += (data['sumaVisitas'] ?? 0) as int;
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // MES - más ancho
        1: FlexColumnWidth(1.5), // TTL REAL
        2: FlexColumnWidth(1.5), // TTL SEMANA  
        3: FlexColumnWidth(1.5), // VISITAS
      },
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('MES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('TTL\nREAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('TTL\nSEMANA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('VISITAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ],
        ),
        // Data rows
        ...monthNames.map((monthName) {
          final data = monthlyData[monthName] ?? {};
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(monthName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(child: _buildCellContainer(data['sumaTtlReal'] ?? 0, Colors.blue.shade100)),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(child: _buildCellContainer(data['sumaTtlSemana'] ?? 0, Colors.grey.shade200)),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(child: _buildCellContainer(data['sumaVisitas'] ?? 0, Colors.grey.shade300)),
              ),
            ],
          );
        }),
        // Total row
        TableRow(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.05)),
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Total general', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: _buildCellContainer(totalTtlReal, Colors.grey.shade200, bold: true)),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: _buildCellContainer(totalTtlSemana, Colors.grey.shade300, bold: true)),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: _buildCellContainer(totalVisitas, Colors.grey.shade400, bold: true)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromediosTable(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames) {
    // Calcular promedios generales
    int validMonths = 0;
    int totalPromedioReal = 0;
    int totalPromedioSemana = 0;
    int totalPromedioVisitas = 0;

    for (final monthName in monthNames) {
      final data = monthlyData[monthName] ?? {};
      if (data['weekCount'] > 0) {
        validMonths++;
        totalPromedioReal += (data['promedioTtlReal'] ?? 0) as int;
        totalPromedioSemana += (data['promedioTtlSemana'] ?? 0) as int;
        totalPromedioVisitas += (data['promedioVisitas'] ?? 0) as int;
      }
    }

    final promedioGeneral = validMonths > 0 ? {
      'real': (totalPromedioReal / validMonths).round(),
      'semana': (totalPromedioSemana / validMonths).round(),
      'visitas': (totalPromedioVisitas / validMonths).round(),
    } : {'real': 0, 'semana': 0, 'visitas': 0};

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // MES - más ancho
        1: FlexColumnWidth(1.5), // PROM REAL
        2: FlexColumnWidth(1.5), // PROM SEMANA  
        3: FlexColumnWidth(1.5), // PROM VISITAS
      },
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('MES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('PROM\nREAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('PROM\nSEMANA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('PROM\nVISITAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ],
        ),
        // Data rows
        ...monthNames.map((monthName) {
          final data = monthlyData[monthName] ?? {};
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(monthName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(child: _buildCellContainer(data['promedioTtlReal'] ?? 0, Colors.blue.shade100)),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(child: _buildCellContainer(data['promedioTtlSemana'] ?? 0, Colors.grey.shade200)),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(child: _buildCellContainer(data['promedioVisitas'] ?? 0, Colors.grey.shade300)),
              ),
            ],
          );
        }),
        // Total row
        TableRow(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.05)),
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Total general', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: _buildCellContainer(promedioGeneral['real']!, Colors.grey.shade200, bold: true)),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: _buildCellContainer(promedioGeneral['semana']!, Colors.grey.shade300, bold: true)),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: _buildCellContainer(promedioGeneral['visitas']!, Colors.grey.shade400, bold: true)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCellContainer(int value, Color color, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSumasChart(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames) {
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < monthNames.length; i++) {
      final monthName = monthNames[i];
      final data = monthlyData[monthName] ?? {};
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          showingTooltipIndicators: [0, 1, 2], // Mostrar tooltips para todas las barras
          barRods: [
            BarChartRodData(
              toY: (data['sumaTtlReal'] ?? 0).toDouble(),
              color: Colors.blue.shade600,
              width: 25, // Barras más anchas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: (data['sumaTtlSemana'] ?? 0).toDouble(),
              color: Colors.orange.shade600,
              width: 25, // Barras más anchas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: (data['sumaVisitas'] ?? 0).toDouble(),
              color: Colors.green.shade600,
              width: 25, // Barras más anchas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 320, // Altura aumentada para acomodar tooltips
      padding: const EdgeInsets.only(top: 30, bottom: 20, left: 16, right: 16), // Padding interno
      child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(monthlyData, monthNames, true),
          barTouchData: BarTouchData(
            enabled: false, // Tooltips siempre visibles
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white.withOpacity(0.9), // Fondo ligero
              tooltipBorder: BorderSide(color: Colors.grey.shade300, width: 1),
              tooltipRoundedRadius: 4,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final monthName = monthNames[group.x.toInt()];
                final data = monthlyData[monthName] ?? {};
                String value = '';
                Color color = Colors.black;
                
                switch (rodIndex) {
                  case 0:
                    value = '${data['sumaTtlReal'] ?? 0}';
                    color = Colors.blue.shade700;
                    break;
                  case 1:
                    value = '${data['sumaTtlSemana'] ?? 0}';
                    color = Colors.orange.shade700;
                    break;
                  case 2:
                    value = '${data['sumaVisitas'] ?? 0}';
                    color = Colors.green.shade700;
                    break;
                }
                return BarTooltipItem(
                  value,
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
                reservedSize: 30, // Espacio reservado para etiquetas
              getTitlesWidget: (value, meta) {
                if (value.toInt() < monthNames.length) {
                    return Text(
                      monthNames[value.toInt()], 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: () {
              final maxValue = _getMaxValue(monthlyData, monthNames, true);
              return maxValue > 100 ? (maxValue / 5).ceilToDouble() : 20.0; // Líneas de guía inteligentes
            }(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromediosChart(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames) {
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < monthNames.length; i++) {
      final monthName = monthNames[i];
      final data = monthlyData[monthName] ?? {};
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          showingTooltipIndicators: [0, 1, 2], // Mostrar tooltips para todas las barras
          barRods: [
            BarChartRodData(
              toY: (data['promedioTtlReal'] ?? 0).toDouble(),
              color: Colors.blue.shade600,
              width: 25, // Barras más anchas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: (data['promedioTtlSemana'] ?? 0).toDouble(),
              color: Colors.orange.shade600,
              width: 25, // Barras más anchas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: (data['promedioVisitas'] ?? 0).toDouble(),
              color: Colors.green.shade600,
              width: 25, // Barras más anchas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 320, // Altura aumentada para acomodar tooltips
      padding: const EdgeInsets.only(top: 30, bottom: 20, left: 16, right: 16), // Padding interno
      child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(monthlyData, monthNames, false),
          barTouchData: BarTouchData(
            enabled: false, // Tooltips siempre visibles
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white.withOpacity(0.9), // Fondo ligero
              tooltipBorder: BorderSide(color: Colors.grey.shade300, width: 1),
              tooltipRoundedRadius: 4,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final monthName = monthNames[group.x.toInt()];
                final data = monthlyData[monthName] ?? {};
                String value = '';
                Color color = Colors.black;
                
                switch (rodIndex) {
                  case 0:
                    value = '${data['promedioTtlReal'] ?? 0}';
                    color = Colors.blue.shade700;
                    break;
                  case 1:
                    value = '${data['promedioTtlSemana'] ?? 0}';
                    color = Colors.orange.shade700;
                    break;
                  case 2:
                    value = '${data['promedioVisitas'] ?? 0}';
                    color = Colors.green.shade700;
                    break;
                }
                return BarTooltipItem(
                  value,
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
                reservedSize: 30, // Espacio reservado para etiquetas
              getTitlesWidget: (value, meta) {
                if (value.toInt() < monthNames.length) {
                    return Text(
                      monthNames[value.toInt()], 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: () {
              final maxValue = _getMaxValue(monthlyData, monthNames, false);
              return maxValue > 100 ? (maxValue / 5).ceilToDouble() : 20.0; // Líneas de guía inteligentes
            }(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxValue(Map<String, Map<String, dynamic>> monthlyData, List<String> monthNames, bool isSumas) {
    double maxValue = 0;
    
    for (final monthName in monthNames) {
      final data = monthlyData[monthName] ?? {};
      if (isSumas) {
        final values = [
          maxValue,
          (data['sumaTtlReal'] ?? 0).toDouble(),
          (data['sumaTtlSemana'] ?? 0).toDouble(),
          (data['sumaVisitas'] ?? 0).toDouble(),
        ];
        if (values.any((v) => v > 0)) {
          maxValue = values.reduce((a, b) => a > b ? a : b);
        }
      } else {
        final values = [
          maxValue,
          (data['promedioTtlReal'] ?? 0).toDouble(),
          (data['promedioTtlSemana'] ?? 0).toDouble(),
          (data['promedioVisitas'] ?? 0).toDouble(),
        ];
        if (values.any((v) => v > 0)) {
          maxValue = values.reduce((a, b) => a > b ? a : b);
        }
      }
    }
    
    return maxValue > 0 ? maxValue * 1.2 : 10.0; // Añadir 20% de margen o valor por defecto
  }
} 