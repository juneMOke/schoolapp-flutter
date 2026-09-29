import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// Une période de la frise, sans montant (`StaffContractPeriod`).
class StaffContractPeriodDto {
  final String contractId;
  final String kind;
  final String? payMode;
  final String effectiveFrom;
  final String? endsOn;

  const StaffContractPeriodDto({
    required this.contractId,
    required this.kind,
    required this.effectiveFrom,
    this.payMode,
    this.endsOn,
  });

  static StaffContractPeriodDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final contractId = raw.text('contractId');
    final kind = raw.text('kind');
    final effectiveFrom = raw.day('effectiveFrom');
    if (contractId == null || kind == null || effectiveFrom == null) {
      return null;
    }
    return StaffContractPeriodDto(
      contractId: contractId,
      kind: kind,
      payMode: raw.text('payMode'),
      effectiveFrom: effectiveFrom,
      endsOn: raw.day('endsOn'),
    );
  }

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'kind': kind,
    'payMode': payMode,
    'effectiveFrom': effectiveFrom,
    'endsOn': endsOn,
  };
}

/// Un diplôme (`StaffDiploma`) — même forme à la montée et à la descente.
class StaffDiplomaDto {
  final String level;
  final String title;
  final String? institution;
  final int? graduationYear;

  const StaffDiplomaDto({
    required this.level,
    required this.title,
    this.institution,
    this.graduationYear,
  });

  static StaffDiplomaDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final level = raw.text('level');
    final title = raw.text('title');
    if (level == null || title == null) return null;
    return StaffDiplomaDto(
      level: level,
      title: title,
      institution: raw.text('institution'),
      graduationYear: raw.integer('graduationYear'),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'title': title,
    'institution': institution,
    'graduationYear': graduationYear,
  };
}

/// L'état canonique d'une fiche (`StaffMemberDelta`) — même forme dans le flux
/// et dans l'accusé.
///
/// Les champs exigés à la saisie peuvent manquer ici : un enseignant repris
/// d'avant le fichier du personnel a un dossier à compléter. Seuls l'`id`, le
/// nom, le prénom et la catégorie sont indispensables à l'affichage.
class StaffMemberDeltaDto {
  final String id;
  final String? staffNumber;
  final String lastName;
  final String? middleName;
  final String firstName;
  final String? sex;
  final String? birthDate;
  final String? phoneNumber;
  final String? email;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String category;
  final String? jobTitle;
  final String? entryDate;
  final List<String> branches;
  final List<StaffDiplomaDto> diplomas;
  final List<StaffContractPeriodDto> contracts;
  final String? clientUpdatedAt;
  final int? version;
  final String? serverUpdatedAt;

  const StaffMemberDeltaDto({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.category,
    this.staffNumber,
    this.middleName,
    this.sex,
    this.birthDate,
    this.phoneNumber,
    this.email,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.jobTitle,
    this.entryDate,
    this.branches = const [],
    this.diplomas = const [],
    this.contracts = const [],
    this.clientUpdatedAt,
    this.version,
    this.serverUpdatedAt,
  });

  static StaffMemberDeltaDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final lastName = raw.text('lastName');
    final firstName = raw.text('firstName');
    final category = raw.text('category');
    if (id == null ||
        lastName == null ||
        firstName == null ||
        category == null) {
      return null;
    }
    List<T> each<T>(String key, T? Function(Object?) parse) {
      final value = raw[key];
      if (value is! List) return const [];
      return [for (final item in value) ?parse(item)];
    }

    return StaffMemberDeltaDto(
      id: id,
      staffNumber: raw.text('staffNumber'),
      lastName: lastName,
      middleName: raw.text('middleName'),
      firstName: firstName,
      sex: raw.text('sex'),
      birthDate: raw.day('birthDate'),
      phoneNumber: raw.text('phoneNumber'),
      email: raw.text('email'),
      city: raw.text('city'),
      district: raw.text('district'),
      municipality: raw.text('municipality'),
      neighborhood: raw.text('neighborhood'),
      address: raw.text('address'),
      category: category,
      jobTitle: raw.text('jobTitle'),
      entryDate: raw.day('entryDate'),
      branches: raw.texts('branches'),
      diplomas: each('diplomas', StaffDiplomaDto.tryParse),
      contracts: each('contracts', StaffContractPeriodDto.tryParse),
      clientUpdatedAt: raw.instant('clientUpdatedAt'),
      version: raw.integer('version'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }
}

/// Page du flux `hr.staff-members`.
class StaffMemberPageDto extends ParsedKeysetPage<StaffMemberDeltaDto> {
  StaffMemberPageDto._(ParsedKeysetPage<StaffMemberDeltaDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StaffMemberPageDto.fromJson(Map<String, dynamic> json) =>
      StaffMemberPageDto._(
        ParsedKeysetPage.fromJson(json, StaffMemberDeltaDto.tryParse),
      );
}
