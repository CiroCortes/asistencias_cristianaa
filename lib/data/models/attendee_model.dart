import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeeModel {
  final String? id;
  final String? name;
  final String? lastName;
  final String type; // 'member', 'visitor', 'listener'
  final String sectorId;
  final String? contactInfo;
  final DateTime createdAt;
  final String createdByUserId;
  final bool isActive; // Nuevo campo para activar/desactivar

  AttendeeModel({
    this.id,
    this.name,
    this.lastName,
    required this.type,
    required this.sectorId,
    this.contactInfo,
    required this.createdAt,
    required this.createdByUserId,
    this.isActive = true, // Por defecto, activo
  });

  factory AttendeeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    
    // Verificar que los campos requeridos no sean null
    if (data == null) {
      throw Exception('Attendee data is null for document ${snapshot.id}');
    }
    
    final type = data['type'] as String?;
    final sectorId = data['sectorId'] as String?;
    final createdByUserId = data['createdByUserId'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    
    if (type == null || type.isEmpty) {
      throw Exception('Attendee type is null or empty for document ${snapshot.id}');
    }
    if (sectorId == null || sectorId.isEmpty) {
      throw Exception('Attendee sectorId is null or empty for document ${snapshot.id}');
    }
    if (createdByUserId == null || createdByUserId.isEmpty) {
      throw Exception('Attendee createdByUserId is null or empty for document ${snapshot.id}');
    }
    if (createdAt == null) {
      throw Exception('Attendee createdAt is null for document ${snapshot.id}');
    }
    
    return AttendeeModel(
      id: snapshot.id,
      name: data['name'] as String?,
      lastName: data['lastName'] as String?,
      type: type,
      sectorId: sectorId,
      contactInfo: data['contactInfo'] as String?,
      createdAt: createdAt.toDate(),
      createdByUserId: createdByUserId,
      isActive: data['isActive'] ?? true, // Leer el estado activo
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "lastName": lastName,
      "type": type,
      "sectorId": sectorId,
      "contactInfo": contactInfo,
      "createdAt": Timestamp.fromDate(createdAt),
      "createdByUserId": createdByUserId,
      "isActive": isActive, // Guardar el estado activo
    };
  }

  AttendeeModel copyWith({
    String? id,
    String? name,
    String? lastName,
    String? type,
    String? sectorId,
    String? contactInfo,
    DateTime? createdAt,
    String? createdByUserId,
    bool? isActive,
  }) {
    return AttendeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      type: type ?? this.type,
      sectorId: sectorId ?? this.sectorId,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      isActive: isActive ?? this.isActive,
    );
  }
} 