import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// Une fiche en cours de saisie — création ou modification.
///
/// Tout est ici tel que saisi : c'est la validation qui juge, et le dépôt qui
/// normalise (téléphone en E.164, diplômes vides écartés) au moment d'écrire.
class StaffMemberDraft extends Equatable {
  /// Uuid de la fiche : fabriqué à la création, repris à la modification.
  final String id;
  final String lastName;
  final String middleName;
  final String firstName;
  final StaffSex? sex;

  /// Jours `YYYY-MM-DD`, ou `null`.
  final String? birthDate;
  final String? entryDate;
  final String phone;
  final String email;
  final String city;
  final String district;
  final String municipality;
  final String neighborhood;
  final String address;
  final StaffCategory? category;
  final String jobTitle;
  final List<String> branches;
  final List<StaffDiploma> diplomas;

  const StaffMemberDraft({
    required this.id,
    this.lastName = '',
    this.middleName = '',
    this.firstName = '',
    this.sex,
    this.birthDate,
    this.entryDate,
    this.phone = '',
    this.email = '',
    this.city = '',
    this.district = '',
    this.municipality = '',
    this.neighborhood = '',
    this.address = '',
    this.category,
    this.jobTitle = '',
    this.branches = const [],
    this.diplomas = const [],
  });

  factory StaffMemberDraft.of(StaffMember member) => StaffMemberDraft(
    id: member.id,
    lastName: member.lastName,
    middleName: member.middleName ?? '',
    firstName: member.firstName,
    sex: member.sex,
    birthDate: member.birthDate,
    entryDate: member.entryDate,
    phone: member.phoneNumber ?? '',
    email: member.email ?? '',
    city: member.city ?? '',
    district: member.district ?? '',
    municipality: member.municipality ?? '',
    neighborhood: member.neighborhood ?? '',
    address: member.address ?? '',
    category: member.category,
    jobTitle: member.jobTitle ?? '',
    branches: member.branches,
    diplomas: member.diplomas,
  );

  /// Une fiche neuve, préremplie avec les mots d'une recherche restée vide :
  /// un mot → le nom ; deux → nom et prénom ; trois et plus → nom, post-nom,
  /// puis le reste en prénom (l'ordre de l'état civil).
  factory StaffMemberDraft.fromSearch(
    String id,
    String text, {
    String city = '',
  }) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return StaffMemberDraft(
      id: id,
      city: city,
      lastName: words.isNotEmpty ? words.first : '',
      middleName: words.length >= 3 ? words[1] : '',
      firstName: switch (words.length) {
        0 || 1 => '',
        2 => words[1],
        _ => words.sublist(2).join(' '),
      },
    );
  }

  /// Les matières n'ont de sens que pour un enseignant : le serveur les
  /// ignore sinon, le poste les efface pour ne pas les montrer.
  bool get isTeacher => category == StaffCategory.teacher;

  StaffMemberDraft copyWith({
    String? lastName,
    String? middleName,
    String? firstName,
    StaffSex? Function()? sex,
    String? Function()? birthDate,
    String? Function()? entryDate,
    String? phone,
    String? email,
    String? city,
    String? district,
    String? municipality,
    String? neighborhood,
    String? address,
    StaffCategory? Function()? category,
    String? jobTitle,
    List<String>? branches,
    List<StaffDiploma>? diplomas,
  }) => StaffMemberDraft(
    id: id,
    lastName: lastName ?? this.lastName,
    middleName: middleName ?? this.middleName,
    firstName: firstName ?? this.firstName,
    sex: sex == null ? this.sex : sex(),
    birthDate: birthDate == null ? this.birthDate : birthDate(),
    entryDate: entryDate == null ? this.entryDate : entryDate(),
    phone: phone ?? this.phone,
    email: email ?? this.email,
    city: city ?? this.city,
    district: district ?? this.district,
    municipality: municipality ?? this.municipality,
    neighborhood: neighborhood ?? this.neighborhood,
    address: address ?? this.address,
    category: category == null ? this.category : category(),
    jobTitle: jobTitle ?? this.jobTitle,
    branches: branches ?? this.branches,
    diplomas: diplomas ?? this.diplomas,
  );

  @override
  List<Object?> get props => [
    id,
    lastName,
    middleName,
    firstName,
    sex,
    birthDate,
    entryDate,
    phone,
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
  ];
}
