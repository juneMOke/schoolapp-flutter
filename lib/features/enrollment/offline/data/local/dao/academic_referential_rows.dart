/// Lignes brutes lues depuis les tables référentiel (`ref_academic_years`,
/// `ref_school_level_groups`, `ref_school_levels`) — mappées en entités
/// domaine par le repository appelant (règle Modèle → Entité dans le
/// repository), jamais exposées telles quelles hors de la couche data.
/// Identité de l'école (`ref_school`), cache mono-ligne du device.
class SchoolRow {
  final String id;
  final String name;
  final String? country;
  final String? city;
  final String? district;
  final String? municipality;
  final String? address;
  final String? phone;
  final String? email;

  const SchoolRow({
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
}

class AcademicYearRow {
  final String id;
  final String name;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;

  const AcademicYearRow({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.isCurrent,
  });
}

class SchoolLevelGroupRow {
  final String id;
  final String name;
  final String code;
  final String? periodType;
  final int displayOrder;

  const SchoolLevelGroupRow({
    required this.id,
    required this.name,
    required this.code,
    this.periodType,
    required this.displayOrder,
  });
}

class SchoolLevelRow {
  final String id;
  final String name;
  final String code;
  final String levelGroupId;
  final int displayOrder;
  final bool splitIntoClassrooms;

  const SchoolLevelRow({
    required this.id,
    required this.name,
    required this.code,
    required this.levelGroupId,
    required this.displayOrder,
    required this.splitIntoClassrooms,
  });
}
