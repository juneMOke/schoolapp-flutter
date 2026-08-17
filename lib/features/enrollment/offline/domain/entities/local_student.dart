import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Élève lu depuis sqflite (miroir local). `matriculationNumber` est null
/// hors-ligne (« en cours d'attribution »), posé à l'ACK.
///
/// Ni téléphone ni e-mail (retirés ADR-015 F8) : le serveur les envoyait, la
/// base les gardait, et `LocalEnrollmentDetailMapper` — le seul chemin vers
/// l'écran — ne les recopiait pas dans `StudentDetail`. De la donnée personnelle
/// qui traversait trois couches pour être abandonnée à la dernière. Le tuteur,
/// lui, garde les siens : `ParentSummary` les affiche.
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
  final String? matriculationNumber;
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
    this.matriculationNumber,
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
    matriculationNumber,
    syncState,
  ];
}
