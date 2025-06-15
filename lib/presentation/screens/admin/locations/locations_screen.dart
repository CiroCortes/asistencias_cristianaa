import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistencias_app/core/providers/location_provider.dart';
import 'package:asistencias_app/data/models/location_models.dart';

enum LocationFormType { city, commune, location }

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController();
  
  LocationFormType _currentFormType = LocationFormType.city;

  City? _selectedCityForCommune;
  Commune? _selectedCommuneForLocation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _addressController.clear();
    _capacityController.clear();
    setState(() {
      _selectedCityForCommune = null;
      _selectedCommuneForLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Localidades'),
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFormSelector(),
                const SizedBox(height: 24),
                _buildCurrentForm(locationProvider),
                const SizedBox(height: 24),
                _buildLists(locationProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormSelector() {
    return SegmentedButton<LocationFormType>(
      segments: const <ButtonSegment<LocationFormType>>[
        ButtonSegment<LocationFormType>(
            value: LocationFormType.city, label: Text('Ciudad')),
        ButtonSegment<LocationFormType>(
            value: LocationFormType.commune, label: Text('Comuna')),
        ButtonSegment<LocationFormType>(
            value: LocationFormType.location, label: Text('Localidad')),
      ],
      selected: <LocationFormType>{_currentFormType},
      onSelectionChanged: (Set<LocationFormType> newSelection) {
        setState(() {
          _currentFormType = newSelection.first;
          _resetForm();
        });
      },
    );
  }

  Widget _buildCurrentForm(LocationProvider locationProvider) {
    switch (_currentFormType) {
      case LocationFormType.city:
        return _buildCityForm(locationProvider);
      case LocationFormType.commune:
        return _buildCommuneForm(locationProvider);
      case LocationFormType.location:
        return _buildLocationForm(locationProvider);
    }
  }

  Widget _buildCityForm(LocationProvider locationProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Ciudad',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre para la ciudad';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await locationProvider.createCity(_nameController.text);
                _resetForm();
                await locationProvider.loadCities();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ciudad creada exitosamente')),
                );
              }
            },
            child: const Text('Crear Ciudad'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommuneForm(LocationProvider locationProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<City>(
            decoration: const InputDecoration(
              labelText: 'Seleccionar Ciudad',
              border: OutlineInputBorder(),
            ),
            value: _selectedCityForCommune,
            items: locationProvider.cities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city.name),
              );
            }).toList(),
            onChanged: (City? value) {
              setState(() {
                _selectedCityForCommune = value;
                _selectedCommuneForLocation = null; // Reset commune when city changes
              });
              if (value != null) {
                locationProvider.loadCommunes(value.id);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor seleccione una ciudad';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Comuna',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre para la comuna';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate() && _selectedCityForCommune != null) {
                await locationProvider.createCommune(
                  _nameController.text,
                  _selectedCityForCommune!.id,
                );
                _resetForm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comuna creada exitosamente')),
                );
              }
            },
            child: const Text('Crear Comuna'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationForm(LocationProvider locationProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<City>(
            decoration: const InputDecoration(
              labelText: 'Seleccionar Ciudad',
              border: OutlineInputBorder(),
            ),
            value: _selectedCityForCommune,
            items: locationProvider.cities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city.name),
              );
            }).toList(),
            onChanged: (City? value) {
              setState(() {
                _selectedCityForCommune = value;
                _selectedCommuneForLocation = null; // Reset commune when city changes
              });
              if (value != null) {
                locationProvider.loadCommunes(value.id);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor seleccione una ciudad';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Commune>(
            decoration: const InputDecoration(
              labelText: 'Seleccionar Comuna',
              border: OutlineInputBorder(),
            ),
            value: _selectedCommuneForLocation,
            items: locationProvider.communes.map((commune) {
              return DropdownMenuItem(
                value: commune,
                child: Text(commune.name),
              );
            }).toList(),
            onChanged: (Commune? value) {
              setState(() {
                _selectedCommuneForLocation = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor seleccione una comuna';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Localidad',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre para la localidad';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección de la Localidad',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese una dirección';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            decoration: const InputDecoration(
              labelText: 'Capacidad de la Localidad (Número)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la capacidad';
              }
              if (int.tryParse(value) == null) {
                return 'Por favor ingrese un número válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate() && _selectedCommuneForLocation != null) {
                await locationProvider.createLocation(
                  _nameController.text,
                  _addressController.text,
                  _selectedCommuneForLocation!.id,
                );
                _resetForm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Localidad creada exitosamente')),
                );
              }
            },
            child: const Text('Crear Localidad'),
          ),
        ],
      ),
    );
  }

  Widget _buildLists(LocationProvider locationProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lista de Ciudades
        const Text(
          'Ciudades Existentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: locationProvider.cities.length,
          itemBuilder: (context, index) {
            final city = locationProvider.cities[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(city.name),
                onTap: () async {
                  await locationProvider.selectCity(city);
                  _showCityDetailsDialog(context, locationProvider);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditCityDialog(context, locationProvider, city);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'Desactivar Ciudad',
                          '¿Está seguro de DESACTIVAR la ciudad ${city.name}? Esto la ocultará de las listas.',
                          () async {
                            await locationProvider.deactivateCity(city.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Lista de Comunas
        if (locationProvider.selectedCity != null) ...[
          const Text(
            'Comunas en la ciudad seleccionada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locationProvider.communes.length,
            itemBuilder: (context, index) {
              final commune = locationProvider.communes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(commune.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditCommuneDialog(context, locationProvider, commune);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmationDialog(
                            context,
                            'Eliminar Comuna',
                            '¿Está seguro de eliminar la comuna ${commune.name}?',
                            () async {
                              await locationProvider.deleteCommune(commune.id, commune.cityId);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // Lista de Localidades
        if (locationProvider.selectedCommune != null) ...[
          const Text(
            'Localidades en la comuna seleccionada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locationProvider.locations.length,
            itemBuilder: (context, index) {
              final location = locationProvider.locations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(location.name),
                  subtitle: Text(location.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditLocationDialog(context, locationProvider, location);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmationDialog(
                            context,
                            'Eliminar Localidad',
                            '¿Está seguro de eliminar la localidad ${location.name}?',
                            () async {
                              await locationProvider.deleteLocation(location.id, location.communeId);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _showCityDetailsDialog(BuildContext context, LocationProvider locationProvider) async {
    final city = locationProvider.selectedCity;
    if (city == null) return;

    await locationProvider.loadCommunes(city.id);
    final totalCommunes = locationProvider.communes.length;

    int totalLocations = 0;
    for (var commune in locationProvider.communes) {
      await locationProvider.loadLocations(commune.id);
      totalLocations += locationProvider.locations.length;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${city.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comunas: $totalCommunes'),
            Text('Localidades: $totalLocations'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCityDialog(BuildContext context, LocationProvider locationProvider, City city) async {
    _nameController.text = city.name;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Ciudad'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Ciudad'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un nombre';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _resetForm();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await locationProvider.updateCity(city.id, _nameController.text);
                  _resetForm();
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCommuneDialog(BuildContext context, LocationProvider locationProvider, Commune commune) async {
    _nameController.text = commune.name;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Comuna'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Comuna'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un nombre';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _resetForm();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await locationProvider.updateCommune(commune.id, _nameController.text);
                  _resetForm();
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditLocationDialog(BuildContext context, LocationProvider locationProvider, Location location) async {
    _nameController.text = location.name;
    _addressController.text = location.address;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Localidad'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Localidad'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección de la Localidad'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese una dirección';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _resetForm();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await locationProvider.updateLocation(
                    location.id,
                    _nameController.text,
                    _addressController.text,
                  );
                  _resetForm();
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context, String title, String content, VoidCallback onDeleteConfirmed) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: onDeleteConfirmed,
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}