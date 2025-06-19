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
import 'package:asistencias_app/core/services/location_service.dart';
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
  final AttendanceRecordService _attendanceRecordService = AttendanceRecordService();

  // Para admin: selección de ciudad, comuna y sector
  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;

  String? _sectorName; // Para mostrar el nombre del sector asignado
  bool _loadingSectorName = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;
    final locationProvider = context.read<LocationProvider>();
    if (userProvider.isAdmin) {
      locationProvider.loadCities();
    } else if (currentUser != null && currentUser.sectorId != null) {
      _fetchSectorName(currentUser.sectorId!);
    }
  }

  Future<void> _fetchSectorName(String sectorId) async {
    setState(() { _loadingSectorName = true; });
    try {
      final doc = await FirebaseFirestore.instance.collection('locations').doc(sectorId).get();
      if (doc.exists) {
        setState(() {
          _sectorName = doc.data()!["name"] ?? sectorId;
        });
      } else {
        setState(() { _sectorName = sectorId; });
      }
    } catch (_) {
      setState(() { _sectorName = sectorId; });
    } finally {
      setState(() { _loadingSectorName = false; });
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

  void _recordAttendance() async {
    if (_selectedMeeting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un evento.')),
      );
      return;
    }
    if (_selectedAttendeeIds.isEmpty && _visitorCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona al menos un asistente o agrega una visita.')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      return;
    }

    // Si no es admin, verificar que tenga sector asignado
    if (!userProvider.isAdmin && currentUser.sectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario sin sector asignado.')),
      );
      return;
    }

    try {
      String sectorId;
      if (userProvider.isAdmin) {
        if (_selectedLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor selecciona un sector.')),
          );
          return;
        }
        sectorId = _selectedLocation!.id;
      } else {
        sectorId = currentUser.sectorId!;
      }

      final record = AttendanceRecordModel(
        sectorId: sectorId,
        date: _selectedDate,
        meetingType: _selectedMeeting!.name,
        attendedAttendeeIds: _selectedAttendeeIds,
        visitorCount: _visitorCount,
        recordedByUserId: currentUser.uid,
      );
      await _attendanceRecordService.addAttendanceRecord(record);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia registrada exitosamente.')),
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
        SnackBar(content: Text('Error al registrar asistencia: $e')),
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
          filteredAttendees = attendeeProvider.attendees.where((att) => att.sectorId == _selectedLocation!.id).toList();
        }
      } else if (currentUser.sectorId != null) {
        filteredAttendees = attendeeProvider.attendees.where((att) => att.sectorId == currentUser.sectorId).toList();
      }
    }

    if (meetingProvider.isLoading || attendeeProvider.isLoading || locationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (meetingProvider.errorMessage != null) {
      return Center(child: Text('Error al cargar eventos: ${meetingProvider.errorMessage}'));
    }
    if (attendeeProvider.errorMessage != null) {
      return Center(child: Text('Error al cargar asistentes: ${attendeeProvider.errorMessage}'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresar Asistencias'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Dropdowns de ciudad, comuna y sector solo para admin ---
            if (userProvider.isAdmin) ...[
              const Text('Seleccionar Ciudad:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<City>(
                decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
                value: _selectedCity,
                items: locationProvider.cities.map((city) => DropdownMenuItem<City>(value: city, child: Text(city.name))).toList(),
                onChanged: (city) async {
                  setState(() {
                    _selectedCity = city;
                    _selectedCommune = null;
                    _selectedLocation = null;
                  });
                  if (city != null) await locationProvider.loadCommunes(city.id);
                },
              ),
              const SizedBox(height: 12),
              const Text('Seleccionar Comuna:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Commune>(
                decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
                value: _selectedCommune,
                items: locationProvider.communes.map((commune) => DropdownMenuItem<Commune>(value: commune, child: Text(commune.name))).toList(),
                onChanged: (commune) async {
                  setState(() {
                    _selectedCommune = commune;
                    _selectedLocation = null;
                  });
                  if (commune != null) await locationProvider.loadLocations(commune.id);
                },
              ),
              const SizedBox(height: 12),
              const Text('Seleccionar Sector:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Location>(
                decoration: const InputDecoration(labelText: 'Sector', border: OutlineInputBorder()),
                value: _selectedLocation,
                items: locationProvider.locations.map((loc) => DropdownMenuItem<Location>(value: loc, child: Text(loc.name))).toList(),
                onChanged: (loc) {
                  setState(() {
                    _selectedLocation = loc;
                  });
                },
              ),
              const SizedBox(height: 20),
            ] else if (currentUser != null && currentUser.sectorId != null) ...[
              // Mostrar info del sector si se desea
              const Text('Sector asignado:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _loadingSectorName
                ? const CircularProgressIndicator()
                : Text(_sectorName ?? currentUser.sectorId ?? '', style: const TextStyle(fontSize: 16)),
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
                  _selectedMeeting = meetingProvider.recurringMeetings.firstWhere((m) => m.id == newId);
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
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                ? const Text('No hay asistentes disponibles en tu sector.')
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

                        final isSelected = _selectedAttendeeIds.contains(attendee.id);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: typeColor,
                              child: Text(
                                (attendee.name != null && attendee.name!.isNotEmpty)
                                    ? attendee.name![0].toUpperCase()
                                    : typeText[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              (attendee.name != null && attendee.name!.isNotEmpty)
                                  ? '${attendee.name!} ${attendee.lastName ?? ''}'
                                  : '$typeText - ${attendee.id!.substring(0, 4)}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (attendee.contactInfo != null && attendee.contactInfo!.isNotEmpty)
                                  Text(attendee.contactInfo!),
                                Text(
                                  'Tipo: $typeText',
                                  style: TextStyle(fontSize: 12, color: typeColor),
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
                                if (_selectedAttendeeIds.contains(attendee.id)) {
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
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _recordAttendance,
                child: const Text('Registrar Asistencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 