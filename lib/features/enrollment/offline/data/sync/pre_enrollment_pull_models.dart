import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/pull_json_support.dart';

// Pull des préinscriptions en ligne — `GET /api/v1/sync/pre-enrollments`
// (miroir `openApi.yaml`). Delta keyset (ADR-008/009).

/// Page delta keyset des préinscriptions (enveloppe [KeysetPageEnvelope]).
class PreEnrollmentsPageDto implements KeysetPageDto<PreEnrollmentDto> {
  @override
  final List<PreEnrollmentDto> items;
  @override
  final KeysetPageEnvelope page;

  const PreEnrollmentsPageDto({required this.items, required this.page});

  factory PreEnrollmentsPageDto.fromJson(Map<String, dynamic> j) =>
      PreEnrollmentsPageDto(
        items: pullList(j['items'], PreEnrollmentDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

/// Préinscription portail parent. Alimente le repli Pré → Première (D4).
class PreEnrollmentDto {
  final String id; // id serveur
  final String firstName;
  final String lastName;
  final String surname;
  final String? gender;
  final String? dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? desiredSchoolLevelId;
  final String? guardianName;
  final String? guardianPhone;
  final String updatedAt; // ISO-8601

  const PreEnrollmentDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    this.gender,
    this.dateOfBirth,
    this.birthPlace,
    this.desiredSchoolLevelId,
    this.guardianName,
    this.guardianPhone,
    required this.updatedAt,
  });

  factory PreEnrollmentDto.fromJson(Map<String, dynamic> j) => PreEnrollmentDto(
    id: j['id'] as String,
    firstName: j['firstName'] as String,
    lastName: j['lastName'] as String,
    surname: (j['surname'] as String?) ?? '',
    gender: j['gender'] as String?,
    dateOfBirth: j['dateOfBirth'] as String?,
    birthPlace: j['birthPlace'] as String?,
    desiredSchoolLevelId: j['desiredSchoolLevelId'] as String?,
    guardianName: j['guardianName'] as String?,
    guardianPhone: j['guardianPhone'] as String?,
    updatedAt: j['updatedAt'] as String,
  );
}
