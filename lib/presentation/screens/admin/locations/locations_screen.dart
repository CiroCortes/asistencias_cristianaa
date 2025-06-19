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

  City? _selectedCityFilter;
  Commune? _selectedCommuneFilter;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.loadCities();
    // Cargar todas las comunas de todas las ciudades
    final allCommunes = await locationProvider.loadAllCommunes();
    if (!mounted) return;
    locationProvider.setCommunes = allCommunes;
    // Cargar todos los sectores de todas las comunas
    final allLocations = await locationProvider.loadAllLocations(allCommunes);
    if (!mounted) return;
    locationProvider.setLocations = allLocations;
    setState(() {});
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _addressController.clear();
    _capacityController.clear();
    setState(() {
      _selectedCityFilter = null;
      _selectedCommuneFilter = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    // Limpiar los datos del provider al salir
    final locationProvider = context.read<LocationProvider>();
    locationProvider.clearData();
    super.dispose();
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
                const SizedBox(height: 16),
                _buildFilters(locationProvider),
                const SizedBox(height: 24),
                _buildCurrentForm(locationProvider),
                const SizedBox(height: 24),
                _buildDynamicLists(locationProvider),
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
            value: LocationFormType.commune, label: Text('Ruta')),
        ButtonSegment<LocationFormType>(
            value: LocationFormType.location, label: Text('Sector')),
      ],
      selected: <LocationFormType>{_currentFormType},
      onSelectionChanged: (Set<LocationFormType> newSelection) {
        setState(() {
          _currentFormType = newSelection.first;
          _resetForm();
          _loadAllData();
        });
      },
    );
  }

  Widget _buildFilters(LocationProvider locationProvider) {
    if (_currentFormType == LocationFormType.city) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_currentFormType == LocationFormType.commune || _currentFormType == LocationFormType.location)
          DropdownButtonFormField<City>(
            decoration: const InputDecoration(
              labelText: 'Filtrar por Ciudad',
              border: OutlineInputBorder(),
            ),
            value: _selectedCityFilter,
            items: locationProvider.cities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city.name),
              );
            }).toList(),
            onChanged: (City? value) {
              setState(() {
                _selectedCityFilter = value;
                _selectedCommuneFilter = null;
              });
            },
            isExpanded: true,
          ),
        if (_currentFormType == LocationFormType.location && _selectedCityFilter != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<Commune>(
            decoration: const InputDecoration(
              labelText: 'Filtrar por Ruta',
              border: OutlineInputBorder(),
            ),
            value: _selectedCommuneFilter,
            items: locationProvider.communes
                .where((c) => c.cityId == _selectedCityFilter!.id)
                .map((commune) {
              return DropdownMenuItem(
                value: commune,
                child: Text(commune.name),
              );
            }).toList(),
            onChanged: (Commune? value) {
              setState(() {
                _selectedCommuneFilter = value;
              });
            },
            isExpanded: true,
          ),
        ],
      ],
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
    if (_selectedCityFilter == null) {
      return const Center(
        child: Text('Por favor seleccione una ciudad en el filtro superior'),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Ruta',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre para la ruta';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await locationProvider.createCommune(
                  _nameController.text,
                  _selectedCityFilter!.id,
                );
                _resetForm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta creada exitosamente')),
                );
              }
            },
            child: const Text('Crear Ruta'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationForm(LocationProvider locationProvider) {
    if (_selectedCommuneFilter == null) {
      return const Center(
        child: Text('Por favor seleccione una ruta en el filtro superior'),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              if (_formKey.currentState!.validate()) {
                await locationProvider.createLocation(
                  _nameController.text,
                  _addressController.text,
                  _selectedCommuneFilter!.id,
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

  Widget _buildDynamicLists(LocationProvider locationProvider) {
    if (_currentFormType == LocationFormType.city) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ciudades Existentes', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locationProvider.cities.length,
            itemBuilder: (context, index) {
              final city = locationProvider.cities[index];
              final cityCommunes = locationProvider.communes
                  .where((c) => c.cityId == city.id)
                  .toList();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(city.name)),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCityDialog(context, locationProvider, city),
                      ),
                    ],
                  ),
                  children: cityCommunes.map((commune) => 
                    ListTile(
                      title: Text(commune.name),
                      dense: true,
                    )
                  ).toList(),
                ),
              );
            },
          ),
        ],
      );
    } else if (_currentFormType == LocationFormType.commune) {
      List<Commune> filteredCommunes = locationProvider.communes;
      if (_selectedCityFilter != null) {
        filteredCommunes = filteredCommunes
            .where((c) => c.cityId == _selectedCityFilter!.id)
            .toList();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text('Rutas', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCommunes.length,
            itemBuilder: (context, index) {
              final commune = filteredCommunes[index];
              final city = locationProvider.cities
                  .firstWhere((c) => c.id == commune.cityId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(commune.name),
                  subtitle: Text('Ciudad: ${city.name}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCommuneDialog(context, locationProvider, commune),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteCommuneDialog(context, locationProvider, commune),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else {
      List<Location> filteredLocations = locationProvider.locations;
      if (_selectedCommuneFilter != null) {
        filteredLocations = filteredLocations
            .where((l) => l.communeId == _selectedCommuneFilter!.id)
            .toList();
      } else if (_selectedCityFilter != null) {
        final communeIds = locationProvider.communes
            .where((c) => c.cityId == _selectedCityFilter!.id)
            .map((c) => c.id)
            .toList();
        filteredLocations = filteredLocations
            .where((l) => communeIds.contains(l.communeId))
            .toList();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text('Sectores', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredLocations.length,
            itemBuilder: (context, index) {
              final location = filteredLocations[index];
              final commune = locationProvider.communes
                  .firstWhere((c) => c.id == location.communeId);
              final city = locationProvider.cities
                  .firstWhere((c) => c.id == commune.cityId);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(location.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ruta: ${commune.name}'),
                      Text('Ciudad: ${city.name}'),
                      Text('Dirección: ${location.address}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditLocationDialog(context, locationProvider, location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteLocationDialog(context, locationProvider, location),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ],
      );
    }
  }

  void _showEditCityDialog(BuildContext context, LocationProvider locationProvider, City city) {
    _nameController.text = city.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Ciudad'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Ciudad',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await locationProvider.updateCity(
                  city.id,
                  _nameController.text,
                );
                Navigator.pop(context);
                _resetForm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ciudad actualizada exitosamente'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditCommuneDialog(BuildContext context, LocationProvider locationProvider, Commune commune) {
    _nameController.text = commune.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Ruta'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Ruta',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await locationProvider.updateCommune(
                  commune.id,
                  _nameController.text,
                );
                Navigator.pop(context);
                _resetForm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ruta actualizada exitosamente'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, LocationProvider locationProvider, Location location) {
    _nameController.text = location.name;
    _addressController.text = location.address;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Sector'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Sector',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección del Sector',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una dirección';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await locationProvider.updateLocation(
                  location.id,
                  _nameController.text,
                  _addressController.text,
                );
                Navigator.pop(context);
                _resetForm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sector actualizado exitosamente'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommuneDialog(BuildContext context, LocationProvider locationProvider, Commune commune) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ruta'),
        content: Text('¿Está seguro que desea eliminar la ruta ${commune.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await locationProvider.deleteCommune(
                commune.id,
                commune.cityId,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ruta eliminada exitosamente'),
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLocationDialog(BuildContext context, LocationProvider locationProvider, Location location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sector'),
        content: Text('¿Está seguro que desea eliminar el sector ${location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await locationProvider.deleteLocation(
                location.id,
                location.communeId,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sector eliminado exitosamente'),
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}