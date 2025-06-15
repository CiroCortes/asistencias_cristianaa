import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencias_app/data/models/location_models.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ciudades
  Future<List<City>> getCities() async {
    print('Obteniendo ciudades de Firestore...');
    final snapshot = await _firestore.collection('cities').where('isActive', isEqualTo: true).get();
    print('Documentos obtenidos: ${snapshot.docs.length}');
    return snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
  }

  Future<City> createCity(String name) async {
    print('Creando documento de ciudad en Firestore...');
    final docRef = await _firestore.collection('cities').add({
      'name': name,
      'communeIds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    print('Documento de ciudad creado con ID: ${docRef.id}');

    final doc = await docRef.get();
    return City.fromFirestore(doc);
  }

  Future<void> updateCity(String id, String name) async {
    await _firestore.collection('cities').doc(id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateCity(String id) async {
    await _firestore.collection('cities').doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Comunas
  Future<List<Commune>> getCommunesByCity(String cityId) async {
    final snapshot = await _firestore
        .collection('communes')
        .where('cityId', isEqualTo: cityId)
        .get();
    return snapshot.docs.map((doc) => Commune.fromFirestore(doc)).toList();
  }

  Future<Commune> createCommune(String name, String cityId) async {
    final docRef = await _firestore.collection('communes').add({
      'name': name,
      'cityId': cityId,
      'locationIds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Actualizar la lista de comunas en la ciudad
    await _firestore.collection('cities').doc(cityId).update({
      'communeIds': FieldValue.arrayUnion([docRef.id]),
    });

    final doc = await docRef.get();
    return Commune.fromFirestore(doc);
  }

  Future<void> updateCommune(String id, String name) async {
    await _firestore.collection('communes').doc(id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCommune(String id, String cityId) async {
    // Eliminar la comuna
    await _firestore.collection('communes').doc(id).delete();

    // Actualizar la lista de comunas en la ciudad
    await _firestore.collection('cities').doc(cityId).update({
      'communeIds': FieldValue.arrayRemove([id]),
    });
  }

  // Locaciones
  Future<List<Location>> getLocationsByCommune(String communeId) async {
    final snapshot = await _firestore
        .collection('locations')
        .where('communeId', isEqualTo: communeId)
        .get();
    return snapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
  }

  Future<Location> createLocation(String name, String address, String communeId) async {
    final docRef = await _firestore.collection('locations').add({
      'name': name,
      'communeId': communeId,
      'address': address,
      'attendeeIds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Actualizar la lista de locaciones en la comuna
    await _firestore.collection('communes').doc(communeId).update({
      'locationIds': FieldValue.arrayUnion([docRef.id]),
    });

    final doc = await docRef.get();
    return Location.fromFirestore(doc);
  }

  Future<void> updateLocation(String id, String name, String address) async {
    await _firestore.collection('locations').doc(id).update({
      'name': name,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLocation(String id, String communeId) async {
    // Eliminar la locación
    await _firestore.collection('locations').doc(id).delete();

    // Actualizar la lista de locaciones en la comuna
    await _firestore.collection('communes').doc(communeId).update({
      'locationIds': FieldValue.arrayRemove([id]),
    });
  }
} 