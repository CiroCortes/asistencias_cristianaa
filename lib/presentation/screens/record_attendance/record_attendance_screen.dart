import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/meeting_provider.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/data/models/recurring_meeting_model.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/data/models/attendance_record_model.dart';
import 'package:asistencias_app/core/services/attendance_record_service.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordAttendanceScreen extends StatefulWidget {
  const RecordAttendanceScreen({super.key});

  @override
  State<RecordAttendanceScreen> createState() => _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState extends State<RecordAttendanceScreen> {
  String? _selectedMeetingId;
  RecurringMeetingModel? _selectedMeeting;
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedAttendeeIds = [];
  int _visitorCount = 0;
  final AttendanceRecordService _attendanceRecordService =
      AttendanceRecordService();

  // Para admin: selección de ciudad, comuna y sector
  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;

  String? _sectorName; // Para mostrar el nombre del sector asignado
  bool _loadingSectorName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.user;
      final locationProvider = context.read<LocationProvider>();
      if (userProvider.isAdmin) {
        locationProvider.loadCities();
      } else if (currentUser != null && currentUser.sectorId != null) {
        _fetchSectorName(currentUser.sectorId!);
      }
    });
  }

  Future<void> _fetchSectorName(String sectorId) async {
    setState(() {
      _loadingSectorName = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('locations')
          .doc(sectorId)
          .get();
      if (doc.exists) {
        setState(() {
          _sectorName = doc.data()!["name"] ?? sectorId;
        });
      } else {
        setState(() {
          _sectorName = sectorId;
        });
      }
    } catch (_) {
      setState(() {
        _sectorName = sectorId;
      });
    } finally {
      setState(() {
        _loadingSectorName = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
          DateTime.now().second,
        );
      });
    }
  }

  void _addVisitor() {
    setState(() {
      _visitorCount++;
    });
  }

  void _removeVisitor() {
    if (_visitorCount > 0) {
      setState(() {
        _visitorCount--;
      });
    }
  }

  /// Combina la fecha seleccionada con la hora del evento seleccionado
  /// Esto resuelve el problema de AM/PM para registros históricos
  DateTime _combineSelectedDateWithEventTime() {
    if (_selectedMeeting == null) {
      return _selectedDate; // Fallback a fecha original si no hay evento
    }

    try {
      // Parsear la hora del evento (formato "HH:MM")
      final timeParts = _selectedMeeting!.time.split(':');
      if (timeParts.length != 2) {
        print('⚠️ Formato de hora inválido: ${_selectedMeeting!.time}');
        return _selectedDate;
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Combinar fecha seleccionada + hora del evento
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );
    } catch (e) {
      print('❌ Error al combinar fecha y hora del evento: $e');
      return _selectedDate; // Fallback a fecha original en caso de error
    }
  }

  /// Valida que el día de la semana corresponda al tipo de reunión
  /// Retorna true si es válido, false si hay discrepancia
  bool _validateMeetingDayOfWeek() {
    if (_selectedMeeting == null) return true;

    final eventDateTime = _combineSelectedDateWithEventTime();
    final selectedWeekday = eventDateTime.weekday;

    // NUEVA LÓGICA: Usar daysOfWeek del modelo de reunión
    final weekdayNames = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final selectedDayName = weekdayNames[selectedWeekday];

    // Verificar si el día seleccionado está en los días configurados de la reunión
    final isValidDay = _selectedMeeting!.daysOfWeek.contains(selectedDayName);

    // Debug: Mostrar información de validación
    print('🔍 Validación de día:');
    print('   Reunión: ${_selectedMeeting!.name}');
    print('   Días configurados: ${_selectedMeeting!.daysOfWeek}');
    print('   Día seleccionado: $selectedDayName');
    print('   Es válido: $isValidDay');

    return isValidDay;
  }

  /// Muestra un diálogo de advertencia cuando el día no coincide
  void _showDayMismatchWarning() {
    if (_selectedMeeting == null) return;

    final eventDateTime = _combineSelectedDateWithEventTime();
    final selectedWeekday = eventDateTime.weekday;
    final meetingName = _selectedMeeting!.name;

    // Obtener nombres de días
    final weekdayNames = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final selectedDayName = weekdayNames[selectedWeekday];

    // NUEVA LÓGICA: Usar daysOfWeek para mostrar los días correctos
    final expectedDays = _selectedMeeting!.daysOfWeek;
    final expectedDaysText = expectedDays.join(', ');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Día Incorrecto'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Has seleccionado "$meetingName" pero la fecha es $selectedDayName.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Las reuniones "$meetingName" deben registrarse en: $expectedDaysText',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Por favor corrige la fecha para que coincida con uno de los días correctos.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  bool _canSubmit(UserProvider userProvider) {
    final currentUser = userProvider.user;

    // Validar que el usuario está autenticado
    if (currentUser == null) {
      return false;
    }

    // Para usuario normal: validar que tenga sector asignado
    if (!userProvider.isAdmin && currentUser.sectorId == null) {
      return false;
    }

    // Validar que hay un evento seleccionado
    if (_selectedMeeting == null) {
      return false;
    }

    // Validar que hay al menos un asistente o una visita
    if (_selectedAttendeeIds.isEmpty && _visitorCount == 0) {
      return false;
    }

    // Si es admin, validar que hay un sector seleccionado
    if (userProvider.isAdmin && _selectedLocation == null) {
      return false;
    }

    return true;
  }

  Widget _buildNoAttendeesMessage(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            userProvider.isAdmin
                ? 'No hay asistentes en el sector seleccionado.\nSelecciona una ciudad, comuna y sector válidos.'
                : 'No hay asistentes registrados en tu sector.\nContacta al administrador para agregar asistentes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (!userProvider.isAdmin)
            Text(
              'Sector asignado: ${_sectorName ?? 'Cargando...'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _recordAttendance() async {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: Usuario no autenticado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!userProvider.isAdmin && currentUser.sectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: Usuario sin sector asignado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // NUEVA VALIDACIÓN: Verificar que el día de la semana sea correcto
    if (!_validateMeetingDayOfWeek()) {
      _showDayMismatchWarning();
      return; // No proceder con el guardado
    }

    try {
      String sectorId;
      if (userProvider.isAdmin) {
        if (_selectedLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('⚠️ Por favor selecciona una ciudad, comuna y sector.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        sectorId = _selectedLocation!.id;
      } else {
        sectorId = currentUser.sectorId!;
      }

      // Combinar fecha seleccionada con hora real del evento
      final eventDateTime = _combineSelectedDateWithEventTime();

      // Debug: Mostrar la diferencia entre fecha seleccionada y fecha final
      // print('🔍 DEBUG - Registro de Asistencia:');
      // print('   Fecha seleccionada: ${_selectedDate}');
      // print('   Evento: ${_selectedMeeting!.name} (${_selectedMeeting!.time})');
      // print('   Fecha final (evento): ${eventDateTime}');
      // print('   AM/PM resultante: ${eventDateTime.hour < 14 ? "AM" : "PM"}');

      final record = AttendanceRecordModel(
        sectorId: sectorId,
        date: eventDateTime, // ← Usar fecha/hora combinada del evento
        meetingType: _selectedMeeting!.meetingType, // Usar meetingType para KPI
        attendedAttendeeIds: _selectedAttendeeIds,
        visitorCount: _visitorCount,
        recordedByUserId: currentUser.uid,
      );
      await _attendanceRecordService.addAttendanceRecord(record);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Asistencia registrada exitosamente - ${_selectedAttendeeIds.length} asistentes + $_visitorCount visitas'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      // Limpiar el formulario
      setState(() {
        _selectedMeeting = null;
        _selectedAttendeeIds = [];
        _visitorCount = 0;
        _selectedDate = DateTime.now();
        if (userProvider.isAdmin) {
          _selectedCity = null;
          _selectedCommune = null;
          _selectedLocation = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al registrar asistencia: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingProvider = context.watch<MeetingProvider>();
    final attendeeProvider = context.watch<AttendeeProvider>();
    final userProvider = context.watch<UserProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final currentUser = userProvider.user;

    // --- Lógica de asistentes filtrados ---
    List<AttendeeModel> filteredAttendees = [];
    if (currentUser != null) {
      if (userProvider.isAdmin) {
        if (_selectedLocation != null) {
          filteredAttendees = attendeeProvider.attendees
              .where((att) => att.sectorId == _selectedLocation!.id)
              .toList();
        }
      } else if (currentUser.sectorId != null) {
        filteredAttendees = attendeeProvider.attendees
            .where((att) => att.sectorId == currentUser.sectorId)
            .toList();
      }
    }

    // Validar que los valores seleccionados existen en las listas disponibles
    if (userProvider.isAdmin) {
      if (_selectedCity != null &&
          !locationProvider.cities
              .any((city) => city.id == _selectedCity!.id)) {
        _selectedCity = null;
        _selectedCommune = null;
        _selectedLocation = null;
      }
      if (_selectedCommune != null &&
          !locationProvider.communes
              .any((commune) => commune.id == _selectedCommune!.id)) {
        _selectedCommune = null;
        _selectedLocation = null;
      }
      if (_selectedLocation != null &&
          !locationProvider.locations
              .any((location) => location.id == _selectedLocation!.id)) {
        _selectedLocation = null;
      }
    }

    // Validación para usuarios no aprobados (especialmente importante para usuarios normales)
    if (currentUser != null &&
        !currentUser.isApproved &&
        !userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ingresar Asistencias')),
        body: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pending_actions,
                  size: 64, color: Colors.orange.shade600),
              const SizedBox(height: 16),
              Text(
                'Cuenta Pendiente de Aprobación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tu cuenta está pendiente de aprobación por un administrador. Una vez aprobada, podrás registrar asistencias.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al Inicio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (meetingProvider.isLoading ||
        attendeeProvider.isLoading ||
        locationProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ingresar Asistencias')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (meetingProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ingresar Asistencias')),
        body: Center(
            child: Text(
                'Error al cargar eventos: ${meetingProvider.errorMessage}')),
      );
    }
    if (attendeeProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ingresar Asistencias')),
        body: Center(
            child: Text(
                'Error al cargar asistentes: ${attendeeProvider.errorMessage}')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresar Asistencias'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _canSubmit(userProvider) ? _recordAttendance : null,
        backgroundColor: _canSubmit(userProvider) ? null : Colors.grey,
        tooltip: 'Registrar Asistencia',
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 18),
            Text(
              'Guardar',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Mejor posicionamiento
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Dropdowns de ciudad, comuna y sector solo para admin ---
            if (userProvider.isAdmin) ...[
              const Text('Seleccionar Ciudad:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<City>(
                decoration: const InputDecoration(
                    labelText: 'Ciudad', border: OutlineInputBorder()),
                value: _selectedCity,
                items: locationProvider.cities
                    .map((city) => DropdownMenuItem<City>(
                        value: city, child: Text(city.name)))
                    .toList(),
                onChanged: (city) async {
                  setState(() {
                    _selectedCity = city;
                    _selectedCommune = null;
                    _selectedLocation = null;
                  });
                  if (city != null)
                    await locationProvider.loadCommunes(city.id);
                },
              ),
              const SizedBox(height: 12),
              const Text('Seleccionar Comuna:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Commune>(
                decoration: const InputDecoration(
                    labelText: 'Comuna', border: OutlineInputBorder()),
                value: _selectedCommune,
                items: locationProvider.communes
                    .map((commune) => DropdownMenuItem<Commune>(
                        value: commune, child: Text(commune.name)))
                    .toList(),
                onChanged: (commune) async {
                  setState(() {
                    _selectedCommune = commune;
                    _selectedLocation = null;
                  });
                  if (commune != null)
                    await locationProvider.loadLocations(commune.id);
                },
              ),
              const SizedBox(height: 12),
              const Text('Seleccionar Sector:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Location>(
                decoration: const InputDecoration(
                    labelText: 'Sector', border: OutlineInputBorder()),
                value: _selectedLocation,
                items: locationProvider.locations
                    .map((loc) => DropdownMenuItem<Location>(
                        value: loc, child: Text(loc.name)))
                    .toList(),
                onChanged: (loc) {
                  setState(() {
                    _selectedLocation = loc;
                  });
                },
              ),
              const SizedBox(height: 20),
            ] else if (currentUser != null && currentUser.sectorId != null) ...[
              // Mostrar info del sector si se desea
              const Text('Sector asignado:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _loadingSectorName
                  ? const CircularProgressIndicator()
                  : Text(_sectorName ?? currentUser.sectorId ?? '',
                      style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
            const Text(
              'Seleccionar Evento Recurrente:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Evento',
                border: OutlineInputBorder(),
              ),
              value: _selectedMeetingId,
              items: meetingProvider.recurringMeetings.map((meeting) {
                return DropdownMenuItem(
                  value: meeting.id,
                  child: Text(meeting.name),
                );
              }).toList(),
              onChanged: (newId) {
                setState(() {
                  _selectedMeetingId = newId;
                  _selectedMeeting = meetingProvider.recurringMeetings
                      .firstWhere((m) => m.id == newId);
                });
              },
              validator: (value) {
                if (value == null) return 'Por favor selecciona un evento';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Fecha de Asistencia:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text:
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Asistentes Presentes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _removeVisitor,
                      color: Colors.red,
                    ),
                    Text(
                      '$_visitorCount',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _addVisitor,
                      color: Colors.green,
                    ),
                    const Text('Visitas'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            filteredAttendees.isEmpty
                ? _buildNoAttendeesMessage(userProvider)
                : SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredAttendees.length,
                      itemBuilder: (context, index) {
                        final attendee = filteredAttendees[index];
                        if (!attendee.isActive) return const SizedBox.shrink();

                        String typeText = '';
                        Color typeColor = Colors.grey;

                        switch (attendee.type) {
                          case 'member':
                            typeText = 'Miembro';
                            typeColor = Colors.blue;
                            break;
                          case 'listener':
                            typeText = 'Oyente';
                            typeColor = Colors.green;
                            break;
                          case 'visitor':
                            typeText = 'Visita';
                            typeColor = Colors.orange;
                            break;
                        }

                        final isSelected =
                            _selectedAttendeeIds.contains(attendee.id);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          color:
                              isSelected ? Colors.blue.withOpacity(0.1) : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: typeColor,
                              child: Text(
                                (attendee.name != null &&
                                        attendee.name!.isNotEmpty)
                                    ? attendee.name![0].toUpperCase()
                                    : typeText[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              (attendee.name != null &&
                                      attendee.name!.isNotEmpty)
                                  ? '${attendee.name!} ${attendee.lastName ?? ''}'
                                  : '$typeText - ${attendee.id!.substring(0, 4)}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (attendee.contactInfo != null &&
                                    attendee.contactInfo!.isNotEmpty)
                                  Text(attendee.contactInfo!),
                                Text(
                                  'Tipo: $typeText',
                                  style:
                                      TextStyle(fontSize: 12, color: typeColor),
                                ),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedAttendeeIds.add(attendee.id!);
                                  } else {
                                    _selectedAttendeeIds.remove(attendee.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (_selectedAttendeeIds
                                    .contains(attendee.id)) {
                                  _selectedAttendeeIds.remove(attendee.id);
                                } else {
                                  _selectedAttendeeIds.add(attendee.id!);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(
                height:
                    120), // Más espacio para el FloatingActionButton (levantado)
          ],
        ),
      ),
    );
  }
}
