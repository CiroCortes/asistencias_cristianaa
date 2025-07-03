import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/core/services/admin_utilities_service.dart';

class AdminUtilitiesScreen extends StatefulWidget {
  const AdminUtilitiesScreen({super.key});

  @override
  State<AdminUtilitiesScreen> createState() => _AdminUtilitiesScreenState();
}

class _AdminUtilitiesScreenState extends State<AdminUtilitiesScreen> {
  final AdminUtilitiesService _utilitiesService = AdminUtilitiesService();
  
  void _showMessage(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _createTestAttendees() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;

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
                Text("Creando asistentes TEST..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final results = await _utilitiesService.createTestAttendees(
        onProgress: (message) => print('🔷 $message'),
        userEmail: currentUser?.email,
      );
      
      if (mounted) {
        Navigator.pop(context);
        _showMessage(
          '✅ Asistentes creados: ${results['attendees']} en ${results['sectors']} sectores',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('❌ Error: ${e.toString()}', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _createAttendanceRecords() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;

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
                Text("Creando registros de asistencia..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final results = await _utilitiesService.createAttendanceRecords(
        onProgress: (message) => print('🔷 $message'),
        userEmail: currentUser?.email,
      );
      
      if (mounted) {
        Navigator.pop(context);
        _showMessage(
          '✅ Registros creados: ${results['records']} para ${results['dates']} fechas',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('❌ Error: ${e.toString()}', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _cleanupData(String cleanupType) async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;
    
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
                Text("Ejecutando limpieza..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final results = await _utilitiesService.cleanupData(
        cleanupType: cleanupType,
        onProgress: (message) => print('🔷 $message'),
        userEmail: currentUser?.email,
      );
      
      if (mounted) {
        Navigator.pop(context);
        if (cleanupType == 'analyze') {
          _showMessage(
            '📊 Total: ${results['totalRecords']} registros, ${results['testRecords']} problemáticos',
            backgroundColor: Colors.blue,
          );
        } else {
          _showMessage(
            '✅ Eliminados: ${results['deletedRecords']} registros, ${results['deletedAttendees']} asistentes',
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('❌ Error: ${e.toString()}', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _analyzeAttendanceDiscrepancies() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;

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
                Text("Analizando discrepancias..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final results = await _utilitiesService.analyzeWeeklyAttendanceDiscrepancies(
        onProgress: (message) => print('🔍 $message'),
        userEmail: currentUser?.email,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        if (results.containsKey('error')) {
          _showMessage(
            '⚠️ ${results['error']}',
            backgroundColor: Colors.orange,
          );
        } else {
          final discrepancy = results['discrepancy'] ?? 0;
          final weekNumber = results['weekNumber'] ?? 0;
          
          if (discrepancy == 0) {
            _showMessage(
              '✅ Semana $weekNumber: Sin discrepancias encontradas',
              backgroundColor: Colors.green,
            );
          } else {
            _showMessage(
              '⚠️ Semana $weekNumber: ${discrepancy} personas en días incorrectos (Ver consola para detalles)',
              backgroundColor: Colors.orange,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('❌ Error: ${e.toString()}', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _cleanupIncorrectDayRecords({bool dryRun = true}) async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(dryRun ? "Simulando limpieza..." : "Limpiando registros..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final results = await _utilitiesService.cleanupIncorrectDayRecords(
        onProgress: (message) => print('🧹 $message'),
        userEmail: currentUser?.email,
        dryRun: dryRun,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        if (results.containsKey('error')) {
          _showMessage(
            '⚠️ ${results['error']}',
            backgroundColor: Colors.orange,
          );
        } else {
          final incorrectRecords = results['incorrectDayRecords'] ?? 0;
          final deletedRecords = results['deletedRecords'] ?? 0;
          final deletedAttendance = results['deletedAttendance'] ?? 0;
          final weekNumber = results['weekNumber'] ?? 0;
          
          if (incorrectRecords == 0) {
            _showMessage(
              '✅ Semana $weekNumber: No hay registros en días incorrectos',
              backgroundColor: Colors.green,
            );
          } else if (dryRun) {
            _showMessage(
              '🔍 Simulación: $incorrectRecords registros ($deletedAttendance personas) serían eliminados',
              backgroundColor: Colors.blue,
            );
          } else {
            _showMessage(
              '✅ Limpieza completada: $deletedRecords registros ($deletedAttendance personas) eliminados',
              backgroundColor: Colors.green,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('❌ Error: ${e.toString()}', backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;

    // Verificar acceso - Solo ciro.720@gmail.com
    if (currentUser?.email != 'ciro.720@gmail.com') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Restringido'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Acceso Denegado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Esta sección de utilidades de administrador está restringida a usuarios autorizados únicamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilidades de Administrador'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group_add, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Crear Asistentes TEST',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Crea 10 asistentes TEST para cada sector de Quilicura (80 asistentes total).',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('👥 Crear Asistentes TEST'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Esto creará en la ruta QUILICURA:'),
                                SizedBox(height: 8),
                                Text('• 10 asistentes TEST por sector'),
                                Text('• Total esperado: ~80 asistentes'),
                                Text('• Nombres y datos simulados'),
                                SizedBox(height: 16),
                                Text('⚠️ Verificará que no existan asistentes TEST previos', 
                                     style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('👥 Crear'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await _createTestAttendees();
                        }
                      },
                      icon: const Icon(Icons.group_add),
                      label: const Text('Crear Asistentes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Crear Registros de Asistencia',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Genera registros de asistencia para junio-julio 2025 (16 semanas completas con validación).',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('📊 Crear Registros de Asistencia'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Esto creará registros para jun-jul 2025:'),
                                SizedBox(height: 8),
                                Text('• 35 fechas de reuniones programadas'),
                                Text('• 4 tipos de reuniones por semana'),
                                Text('• Asistencia realista (60-85%)'),
                                Text('• Validación de máximo de registros'),
                                SizedBox(height: 16),
                                Text('🛡️ Requiere asistentes TEST creados previamente', 
                                     style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('📊 Crear'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await _createAttendanceRecords();
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Crear Registros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cleaning_services, color: Colors.red.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Limpiar Datos Inconsistentes',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Elimina registros malformados, datos TEST o realiza una limpieza completa de la base de datos.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _cleanupData('analyze'),
                            icon: const Icon(Icons.analytics),
                            label: const Text('Analizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _cleanupData('test'),
                            icon: const Icon(Icons.science),
                            label: const Text('Solo TEST'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('⚠️ Limpieza Completa'),
                                  content: const Text(
                                    'Esto eliminará TODOS los registros de asistencia. Esta acción no se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Confirmar'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await _cleanupData('full');
                              }
                            },
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Completa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Analizar Discrepancias de Asistencia',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Analiza por qué los KPIs del dashboard no coinciden. Identifica registros en días incorrectos.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('🔍 Analizar Discrepancias'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Este análisis identificará:'),
                                SizedBox(height: 8),
                                Text('• Registros en días incorrectos (lunes-viernes)'),
                                Text('• Diferencias entre KPIs del dashboard'),
                                Text('• Distribución por día de la semana'),
                                Text('• Detalles de registros problemáticos'),
                                SizedBox(height: 16),
                                Text('📊 Los resultados aparecen en la consola de debug', 
                                     style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('🔍 Analizar'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await _analyzeAttendanceDiscrepancies();
                        }
                      },
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Analizar Discrepancias'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cleaning_services, color: Colors.purple.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Limpiar Registros en Días Incorrectos',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Elimina registros de asistencia que están en días incorrectos (lunes, martes, jueves, viernes). Solo mantiene miércoles, sábados y domingos.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('🔍 Simular Limpieza'),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Esta simulación mostrará:'),
                                      SizedBox(height: 8),
                                      Text('• Registros que serían eliminados'),
                                      Text('• Total de personas afectadas'),
                                      Text('• Detalles de cada registro'),
                                      SizedBox(height: 16),
                                      Text('🛡️ NO se eliminará nada, solo simulación', 
                                           style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('🔍 Simular'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await _cleanupIncorrectDayRecords(dryRun: true);
                              }
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Simular'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('⚠️ Limpiar Registros Incorrectos'),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Esta acción eliminará:'),
                                      SizedBox(height: 8),
                                      Text('• Registros en lunes, martes, jueves, viernes'),
                                      Text('• Solo mantendrá miércoles, sábados, domingos'),
                                      Text('• Los registros eliminados NO se pueden recuperar'),
                                      SizedBox(height: 16),
                                      Text('⚠️ Esta acción es irreversible', 
                                           style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('🧹 Limpiar'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await _cleanupIncorrectDayRecords(dryRun: false);
                              }
                            },
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Limpiar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Analizar: Revisa los datos sin eliminar nada (seguro)\n'
                      '• Solo TEST: Elimina únicamente registros de prueba\n'
                      '• Completa: Elimina TODOS los registros de asistencia\n'
                      '• Discrepancias: Encuentra registros en días incorrectos\n'
                      '• Limpiar Días Incorrectos: Elimina registros en lunes-viernes\n'
                      '• Los logs detallados aparecen en la consola de debug',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 