import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/meeting_provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/recurring_meeting_model.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:asistencias_app/core/constants/app_constants.dart'; // Para los días de la semana

class CreateRecurringMeetingScreen extends StatefulWidget {
  const CreateRecurringMeetingScreen({super.key});

  @override
  State<CreateRecurringMeetingScreen> createState() => _CreateRecurringMeetingScreenState();
}

class _CreateRecurringMeetingScreenState extends State<CreateRecurringMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();

  List<String> _selectedDays = [];
  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;

  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadCities();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona al menos un día.')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una hora.')),
      );
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una localidad.')),
      );
      return;
    }

    final meetingProvider = context.read<MeetingProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado.')),
      );
      return;
    }

    final newMeeting = RecurringMeetingModel(
      name: _nameController.text,
      daysOfWeek: _selectedDays,
      time: _timeController.text,
      locationId: _selectedLocation!.id,
      createdByUserId: currentUser.uid,
      createdAt: DateTime.now(),
    );

    await meetingProvider.addRecurringMeeting(newMeeting);

    if (mounted && meetingProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reunión recurrente creada exitosamente.')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${meetingProvider.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final meetingProvider = context.watch<MeetingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reunión Recurrente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Reunión',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre para la reunión';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selector de Días de la Semana
              const Text('Días de la Semana:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: AppConstants.daysOfWeek.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Hora de la Reunión',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una hora';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selectores de Ubicación en cascada
              const Text('Ubicación:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<City>(
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCity,
                items: locationProvider.cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city.name));
                }).toList(),
                onChanged: (City? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                    _selectedCommune = null;
                    _selectedLocation = null;
                  });
                  if (newValue != null) {
                    locationProvider.loadCommunes(newValue.id);
                  }
                },
                validator: (value) {
                  if (value == null) return 'Selecciona una ciudad';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Commune>(
                decoration: const InputDecoration(
                  labelText: 'Comuna',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCommune,
                items: locationProvider.communes.map((commune) {
                  return DropdownMenuItem(value: commune, child: Text(commune.name));
                }).toList(),
                onChanged: (Commune? newValue) {
                  setState(() {
                    _selectedCommune = newValue;
                    _selectedLocation = null;
                  });
                  if (newValue != null) {
                    locationProvider.loadLocations(newValue.id);
                  }
                },
                validator: (value) {
                  if (value == null) return 'Selecciona una comuna';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Location>(
                decoration: const InputDecoration(
                  labelText: 'Localidad',
                  border: OutlineInputBorder(),
                ),
                value: _selectedLocation,
                items: locationProvider.locations.map((location) {
                  return DropdownMenuItem(value: location, child: Text(location.name));
                }).toList(),
                onChanged: (Location? newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Selecciona una localidad';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _createMeeting,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: meetingProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Crear Reunión', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 