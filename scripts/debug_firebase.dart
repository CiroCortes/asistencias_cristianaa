#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

void main() async {
  print('🔍 DEBUG: Explorando estructura de Firebase...');
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final firestore = FirebaseFirestore.instance;
    
    print('\n📋 === CIUDADES (cities) ===');
    final citiesQuery = await firestore.collection('cities').get();
    if (citiesQuery.docs.isEmpty) {
      print('❌ No hay ciudades en la colección "cities"');
    } else {
      for (final doc in citiesQuery.docs) {
        final data = doc.data();
        print('🏙️  ID: ${doc.id}');
        print('   Nombre: "${data['name']}"');
        print('   Activa: ${data['isActive']}');
        print('   CommuneIds: ${data['communeIds']}');
        print('   ---');
      }
    }
    
    print('\n📋 === COMUNAS/RUTAS (communes) ===');
    final communesQuery = await firestore.collection('communes').get();
    if (communesQuery.docs.isEmpty) {
      print('❌ No hay comunas en la colección "communes"');
    } else {
      for (final doc in communesQuery.docs) {
        final data = doc.data();
        print('🗺️  ID: ${doc.id}');
        print('   Nombre: "${data['name']}"');
        print('   CityId: ${data['cityId']}');
        print('   LocationIds: ${data['locationIds']}');
        print('   CreatedAt: ${data['createdAt']}');
        print('   ---');
      }
    }
    
    print('\n📋 === SECTORES/LOCACIONES (locations) ===');
    final locationsQuery = await firestore.collection('locations').get();
    if (locationsQuery.docs.isEmpty) {
      print('❌ No hay locaciones en la colección "locations"');
    } else {
      for (final doc in locationsQuery.docs) {
        final data = doc.data();
        print('📍 ID: ${doc.id}');
        print('   Nombre: "${data['name']}"');
        print('   CommuneId: ${data['communeId']}');
        print('   Address: "${data['address']}"');
        print('   AttendeeIds: ${data['attendeeIds']}');
        print('   ---');
      }
    }
    
    // Buscar específicamente Quilicura
    print('\n🔍 === BÚSQUEDA ESPECÍFICA DE QUILICURA ===');
    
    // Buscar en comunas
    print('Buscando "Quilicura" en communes...');
    bool quilicuraFound = false;
    
    for (final doc in communesQuery.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toLowerCase();
      if (name.contains('quilicura') || name == 'quilicura') {
        print('✅ ENCONTRADO en communes:');
        print('   ID: ${doc.id}');
        print('   Nombre exacto: "${data['name']}"');
        print('   CityId: ${data['cityId']}');
        
        // Buscar sectores de esta comuna
        print('   🔍 Sectores de esta comuna:');
        for (final locDoc in locationsQuery.docs) {
          final locData = locDoc.data();
          if (locData['communeId'] == doc.id) {
            print('     • ${locData['name']} (ID: ${locDoc.id})');
          }
        }
        quilicuraFound = true;
        break;
      }
    }
    
    if (!quilicuraFound) {
      print('❌ No se encontró "Quilicura" en la colección communes');
      print('💡 Nombres disponibles:');
      for (final doc in communesQuery.docs) {
        final data = doc.data();
        print('   • "${data['name']}"');
      }
    }
    
    // Verificar ID específico
    print('\n🎯 === VERIFICACIÓN POR ID ESPECÍFICO ===');
    const targetId = 'QsszuqTZk0QDKHNBiTj6';
    try {
      final specificDoc = await firestore.collection('communes').doc(targetId).get();
      if (specificDoc.exists) {
        final data = specificDoc.data()!;
        print('✅ ID $targetId EXISTE:');
        print('   Nombre: "${data['name']}"');
        print('   CityId: ${data['cityId']}');
        print('   LocationIds: ${data['locationIds']}');
      } else {
        print('❌ ID $targetId NO EXISTE en communes');
      }
    } catch (e) {
      print('❌ Error al buscar ID específico: $e');
    }
    
    print('\n📊 === RESUMEN ===');
    print('Total ciudades: ${citiesQuery.docs.length}');
    print('Total comunas: ${communesQuery.docs.length}');
    print('Total sectores: ${locationsQuery.docs.length}');
    
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }
} 