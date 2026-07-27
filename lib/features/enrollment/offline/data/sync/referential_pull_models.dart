import 'package:school_app_flutter/features/enrollment/offline/data/sync/pull_json_support.dart';

// Pull du socle référentiel — `GET /api/v1/sync/referential`
// (miroir `openApi.yaml`, amendé par `PLAN_referential_current_previous_FRONT.md`).
// Bundle always-200, gelé sur la saison (D2). Lecture seule → `fromJson`.

/// Bundle racine : identité de l'école + deux slots année (`current`/`previous`).
/// Bundle full **always-200** (jamais 304), gelé sur la saison. `previous` est
/// `null` quand l'école n'a pas d'année antérieure (première année) — jamais un
/// slot vide.
class ReferentialBundleDto {
  final RefSchoolDto school;
  final ReferentialYearBundleDto current;
  final ReferentialYearBundleDto? previous;
  final String serverTime; // ISO-8601

  const ReferentialBundleDto({
    required this.school,
    required this.current,
    this.previous,
    required this.serverTime,
  });

  factory ReferentialBundleDto.fromJson(Map<String, dynamic> j) =>
      ReferentialBundleDto(
        school: RefSchoolDto.fromJson(j['school'] as Map<String, dynamic>),
        current: ReferentialYearBundleDto.fromJson(
          j['current'] as Map<String, dynamic>,
        ),
        previous: j['previous'] == null
            ? null
            : ReferentialYearBundleDto.fromJson(
                j['previous'] as Map<String, dynamic>,
              ),
        serverTime: j['serverTime'] as String,
      );
}

/// Identité du tenant (école) — racine du bundle, pas rattachée à une année
/// (D5). Réutilisable tel quel si un `SchoolDto` équivalent existe déjà
/// ailleurs côté serveur ; ici greenfield côté front (D6).
class RefSchoolDto {
  final String id;
  final String name;
  final String? country;
  final String? city;
  final String? district;
  final String? municipality;
  final String? address;
  final String? phone;
  final String? email;

  const RefSchoolDto({
    required this.id,
    required this.name,
    this.country,
    this.city,
    this.district,
    this.municipality,
    this.address,
    this.phone,
    this.email,
  });

  factory RefSchoolDto.fromJson(Map<String, dynamic> j) => RefSchoolDto(
    id: j['id'] as String,
    name: j['name'] as String,
    country: j['country'] as String?,
    city: j['city'] as String?,
    district: j['district'] as String?,
    municipality: j['municipality'] as String?,
    address: j['address'] as String?,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
  );
}

/// Socle d'une année (`current` ou `previous`) : année + cycles/niveaux/tarifs
/// de CETTE année. `current`/`previous` partagent exactement cette forme (D2).
class ReferentialYearBundleDto {
  final RefAcademicYearDto academicYear;
  final List<RefSchoolLevelGroupDto> schoolLevelGroups;
  final List<RefSchoolLevelDto> schoolLevels;
  final List<RefFeeTariffDto> feeTariffs;

  const ReferentialYearBundleDto({
    required this.academicYear,
    required this.schoolLevelGroups,
    required this.schoolLevels,
    required this.feeTariffs,
  });

  factory ReferentialYearBundleDto.fromJson(Map<String, dynamic> j) =>
      ReferentialYearBundleDto(
        academicYear: RefAcademicYearDto.fromJson(
          j['academicYear'] as Map<String, dynamic>,
        ),
        schoolLevelGroups: pullList(
          j['schoolLevelGroups'],
          RefSchoolLevelGroupDto.fromJson,
        ),
        schoolLevels: pullList(j['schoolLevels'], RefSchoolLevelDto.fromJson),
        feeTariffs: pullList(j['feeTariffs'], RefFeeTariffDto.fromJson),
      );
}

/// Année scolaire. `isCurrent` pré-sélectionne l'année active hors-ligne. La
/// clé wire est `current` (contrat `openApi.yaml`) — le champ Dart reste
/// `isCurrent`. `startDate`/`endDate` sont des `date-time` ISO-8601.
class RefAcademicYearDto {
  final String id;
  final String name;
  final String? startDate; // ISO-8601 (date-time)
  final String? endDate; // ISO-8601 (date-time)
  final bool isCurrent;

  const RefAcademicYearDto({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.isCurrent,
  });

  factory RefAcademicYearDto.fromJson(Map<String, dynamic> j) =>
      RefAcademicYearDto(
        id: j['id'] as String,
        name: j['name'] as String,
        startDate: j['startDate'] as String?,
        endDate: j['endDate'] as String?,
        isCurrent: (j['current'] as bool?) ?? false,
      );
}

/// Cycle (`SchoolLevelGroup`). `periodType` = pont vers l'Académique.
class RefSchoolLevelGroupDto {
  final String id;
  final String name;
  final String code;
  final String? periodType;
  final String academicYearId;
  final int displayOrder;

  const RefSchoolLevelGroupDto({
    required this.id,
    required this.name,
    required this.code,
    this.periodType,
    required this.academicYearId,
    required this.displayOrder,
  });

  factory RefSchoolLevelGroupDto.fromJson(Map<String, dynamic> j) =>
      RefSchoolLevelGroupDto(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        periodType: j['periodType'] as String?,
        academicYearId: j['academicYearId'] as String,
        displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
      );
}

/// Niveau (`SchoolLevel`). `splitIntoClassrooms` pilote la répartition (Classe).
class RefSchoolLevelDto {
  final String id;
  final String name;
  final String code;
  final String levelGroupId;
  final int displayOrder;
  final bool splitIntoClassrooms;

  const RefSchoolLevelDto({
    required this.id,
    required this.name,
    required this.code,
    required this.levelGroupId,
    required this.displayOrder,
    required this.splitIntoClassrooms,
  });

  factory RefSchoolLevelDto.fromJson(Map<String, dynamic> j) =>
      RefSchoolLevelDto(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        levelGroupId: j['levelGroupId'] as String,
        displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
        splitIntoClassrooms: (j['splitIntoClassrooms'] as bool?) ?? false,
      );
}

/// Ligne de la grille tarifaire. Montant en centimes entiers.
class RefFeeTariffDto {
  final String id;
  final String feeCode;
  final String? label;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final int amountInCents;
  final String currency;
  final String academicYearId;
  final String? dueAt; // ISO-8601

  const RefFeeTariffDto({
    required this.id,
    required this.feeCode,
    this.label,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.amountInCents,
    required this.currency,
    required this.academicYearId,
    this.dueAt,
  });

  factory RefFeeTariffDto.fromJson(Map<String, dynamic> j) => RefFeeTariffDto(
    id: j['id'] as String,
    feeCode: j['feeCode'] as String,
    label: j['label'] as String?,
    schoolLevelGroupId: j['schoolLevelGroupId'] as String,
    schoolLevelId: j['schoolLevelId'] as String,
    amountInCents: (j['amountInCents'] as num).toInt(),
    currency: j['currency'] as String,
    academicYearId: j['academicYearId'] as String,
    dueAt: j['dueAt'] as String?,
  );
}
