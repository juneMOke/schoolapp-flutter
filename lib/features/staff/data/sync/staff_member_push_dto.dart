import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';

// Modèles de la remontée d'une fiche (`POST /api/v1/sync/staff-members`).
//
// ⚠️ Le round-trip `toJson` → `fromJson` EST le chemin du push : l'outbox
// range le texte, le handler le relit avant de pousser. Un champ perdu à la
// relecture partirait muet — d'où des tests jugés sur du JSON brut.

/// La fiche entière, telle que le poste la pousse. Ni montant, ni contrat, ni
/// matricule : le serveur ignorerait un champ de plus.
class StaffMemberInputDto {
  final String id;
  final String lastName;
  final String middleName;
  final String firstName;
  final String sex;
  final String? birthDate;
  final String phoneNumber;
  final String? email;
  final String? city;
  final String district;
  final String municipality;
  final String neighborhood;
  final String? address;
  final String category;
  final String jobTitle;
  final String entryDate;
  final List<String> branches;
  final List<StaffDiplomaDto> diplomas;
  final String clientUpdatedAt;

  const StaffMemberInputDto({
    required this.id,
    required this.lastName,
    required this.middleName,
    required this.firstName,
    required this.sex,
    required this.phoneNumber,
    required this.district,
    required this.municipality,
    required this.neighborhood,
    required this.category,
    required this.jobTitle,
    required this.entryDate,
    required this.clientUpdatedAt,
    this.birthDate,
    this.email,
    this.city,
    this.address,
    this.branches = const [],
    this.diplomas = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'middleName': middleName,
    'firstName': firstName,
    'sex': sex,
    'birthDate': birthDate,
    'phoneNumber': phoneNumber,
    'email': email,
    'city': city,
    'district': district,
    'municipality': municipality,
    'neighborhood': neighborhood,
    'address': address,
    'category': category,
    'jobTitle': jobTitle,
    'entryDate': entryDate,
    'branches': branches,
    'diplomas': [for (final d in diplomas) d.toJson()],
    'clientUpdatedAt': clientUpdatedAt,
  };

  static StaffMemberInputDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final required = {
      for (final key in [
        'id',
        'lastName',
        'middleName',
        'firstName',
        'sex',
        'phoneNumber',
        'district',
        'municipality',
        'neighborhood',
        'category',
        'jobTitle',
      ])
        key: raw.text(key),
    };
    final entryDate = raw.day('entryDate');
    final clientUpdatedAt = raw.text('clientUpdatedAt');
    if (required.values.any((v) => v == null) ||
        entryDate == null ||
        clientUpdatedAt == null) {
      return null;
    }
    final diplomas = raw['diplomas'];
    return StaffMemberInputDto(
      id: required['id']!,
      lastName: required['lastName']!,
      middleName: required['middleName']!,
      firstName: required['firstName']!,
      sex: required['sex']!,
      birthDate: raw.day('birthDate'),
      phoneNumber: required['phoneNumber']!,
      email: raw.text('email'),
      city: raw.text('city'),
      district: required['district']!,
      municipality: required['municipality']!,
      neighborhood: required['neighborhood']!,
      address: raw.text('address'),
      category: required['category']!,
      jobTitle: required['jobTitle']!,
      entryDate: entryDate,
      branches: raw.texts('branches'),
      diplomas: [
        if (diplomas is List)
          for (final item in diplomas) ?StaffDiplomaDto.tryParse(item),
      ],
      clientUpdatedAt: clientUpdatedAt,
    );
  }
}

/// Le corps d'une remontée : la fiche et l'auteur du geste.
class StaffMemberSyncRequestDto {
  final StaffMemberInputDto staffMember;
  final String authorId;

  const StaffMemberSyncRequestDto({
    required this.staffMember,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'staffMember': staffMember.toJson(),
    kOutboxAuthorIdKey: authorId,
  };

  static StaffMemberSyncRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final member = StaffMemberInputDto.tryParse(raw['staffMember']);
    final authorId = raw.text(kOutboxAuthorIdKey);
    if (member == null || authorId == null) return null;
    return StaffMemberSyncRequestDto(staffMember: member, authorId: authorId);
  }
}

/// L'accusé : l'état retenu par le serveur, qu'il ait retenu l'écriture
/// (`APPLIED`) ou non (`SUPERSEDED`).
class StaffMemberSyncResponseDto {
  final StaffMemberDeltaDto staffMember;
  final String lwwOutcome;

  const StaffMemberSyncResponseDto({
    required this.staffMember,
    required this.lwwOutcome,
  });

  factory StaffMemberSyncResponseDto.fromJson(Map<String, dynamic> json) {
    final member = StaffMemberDeltaDto.tryParse(json['staffMember']);
    if (member == null) {
      throw const FormatException('Accusé de fiche illisible');
    }
    return StaffMemberSyncResponseDto(
      staffMember: member,
      lwwOutcome: (json['lwwOutcome'] as String?) ?? 'APPLIED',
    );
  }
}
