import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Modèle de la table `parents`.
class ParentLocalModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String? email;
  final String? identificationNumber;
  final String syncStatus;
  final int? syncedAt;
  final int updatedAt;

  const ParentLocalModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    this.identificationNumber,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'phone_number': phoneNumber,
    'email': email,
    'identification_number': identificationNumber,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory ParentLocalModel.fromMap(Map<String, Object?> m) => ParentLocalModel(
    id: m['id'] as String,
    firstName: m['first_name'] as String,
    lastName: m['last_name'] as String,
    surname: m['surname'] as String?,
    phoneNumber: m['phone_number'] as String,
    email: m['email'] as String?,
    identificationNumber: m['identification_number'] as String?,
    syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
    syncedAt: m['synced_at'] as int?,
    updatedAt: (m['updated_at'] as int?) ?? 0,
  );

  LocalParent toEntity(
    OfflineRelationshipType relationshipType, {
    bool emergencyContact = false,
  }) => LocalParent(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    phoneNumber: phoneNumber,
    email: email,
    identificationNumber: identificationNumber,
    relationshipType: relationshipType,
    emergencyContact: emergencyContact,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}
