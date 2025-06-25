import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/users_provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/user_model.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:collection/collection.dart';

enum UserFilter {
  pendingApproval,
  allRoles,
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  UserFilter _selectedFilter = UserFilter.pendingApproval;

  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadCities();
    });
  }

  void _showEditUserDialog([UserModel? userToEdit]) {
    bool isApproved = userToEdit?.isApproved ?? false;
    String selectedRole = userToEdit?.role ?? 'normal_user';
    final TextEditingController displayNameController = TextEditingController(text: userToEdit?.displayName ?? '');
    final TextEditingController emailController = TextEditingController(text: userToEdit?.email ?? '');

    final locationProvider = context.read<LocationProvider>();
    if (userToEdit?.sectorId != null) {
      _selectedLocation = locationProvider.locations.firstWhereOrNull((loc) => loc.id == userToEdit!.sectorId);
      if (_selectedLocation != null) {
        _selectedCommune = locationProvider.communes.firstWhereOrNull((comm) => comm.id == _selectedLocation!.communeId);
        if (_selectedCommune != null) {
          _selectedCity = locationProvider.cities.firstWhereOrNull((city) => city.id == _selectedCommune!.cityId);
          if (_selectedCity != null) {
            locationProvider.loadCommunes(_selectedCity!.id).then((_) {
              if (_selectedCommune != null) {
                locationProvider.loadLocations(_selectedCommune!.id);
              }
            });
          }
        }
      }
    } else {
      _selectedCity = null;
      _selectedCommune = null;
      _selectedLocation = null;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInDialog) {
            final locationProvider = dialogContext.watch<LocationProvider>();
            final usersProvider = dialogContext.read<UsersProvider>();

            return AlertDialog(
              title: Text(userToEdit == null ? 'Aprobar/Editar Usuario' : 'Editar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: displayNameController,
                      decoration: const InputDecoration(labelText: 'Nombre de Usuario'),
                      readOnly: userToEdit != null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                      readOnly: userToEdit != null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Rol'),
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                        DropdownMenuItem(value: 'normal_user', child: Text('Usuario Normal')),
                      ],
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Aprobado'),
                      value: isApproved,
                      onChanged: (bool? newValue) {
                        setStateInDialog(() {
                          isApproved = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Asignar Ubicación (Sector)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<City>(
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                      value: _selectedCity,
                      items: locationProvider.cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city.name));
                      }).toList(),
                      onChanged: (City? newValue) {
                        setStateInDialog(() {
                          _selectedCity = newValue;
                          _selectedCommune = null;
                          _selectedLocation = null;
                          if (newValue != null) {
                            locationProvider.loadCommunes(newValue.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Commune>(
                      decoration: const InputDecoration(labelText: 'Comuna'),
                      value: _selectedCommune,
                      items: locationProvider.communes.map((commune) {
                        return DropdownMenuItem(value: commune, child: Text(commune.name));
                      }).toList(),
                      onChanged: (_selectedCity == null) ? null : (Commune? newValue) {
                        setStateInDialog(() {
                          _selectedCommune = newValue;
                          _selectedLocation = null;
                          if (newValue != null) {
                            locationProvider.loadLocations(newValue.id);
                          }
                        });
                      },
                      hint: _selectedCity == null ? const Text('Selecciona una Ciudad primero') : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Location>(
                      decoration: const InputDecoration(labelText: 'Localidad/Sector'),
                      value: _selectedLocation,
                      items: locationProvider.locations.map((location) {
                        return DropdownMenuItem(value: location, child: Text(location.name));
                      }).toList(),
                      onChanged: (_selectedCommune == null) ? null : (Location? newValue) {
                        setStateInDialog(() {
                          _selectedLocation = newValue;
                        });
                      },
                      hint: _selectedCommune == null ? const Text('Selecciona una Comuna primero') : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedLocation == null) {
                       ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Por favor, selecciona una localidad/sector.')),
                       );
                       return;
                    }

                    final updatedUser = UserModel(
                      uid: userToEdit?.uid ?? '',
                      email: emailController.text,
                      displayName: displayNameController.text,
                      role: selectedRole,
                      isApproved: isApproved,
                      sectorId: _selectedLocation!.id,
                    );

                    if (userToEdit == null) {
                       ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('La creación de nuevos usuarios es a través de la pantalla de registro.')),
                       );
                    } else {
                      await usersProvider.updateUser(updatedUser);
                       ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Usuario actualizado exitosamente.')),
                       );
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {
      _selectedCity = null;
      _selectedCommune = null;
      _selectedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<UserFilter>(
              segments: const [
                ButtonSegment<UserFilter>(
                  value: UserFilter.pendingApproval,
                  label: Text('Aprobación Pendiente'),
                ),
                ButtonSegment<UserFilter>(
                  value: UserFilter.allRoles,
                  label: Text('Todos los Roles'),
                ),
              ],
              selected: <UserFilter>{_selectedFilter},
              onSelectionChanged: (Set<UserFilter> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<UsersProvider>(
              builder: (context, usersProvider, child) {
                if (usersProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (usersProvider.errorMessage != null) {
                  return Center(
                      child: Text('Error: ${usersProvider.errorMessage}'));
                }

                List<UserModel> filteredUsers = usersProvider.users.where((user) {
                  if (_selectedFilter == UserFilter.pendingApproval) {
                    return !user.isApproved;
                  } else {
                    return true; // All roles
                  }
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                      child: Text('No hay usuarios para mostrar.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(user.displayName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                user.role == 'admin' ? 'Admin' : 'Usuario'),
                            const SizedBox(width: 8),
                            if (!user.isApproved)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () async {
                                  _showEditUserDialog(user);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await usersProvider.deleteUser(user.uid);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _showEditUserDialog(user);
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
      floatingActionButton: FloatingActionButton(
        heroTag: "user_management_fab",
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La creación de nuevos usuarios es a través de la pantalla de registro.')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 