import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:asistencias_app/core/services/report_export_service.dart';
import 'package:intl/intl.dart';

class GenerateReportsScreen extends StatefulWidget {
  const GenerateReportsScreen({super.key});

  @override
  State<GenerateReportsScreen> createState() => _GenerateReportsScreenState();
}

class _GenerateReportsScreenState extends State<GenerateReportsScreen> {
  String selectedReportType = 'asistencia_general';
  String? selectedCityId;
  String? selectedCommuneId;
  DateTimeRange? selectedDateRange;
  bool _isLoading = true;
  bool _isGenerating = false;
  final ReportExportService _reportService = ReportExportService();

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
    
    // Cargar todas las comunas
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Generar Reportes'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final locationProvider = context.watch<LocationProvider>();
    final cities = locationProvider.cities;
    final communes = locationProvider.communes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Reportes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade600, Colors.blue.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.file_download,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Exportar Reportes CSV',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Genera reportes en bruto en formato CSV',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tipos de Reporte
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Tipo de Reporte',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReportOption('asistencia_general', 'Asistencia General', Icons.people, Colors.blue),
                      _buildReportOption('asistencia_sectores', 'Asistencia por Sectores', Icons.location_on, Colors.green),
                      _buildReportOption('ttl_semanal', 'TTL Semanal', Icons.calendar_view_week, Colors.orange),
                      _buildReportOption('visitas', 'Registro de Visitas', Icons.person_add, Colors.purple),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),



              // Filtros
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Selector de Ciudad
                      DropdownButtonFormField<String>(
                        value: selectedCityId,
                        decoration: InputDecoration(
                          labelText: 'Ciudad (Opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.location_city),
                        ),
                        hint: const Text('Todas las ciudades'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todas las ciudades'),
                          ),
                          ...cities.map((city) => DropdownMenuItem(
                            value: city.id,
                            child: Text(city.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCityId = value;
                            selectedCommuneId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Selector de Comuna/Ruta
                      DropdownButtonFormField<String>(
                        value: selectedCommuneId,
                        decoration: InputDecoration(
                          labelText: 'Ruta (Opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.route),
                        ),
                        hint: const Text('Todas las rutas'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todas las rutas'),
                          ),
                          ...communes
                              .where((c) => selectedCityId == null || c.cityId == selectedCityId)
                              .map((commune) => DropdownMenuItem(
                                value: commune.id,
                                child: Text(commune.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCommuneId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Selector de Fecha
                      InkWell(
                        onTap: () async {
                          final DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: selectedDateRange,
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDateRange = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rango de Fechas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      selectedDateRange != null
                                          ? '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'
                                          : 'Seleccionar período',
                                      style: TextStyle(
                                        color: selectedDateRange != null
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Generar
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: _isGenerating ? null : _generateReport,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: _isGenerating 
                            ? [Colors.grey.shade400, Colors.grey.shade300]
                            : [Colors.green.shade600, Colors.green.shade500],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isGenerating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          const Icon(Icons.download, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _isGenerating ? 'Generando...' : 'Generar CSV',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información adicional
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Información',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Los reportes se generan en tiempo real\n'
                        '• Los archivos se descargan automáticamente\n'
                        '• Formato CSV compatible con todas las aplicaciones\n'
                        '• Datos en bruto para análisis posterior',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(String value, String title, IconData icon, Color color) {
    final isSelected = selectedReportType == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => selectedReportType = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? color.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : Colors.black87,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    
    try {
      // Validar que se haya seleccionado un rango de fechas
      if (selectedDateRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un rango de fechas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Generar y exportar el reporte
      final filePath = await _reportService.generateAndExportReport(
        reportType: selectedReportType,
        cityId: selectedCityId,
        communeId: selectedCommuneId,
        dateRange: selectedDateRange!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte generado exitosamente: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                // Aquí podrías abrir el archivo o mostrar más información
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
} 