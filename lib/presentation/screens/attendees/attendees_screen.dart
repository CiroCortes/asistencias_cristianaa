import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/attendee_provider.dart';
import 'package:asistencias_app/data/models/attendee_model.dart';
import 'package:asistencias_app/core/providers/user_provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendeesScreen extends StatefulWidget {
  const AttendeesScreen({super.key});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactInfoController = TextEditingController();

  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;
  String _selectedType = 'member';
  bool _isAttendeeActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.isAdmin) {
        context.read<LocationProvider>().loadCities();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveAttendee([AttendeeModel? existingAttendee]) async {
    if (!_formKey.currentState!.validate()) return;

    final attendeeProvider = context.read<AttendeeProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = FirebaseAuth.instance.currentUser;

    String? assignedSectorId;

    if (userProvider.isAdmin) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Por favor selecciona una localidad.')),
        );
        return;
      }
      assignedSectorId = _selectedLocation!.id;
    } else {
      if (userProvider.user == null || userProvider.user!.sectorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado o sin sector asignado.')),
        );
        return;
      }
      assignedSectorId = userProvider.user!.sectorId!;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      return;
    }

    AttendeeModel attendeeToSave = AttendeeModel(
      id: existingAttendee?.id,
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      type: _selectedType,
      sectorId: assignedSectorId!,
      contactInfo: _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim(),
      createdAt: existingAttendee?.createdAt ?? DateTime.now(),
      createdByUserId: existingAttendee?.createdByUserId ?? currentUser.uid,
      isActive: _isAttendeeActive,
    );

    if (existingAttendee == null) {
      await attendeeProvider.addAttendee(attendeeToSave);
      if (mounted && attendeeProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistente agregado exitosamente.')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar: ${attendeeProvider.errorMessage}')),
        );
      }
    } else {
      attendeeToSave = AttendeeModel(
        id: existingAttendee.id,
        name: attendeeToSave.name,
        lastName: attendeeToSave.lastName,
        type: _selectedType,
        sectorId: assignedSectorId!,
        contactInfo: attendeeToSave.contactInfo,
        createdAt: existingAttendee.createdAt,
        createdByUserId: existingAttendee.createdByUserId,
        isActive: _isAttendeeActive,
      );
      await attendeeProvider.updateAttendee(attendeeToSave);
      if (mounted && attendeeProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistente actualizado exitosamente.')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: ${attendeeProvider.errorMessage}')),
        );
      }
    }
  }

  void _showAddEditAttendeeDialog([AttendeeModel? attendeeToEdit]) {
    _formKey.currentState?.reset();
    _nameController.clear();
    _lastNameController.clear();
    _contactInfoController.clear();

    final userProvider = context.read<UserProvider>();

    if (attendeeToEdit != null) {
      _nameController.text = attendeeToEdit.name ?? '';
      _lastNameController.text = attendeeToEdit.lastName ?? '';
      _contactInfoController.text = attendeeToEdit.contactInfo ?? '';
      _selectedType = attendeeToEdit.type;
      _isAttendeeActive = attendeeToEdit.isActive;

      if (userProvider.isAdmin && attendeeToEdit.sectorId != null) {
        context.read<LocationProvider>().loadCities().then((_) {
          final locationProvider = context.read<LocationProvider>();
          final initialLocation = locationProvider.locations.firstWhereOrNull(
              (loc) => loc.id == attendeeToEdit.sectorId);
          if (initialLocation != null) {
            setState(() {
              _selectedLocation = initialLocation;
              _selectedCommune = locationProvider.communes.firstWhereOrNull(
                  (comm) => comm.id == initialLocation.communeId);
              _selectedCity = locationProvider.cities.firstWhereOrNull(
                  (city) => city.id == _selectedCommune?.cityId);
            });
            if (_selectedCommune != null) {
              locationProvider.loadCommunes(_selectedCity!.id).then((_) {
                locationProvider.loadLocations(_selectedCommune!.id);
              });
            }
          }
        });
      }
    } else {
      _selectedType = 'member';
      if (userProvider.isAdmin) {
        setState(() {
          _selectedCity = null;
          _selectedCommune = null;
          _selectedLocation = null;
        });
        context.read<LocationProvider>().loadCities();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final locationProvider = context.watch<LocationProvider>();

        return AlertDialog(
          title: Text(attendeeToEdit == null ? 'Añadir Nuevo Asistente' : 'Editar Asistente'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Asistente',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'member', child: Text('Miembro')),
                      DropdownMenuItem(value: 'listener', child: Text('Oyente')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Selecciona un tipo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) {
                      if (_selectedType == 'member' && (value == null || value.isEmpty)) {
                        return 'Por favor ingrese el nombre del miembro';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: (value) {
                      if (_selectedType == 'member' && (value == null || value.isEmpty)) {
                        return 'Por favor ingrese el apellido del miembro';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactInfoController,
                    decoration: const InputDecoration(labelText: 'Información de Contacto (Opcional)'),
                  ),
                  const SizedBox(height: 16),
                  if (userProvider.isAdmin) ...[
                    const Text('Ubicación del Asistente:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        if (userProvider.isAdmin && value == null) return 'Selecciona una ciudad';
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
                        if (userProvider.isAdmin && value == null) return 'Selecciona una comuna';
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
                        if (userProvider.isAdmin && value == null) return 'Selecciona una localidad';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Text('Asistente será asignado al sector:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      userProvider.user?.sectorId ?? 'N/A',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (attendeeToEdit != null) ...[
                    SwitchListTile(
                      title: const Text('Activo'),
                      value: _isAttendeeActive,
                      onChanged: (bool newValue) {
                        setState(() {
                          _isAttendeeActive = newValue;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _saveAttendee(attendeeToEdit),
              child: Text(attendeeToEdit == null ? 'Añadir' : 'Guardar Cambios'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isUserApproved = userProvider.user?.isApproved ?? false;

    if (!isUserApproved) {
      return const Center(
        child: Text('Tu cuenta no ha sido aprobada para gestionar asistentes.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Asistentes'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AttendeeProvider>(
              builder: (context, attendeeProvider, child) {
                if (attendeeProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (attendeeProvider.errorMessage != null) {
                  return Center(
                      child: Text('Error: ${attendeeProvider.errorMessage}'));
                }

                List<AttendeeModel> displayAttendees = attendeeProvider.attendees
                    .where((a) => a.isActive)
                    .toList();

                if (displayAttendees.isEmpty) {
                  return const Center(
                    child: Text('No hay asistentes registrados.'),
                  );
                }

                return ListView.builder(
                  itemCount: displayAttendees.length,
                  itemBuilder: (context, index) {
                    final attendee = displayAttendees[index];
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

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
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
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditAttendeeDialog(attendee),
                        ),
                        onTap: () {
                          _showAddEditAttendeeDialog(attendee);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditAttendeeDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Añadir Asistente'),
      ),
    );
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
} 