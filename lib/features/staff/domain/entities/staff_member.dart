import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Un agent du fichier du personnel : enseignant, administratif ou personnel
/// d'appui.
///
/// Ni montant ni pièce ici : ils ont leurs flux et leurs droits. La frise
/// [contracts] dit le statut à toute date, sans jamais dire combien.
class StaffMember extends Equatable {
  /// Uuid fabriqué par le poste qui a créé la fiche ; clé d'idempotence.
  final String id;

  /// `CF-AG-0048`, attribué par le serveur ; `null` tant qu'il ne l'a pas fait
  /// (« en attente »). Affiché tel quel, jamais construit ni découpé.
  final String? staffNumber;

  final String lastName;
  final String? middleName;
  final String firstName;
  final StaffSex? sex;

  /// Jours `YYYY-MM-DD`.
  final String? birthDate;
  final String? entryDate;

  /// En E.164 une fois passé par le serveur.
  final String? phoneNumber;
  final String? email;

  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;

  /// `null` pour une catégorie que ce poste ne connaît pas encore.
  final StaffCategory? category;
  final String? jobTitle;

  /// Matières qu'un enseignant déclare pouvoir tenir.
  final List<String> branches;
  final List<StaffDiploma> diplomas;

  /// La frise des contrats, sans montants, par date d'effet. Vide : « contrat
  /// à poser ».
  final List<StaffContractPeriod> contracts;

  final RecordSyncState syncState;

  const StaffMember({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.category,
    required this.syncState,
    this.staffNumber,
    this.middleName,
    this.sex,
    this.birthDate,
    this.entryDate,
    this.phoneNumber,
    this.email,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.jobTitle,
    this.branches = const [],
    this.diplomas = const [],
    this.contracts = const [],
  });

  /// La même fiche, portant [periods] pour frise — celle du serveur, complétée
  /// à la lecture par les gestes de contrat encore en attente sur le poste.
  StaffMember withContracts(List<StaffContractPeriod> periods) => StaffMember(
    id: id,
    staffNumber: staffNumber,
    lastName: lastName,
    middleName: middleName,
    firstName: firstName,
    sex: sex,
    birthDate: birthDate,
    entryDate: entryDate,
    phoneNumber: phoneNumber,
    email: email,
    city: city,
    district: district,
    municipality: municipality,
    neighborhood: neighborhood,
    address: address,
    category: category,
    jobTitle: jobTitle,
    branches: branches,
    diplomas: diplomas,
    contracts: periods,
    syncState: syncState,
  );

  /// « Nom Post-nom Prénom », l'ordre de l'état civil congolais.
  String get fullName => [
    lastName,
    middleName,
    firstName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    id,
    staffNumber,
    lastName,
    middleName,
    firstName,
    sex,
    birthDate,
    entryDate,
    phoneNumber,
    email,
    city,
    district,
    municipality,
    neighborhood,
    address,
    category,
    jobTitle,
    branches,
    diplomas,
    contracts,
    syncState,
  ];
}
