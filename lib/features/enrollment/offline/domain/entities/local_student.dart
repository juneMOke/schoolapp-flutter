import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Élève lu depuis sqflite (miroir local). `matriculationNumber`/`email` sont
/// null hors-ligne (« en cours d'attribution »).
class LocalStudent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final OfflineGender gender;
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
  final SyncState syncState;

  const LocalStudent({
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
    this.syncState = SyncState.pendingSync,
  });

  bool get hasMatricule =>
      matriculationNumber != null && matriculationNumber!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    nationality,
    city,
    district,
    municipality,
    neighborhood,
    address,
    phoneNumber,
    matriculationNumber,
    email,
    syncState,
  ];
}
