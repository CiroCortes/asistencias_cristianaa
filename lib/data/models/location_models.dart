import 'package:cloud_firestore/cloud_firestore.dart';

class City {
  final String id;
  final String name;
  final List<String> communeIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  City({
    required this.id,
    required this.name,
    required this.communeIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory City.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return City(
      id: doc.id,
      name: data['name'] ?? '',
      communeIds: List<String>.from(data['communeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'communeIds': communeIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Commune {
  final String id;
  final String name;
  final String cityId;
  final List<String> locationIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Commune({
    required this.id,
    required this.name,
    required this.cityId,
    required this.locationIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Commune.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Commune(
      id: doc.id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      locationIds: List<String>.from(data['locationIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cityId': cityId,
      'locationIds': locationIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Commune && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Location {
  final String id;
  final String name;
  final String communeId;
  final String address;
  final List<String> attendeeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.id,
    required this.name,
    required this.communeId,
    required this.address,
    required this.attendeeIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Location.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Location(
      id: doc.id,
      name: data['name'] ?? '',
      communeId: data['communeId'] ?? '',
      address: data['address'] ?? '',
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'communeId': communeId,
      'address': address,
      'attendeeIds': attendeeIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
} 