import 'package:flutter/foundation.dart';
import 'package:asistencias_app/data/models/location_models.dart';
import 'package:asistencias_app/core/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  List<City> _cities = [];
  List<Commune> _communes = [];
  List<Location> _locations = [];
  
  City? _selectedCity;
  Commune? _selectedCommune;
  Location? _selectedLocation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Getters
  List<City> get cities => _cities;
  List<Commune> get communes => _communes;
  List<Location> get locations => _locations;
  
  City? get selectedCity => _selectedCity;
  Commune? get selectedCommune => _selectedCommune;
  Location? get selectedLocation => _selectedLocation;

  // Cargar ciudades
  Future<void> loadCities() async {
    if (_isLoading) return; // Prevenir múltiples cargas simultáneas
    
    _isLoading = true;
    notifyListeners();
    print('Cargando ciudades...');
    
    try {
      _cities = await _locationService.getCities();
      print('Ciudades cargadas: ${_cities.length}');
    } catch (e) {
      print('Error cargando ciudades: $e');
      _cities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar comunas de una ciudad
  Future<void> loadCommunes(String cityId) async {
    if (_isLoading) return; // Prevenir múltiples cargas simultáneas
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _communes = await _locationService.getCommunesByCity(cityId);
    } catch (e) {
      print('Error cargando comunas: $e');
      _communes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar locaciones de una comuna
  Future<void> loadLocations(String communeId) async {
    if (_isLoading) return; // Prevenir múltiples cargas simultáneas
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _locations = await _locationService.getLocationsByCommune(communeId);
    } catch (e) {
      print('Error cargando locaciones: $e');
      _locations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seleccionar ciudad
  Future<void> selectCity(City city) async {
    _selectedCity = city;
    _selectedCommune = null;
    _selectedLocation = null;
    notifyListeners();
    
    await loadCommunes(city.id);
  }

  // Seleccionar comuna
  Future<void> selectCommune(Commune commune) async {
    _selectedCommune = commune;
    _selectedLocation = null;
    notifyListeners();
    
    await loadLocations(commune.id);
  }

  // Seleccionar locación
  void selectLocation(Location location) {
    _selectedLocation = location;
    notifyListeners();
  }

  // Crear ciudad
  Future<void> createCity(String name) async {
    print('Creando ciudad: $name');
    final city = await _locationService.createCity(name);
    print('Ciudad creada con ID: ${city.id}');
    _cities.add(city);
    notifyListeners();
  }

  // Crear comuna
  Future<void> createCommune(String name, String cityId) async {
    final commune = await _locationService.createCommune(name, cityId);
    _communes.add(commune);
    notifyListeners();
  }

  // Crear locación
  Future<void> createLocation(String name, String address, String communeId) async {
    final location = await _locationService.createLocation(name, address, communeId);
    _locations.add(location);
    notifyListeners();
  }

  // Actualizar ciudad
  Future<void> updateCity(String id, String name) async {
    await _locationService.updateCity(id, name);
    final index = _cities.indexWhere((city) => city.id == id);
    if (index != -1) {
      _cities[index] = City(
        id: id,
        name: name,
        communeIds: _cities[index].communeIds,
        createdAt: _cities[index].createdAt,
        updatedAt: DateTime.now(),
        isActive: _cities[index].isActive,
      );
      notifyListeners();
    }
  }

  // Actualizar comuna
  Future<void> updateCommune(String id, String name) async {
    await _locationService.updateCommune(id, name);
    final index = _communes.indexWhere((commune) => commune.id == id);
    if (index != -1) {
      _communes[index] = Commune(
        id: id,
        name: name,
        cityId: _communes[index].cityId,
        locationIds: _communes[index].locationIds,
        createdAt: _communes[index].createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Actualizar locación
  Future<void> updateLocation(String id, String name, String address) async {
    await _locationService.updateLocation(id, name, address);
    final index = _locations.indexWhere((location) => location.id == id);
    if (index != -1) {
      _locations[index] = Location(
        id: id,
        name: name,
        communeId: _locations[index].communeId,
        address: address,
        attendeeIds: _locations[index].attendeeIds,
        createdAt: _locations[index].createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Desactivar ciudad
  Future<void> deactivateCity(String id) async {
    await _locationService.deactivateCity(id);
    _cities.removeWhere((city) => city.id == id);
    if (_selectedCity?.id == id) {
      _selectedCity = null;
      _communes = [];
      _locations = [];
    }
    notifyListeners();
  }

  // Eliminar comuna
  Future<void> deleteCommune(String id, String cityId) async {
    await _locationService.deleteCommune(id, cityId);
    _communes.removeWhere((commune) => commune.id == id);
    if (_selectedCommune?.id == id) {
      _selectedCommune = null;
      _locations = [];
    }
    notifyListeners();
  }

  // Eliminar locación
  Future<void> deleteLocation(String id, String communeId) async {
    await _locationService.deleteLocation(id, communeId);
    _locations.removeWhere((location) => location.id == id);
    if (_selectedLocation?.id == id) {
      _selectedLocation = null;
    }
    notifyListeners();
  }

  // Limpiar todas las selecciones
  void clearSelections() {
    _selectedCity = null;
    _selectedCommune = null;
    _selectedLocation = null;
    _communes = [];
    _locations = [];
    notifyListeners();
  }

  // Limpiar todos los datos
  void clearData() {
    _cities = [];
    _communes = [];
    _locations = [];
    _selectedCity = null;
    _selectedCommune = null;
    _selectedLocation = null;
    notifyListeners();
  }

  // Cargar todas las comunas de todas las ciudades
  Future<List<Commune>> loadAllCommunes() async {
    if (_isLoading) return _communes;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final allCommunes = <Commune>[];
      for (final city in _cities) {
        final cityCommunes = await _locationService.getCommunesByCity(city.id);
        allCommunes.addAll(cityCommunes);
      }
      return allCommunes;
    } catch (e) {
      print('Error cargando todas las comunas: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar todas las ubicaciones de todas las comunas
  Future<List<Location>> loadAllLocations(List<Commune> communes) async {
    if (_isLoading) return _locations;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final allLocations = <Location>[];
      for (final commune in communes) {
        final communeLocations = await _locationService.getLocationsByCommune(commune.id);
        allLocations.addAll(communeLocations);
      }
      return allLocations;
    } catch (e) {
      print('Error cargando todas las ubicaciones: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Setter para communes (necesario para el reporte)
  set setCommunes(List<Commune> communes) {
    _communes = communes;
    notifyListeners();
  }

  // Setter para locations (necesario para el reporte)
  set setLocations(List<Location> locations) {
    _locations = locations;
    notifyListeners();
  }
} 