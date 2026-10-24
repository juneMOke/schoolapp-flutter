import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Pièces exigées par le contrat en vigueur, et combien sont versées.
class HrDossierCount extends Equatable {
  final int provided;
  final int required;

  const HrDossierCount({required this.provided, required this.required});

  @override
  List<Object?> get props => [provided, required];
}

/// Un agent de la liste « Qui sont-ils », tel que le serveur le sert
/// (`GET /hr/staff-stats/members`) : contrat et ancienneté au jour de
/// l'école, **aucun montant**. Les `null` disent « non renseigné ».
class HrStaffMemberRow extends Equatable {
  final String id;

  /// Attribué par le serveur à la première remontée : toujours renseigné
  /// ici, l'agent pas encore remonté n'étant pas dans la liste.
  final String staffNumber;
  final String lastName;
  final String? middleName;
  final String? firstName;
  final StaffSex? sex;
  final HrCategoryKey category;
  final String? jobTitle;
  final String? entryDate;

  /// Années révolues au jour de l'école ; `null` sans date d'entrée, 0 pour
  /// une entrée à venir.
  final int? seniorityYears;

  /// Le contrat en vigueur ; `null` sans contrat en cours.
  final StaffContractKind? contractKind;

  /// Absent sans `hr.document.read`.
  final HrDossierCount? dossier;

  const HrStaffMemberRow({
    required this.id,
    required this.staffNumber,
    required this.lastName,
    required this.middleName,
    required this.firstName,
    required this.sex,
    required this.category,
    required this.jobTitle,
    required this.entryDate,
    required this.seniorityYears,
    required this.contractKind,
    required this.dossier,
  });

  /// « KABASELE Mwamba Marie » : nom, post-nom, prénom — l'ordre du fichier.
  String get fullName => [
    lastName,
    middleName ?? '',
    firstName ?? '',
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
    id,
    staffNumber,
    lastName,
    middleName,
    firstName,
    sex,
    category,
    jobTitle,
    entryDate,
    seniorityYears,
    contractKind,
    dossier,
  ];
}

/// Une page de la liste : filtrée **avant** d'être découpée.
class HrStaffMembersPage extends Equatable {
  final int totalElements;

  /// À partir de 0.
  final int page;
  final int size;
  final List<HrStaffMemberRow> items;

  const HrStaffMembersPage({
    required this.totalElements,
    required this.page,
    required this.size,
    required this.items,
  });

  int get totalPages => size <= 0 ? 0 : (totalElements + size - 1) ~/ size;

  @override
  List<Object?> get props => [totalElements, page, size, items];
}
