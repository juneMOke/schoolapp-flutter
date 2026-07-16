import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Modèle de la table `students` (toMap/fromMap/toEntity).
class StudentLocalModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender;
  final String dateOfBirth;
  final String? birthPlace;
  final String? nationality;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String? phoneNumber;
  final String? matriculationNumber;
  final String? email;
  final String syncStatus;
  final String? syncError;
  final int? syncedAt;
  final int updatedAt;

  const StudentLocalModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.phoneNumber,
    this.matriculationNumber,
    this.email,
    this.syncStatus = 'PENDING_SYNC',
    this.syncError,
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'gender': gender,
    'date_of_birth': dateOfBirth,
    'birth_place': birthPlace,
    'nationality': nationality,
    'city': city,
    'district': district,
    'municipality': municipality,
    'neighborhood': neighborhood,
    'address': address,
    'phone_number': phoneNumber,
    'matriculation_number': matriculationNumber,
    'email': email,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory StudentLocalModel.fromMap(Map<String, Object?> m) =>
      StudentLocalModel(
        id: m['id'] as String,
        firstName: m['first_name'] as String,
        lastName: m['last_name'] as String,
        surname: m['surname'] as String?,
        gender: m['gender'] as String,
        dateOfBirth: m['date_of_birth'] as String,
        birthPlace: m['birth_place'] as String?,
        nationality: m['nationality'] as String?,
        city: m['city'] as String?,
        district: m['district'] as String?,
        municipality: m['municipality'] as String?,
        neighborhood: m['neighborhood'] as String?,
        address: m['address'] as String?,
        phoneNumber: m['phone_number'] as String?,
        matriculationNumber: m['matriculation_number'] as String?,
        email: m['email'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncError: m['sync_error'] as String?,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  LocalStudent toEntity() => LocalStudent(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    gender: OfflineGender.fromApiValue(gender),
    dateOfBirth: dateOfBirth,
    birthPlace: birthPlace,
    nationality: nationality,
    city: city,
    district: district,
    municipality: municipality,
    neighborhood: neighborhood,
    address: address,
    phoneNumber: phoneNumber,
    matriculationNumber: matriculationNumber,
    email: email,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}
