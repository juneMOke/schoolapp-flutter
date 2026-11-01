import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

/// Une cellule rendue par le chargement. [colonneId] est sa sous-période, ou la
/// période si c'est un examen : jamais les deux au fil.
class CoteCelluleDto {
  final String studentId;
  final String coursId;
  final String colonneId;
  final bool examen;
  final double? cote;
  final double? calculee;
  final int? updatedAtMs;

  const CoteCelluleDto({
    required this.studentId,
    required this.coursId,
    required this.colonneId,
    required this.examen,
    this.cote,
    this.calculee,
    this.updatedAtMs,
  });

  /// `null` si la ligne est inutilisable : elle est sautée, sans faire échouer
  /// le chargement d'une classe entière.
  static CoteCelluleDto? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final studentId = raw['studentId'];
    final coursId = raw['coursId'];
    final sousPeriodeId = raw['sousPeriodeId'];
    final periodeId = raw['periodeScolaireId'];
    final colonneId = sousPeriodeId ?? periodeId;
    if (studentId is! String || coursId is! String || colonneId is! String) {
      return null;
    }
    final cote = raw['cote'];
    final calculee = raw['calculee'];
    return CoteCelluleDto(
      studentId: studentId,
      coursId: coursId,
      colonneId: colonneId,
      examen: sousPeriodeId == null,
      cote: cote is num ? cote.toDouble() : null,
      calculee: calculee is num ? calculee.toDouble() : null,
      updatedAtMs: EpochIsoHelper.tryToEpochMs(raw['updatedAt']),
    );
  }
}

/// La réponse de `GET /academics/cotes`. La structure sans ses cellules est
/// gardée brute ([structure]) : c'est elle que le cache rejoue.
class CoteClasseDto {
  final Map<String, dynamic> structure;
  final List<CoteCelluleDto> cellules;

  const CoteClasseDto({required this.structure, required this.cellules});

  /// Lève [FormatException] si la structure est illisible : sans calendrier
  /// fiable, aucune cellule ne se place.
  factory CoteClasseDto.fromJson(Map<String, dynamic> json) {
    final cellules = <CoteCelluleDto>[];
    for (final raw in (json['cellules'] as List<dynamic>?) ?? const []) {
      final cellule = CoteCelluleDto.tryParse(raw);
      if (cellule != null) cellules.add(cellule);
    }
    final structure = {...json}..remove('cellules');
    final dto = CoteClasseDto(structure: structure, cellules: cellules);
    dto.toEntity();
    return dto;
  }

  CoteClasse toEntity() => coteClasseFromStructure(structure);
}

/// La structure d'une classe, du fil ou du cache.
CoteClasse coteClasseFromStructure(Map<String, dynamic> json) {
  return CoteClasse(
    // L'écran se fie à la classe qu'il a demandée, pas à cet écho.
    classroomId: json['classroomId'] as String? ?? '',
    decoupage: DecoupageX.fromApiValue(json['periodType'] as String?),
    periodes: _list(json['periodes'], _periode),
    rubriques: _list(json['rubriques'], _rubrique),
    eleves: _list(json['eleves'], _eleve),
  );
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) => [
  for (final item in (raw as List<dynamic>?) ?? const [])
    if (item is Map<String, dynamic>) parse(item),
];

String _id(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key absent');
  }
  return value;
}

int _int(Object? value) => value is num ? value.toInt() : 0;

CotePeriode _periode(Map<String, dynamic> json) => CotePeriode(
  id: _id(json, 'id'),
  ordre: _int(json['ordre']),
  libelle: json['libelle'] as String? ?? '',
  courant: json['courant'] == true,
  locked: json['locked'] == true,
  sousPeriodes: _list(json['sousPeriodes'], _sousPeriode),
);

CoteSousPeriode _sousPeriode(Map<String, dynamic> json) => CoteSousPeriode(
  id: _id(json, 'id'),
  ordre: _int(json['ordre']),
  locked: json['locked'] == true,
);

CoteRubrique _rubrique(Map<String, dynamic> json) => CoteRubrique(
  id: _id(json, 'id'),
  label: json['label'] as String?,
  produitSousTotal: json['produitSousTotal'] == true,
  sousRubriques: _list(json['sousRubriques'], _rubrique),
  cours: _list(json['cours'], _cours),
);

CoteCours _cours(Map<String, dynamic> json) => CoteCours(
  coursId: _id(json, 'coursId'),
  branche: json['branche'] as String? ?? '',
  maxJournalier: _int(json['maxJournalier']),
  maxExamen: _int(json['maxExamen']),
);

CoteEleve _eleve(Map<String, dynamic> json) => CoteEleve(
  studentId: _id(json, 'studentId'),
  lastName: json['lastName'] as String? ?? '',
  middleName: json['middleName'] as String?,
  firstName: json['firstName'] as String? ?? '',
);
