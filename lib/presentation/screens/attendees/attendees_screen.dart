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

  // Variables para el formulario de agregar/editar
  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;
  String _selectedType = 'member';
  bool _isAttendeeActive = true;

  // Variables para filtros de la lista principal (solo admin)
  City? _filterCity;
  Commune? _filterCommune;
  Location? _filterLocation;

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
      sectorId: assignedSectorId,
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
        sectorId: assignedSectorId,
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
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();
    final attendeeProvider = context.read<AttendeeProvider>();

    // Solo admin puede crear/editar asistentes para cualquier sector
    if (!userProvider.isAdmin && userProvider.user?.sectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes permisos para gestionar asistentes.')),
      );
      return;
    }

    // Reset form state
    if (attendeeToEdit != null) {
      _nameController.text = attendeeToEdit.name ?? '';
      _lastNameController.text = attendeeToEdit.lastName ?? '';
      _contactInfoController.text = attendeeToEdit.contactInfo ?? '';
      _selectedType = attendeeToEdit.type;
      _isAttendeeActive = attendeeToEdit.isActive;
      // Solo admin puede cambiar el sector
      if (userProvider.isAdmin) {
        // Find and set location data for editing
        final location = locationProvider.locations.firstWhereOrNull((l) => l.id == attendeeToEdit.sectorId);
        if (location != null) {
          _selectedLocation = location;
          final commune = locationProvider.communes.firstWhereOrNull((c) => c.id == location.communeId);
          if (commune != null) {
            _selectedCommune = commune;
            final city = locationProvider.cities.firstWhereOrNull((c) => c.id == commune.cityId);
            if (city != null) {
              _selectedCity = city;
            }
          }
        }
      }
    } else {
      _nameController.clear();
      _lastNameController.clear();
      _contactInfoController.clear();
      _selectedType = 'member';
      _isAttendeeActive = true;
      _selectedCity = null;
      _selectedCommune = null;
      _selectedLocation = null;
    }

    // Validar que los valores seleccionados existen en las listas disponibles
    if (userProvider.isAdmin) {
      if (_selectedCity != null && !locationProvider.cities.any((city) => city.id == _selectedCity!.id)) {
        _selectedCity = null;
        _selectedCommune = null;
        _selectedLocation = null;
      }
      if (_selectedCommune != null && !locationProvider.communes.any((commune) => commune.id == _selectedCommune!.id)) {
        _selectedCommune = null;
        _selectedLocation = null;
      }
      if (_selectedLocation != null && !locationProvider.locations.any((location) => location.id == _selectedLocation!.id)) {
        _selectedLocation = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final locationProvider = context.watch<LocationProvider>();

        return AlertDialog(
          title: const Text('Añadir Nuevo Asistente'),
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
          // Filtros para administradores
          if (userProvider.isAdmin) 
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _filterCity = null;
                                _filterCommune = null;
                                _filterLocation = null;
                              });
                            },
                            child: const Text('Limpiar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<City>(
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        value: _filterCity,
                        items: locationProvider.cities.map((city) {
                          return DropdownMenuItem(value: city, child: Text(city.name));
                        }).toList(),
                        onChanged: (City? newValue) {
                          setState(() {
                            _filterCity = newValue;
                            _filterCommune = null;
                            _filterLocation = null;
                          });
                          if (newValue != null) {
                            locationProvider.loadCommunes(newValue.id);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Commune>(
                        decoration: const InputDecoration(
                          labelText: 'Comuna',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.place),
                        ),
                        value: _filterCommune,
                        items: locationProvider.communes
                            .where((commune) => _filterCity == null || commune.cityId == _filterCity!.id)
                            .map((commune) {
                          return DropdownMenuItem(value: commune, child: Text(commune.name));
                        }).toList(),
                        onChanged: (Commune? newValue) {
                          setState(() {
                            _filterCommune = newValue;
                            _filterLocation = null;
                          });
                          if (newValue != null) {
                            locationProvider.loadLocations(newValue.id);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Location>(
                        decoration: const InputDecoration(
                          labelText: 'Sector',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        value: _filterLocation,
                        items: locationProvider.locations
                            .where((location) => _filterCommune == null || location.communeId == _filterCommune!.id)
                            .map((location) {
                          return DropdownMenuItem(value: location, child: Text(location.name));
                        }).toList(),
                        onChanged: (Location? newValue) {
                          setState(() {
                            _filterLocation = newValue;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
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

                // Aplicar filtros para administradores
                if (userProvider.isAdmin) {
                  if (_filterLocation != null) {
                    displayAttendees = displayAttendees
                        .where((a) => a.sectorId == _filterLocation!.id)
                        .toList();
                  } else if (_filterCommune != null) {
                    // Si no hay sector específico pero sí comuna, filtrar por todos los sectores de esa comuna
                    final locationProvider = context.read<LocationProvider>();
                    final sectorsInCommune = locationProvider.locations
                        .where((location) => location.communeId == _filterCommune!.id)
                        .map((location) => location.id)
                        .toList();
                    displayAttendees = displayAttendees
                        .where((a) => sectorsInCommune.contains(a.sectorId))
                        .toList();
                  } else if (_filterCity != null) {
                    // Si no hay comuna específica pero sí ciudad, filtrar por todas las comunas de esa ciudad
                    final locationProvider = context.read<LocationProvider>();
                    final communesInCity = locationProvider.communes
                        .where((commune) => commune.cityId == _filterCity!.id)
                        .map((commune) => commune.id)
                        .toList();
                    final sectorsInCity = locationProvider.locations
                        .where((location) => communesInCity.contains(location.communeId))
                        .map((location) => location.id)
                        .toList();
                    displayAttendees = displayAttendees
                        .where((a) => sectorsInCity.contains(a.sectorId))
                        .toList();
                  }
                }

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
        heroTag: "attendees_fab",
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