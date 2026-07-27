// DTOs du bundle `grades-referential` (`GET /sync/academics/grades-referential`,
// ETag applicatif, cadré prof, NON paginé). Contrat : `GradesReferentialBundle`
// = { branches[], ligneBaremes[], chapitres[], periodes[], sousPeriodes[],
// serverTime }. Parsing tolérant **par élément** (`_lenientList`, patron des
// autres pulls académiques) : une entrée malformée est écartée sans annuler le
// reste du bundle — la garde de clôture/plafonds en dépend.

import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_rows.dart';

List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Entrée écartée : le bundle ne fige pas.
    }
  }
  return out;
}

class BrancheDto {
  final String id;
  final String nom;
  final String? code;

  const BrancheDto({required this.id, required this.nom, this.code});

  factory BrancheDto.fromJson(Map<String, dynamic> j) => BrancheDto(
    id: j['id'] as String,
    nom: j['nom'] as String,
    code: j['code'] as String?,
  );

  RefBrancheRow toLocalRow() => RefBrancheRow(id: id, nom: nom, code: code);
}

class LigneBaremeDto {
  final String id;
  final String grilleId;
  final String rubriqueId;
  final String brancheId;
  final int ordre;
  final int maxJournalierParSousPeriode;
  final int? maxExamenParPeriodeScolaire;

  const LigneBaremeDto({
    required this.id,
    required this.grilleId,
    required this.rubriqueId,
    required this.brancheId,
    required this.ordre,
    required this.maxJournalierParSousPeriode,
    this.maxExamenParPeriodeScolaire,
  });

  factory LigneBaremeDto.fromJson(Map<String, dynamic> j) => LigneBaremeDto(
    id: j['id'] as String,
    grilleId: j['grilleId'] as String,
    rubriqueId: j['rubriqueId'] as String,
    brancheId: j['brancheId'] as String,
    ordre: (j['ordre'] as num?)?.toInt() ?? 0,
    maxJournalierParSousPeriode:
        (j['maxJournalierParSousPeriode'] as num?)?.toInt() ?? 0,
    maxExamenParPeriodeScolaire: (j['maxExamenParPeriodeScolaire'] as num?)
        ?.toInt(),
  );

  RefLigneBaremeRow toLocalRow() => RefLigneBaremeRow(
    id: id,
    grilleId: grilleId,
    rubriqueId: rubriqueId,
    brancheId: brancheId,
    ordre: ordre,
    maxJournalierParSousPeriode: maxJournalierParSousPeriode,
    maxExamenParPeriodeScolaire: maxExamenParPeriodeScolaire,
  );
}

class ChapitreDto {
  final String id;
  final String coursId;
  final String titre;
  final int ordre;

  const ChapitreDto({
    required this.id,
    required this.coursId,
    required this.titre,
    required this.ordre,
  });

  factory ChapitreDto.fromJson(Map<String, dynamic> j) => ChapitreDto(
    id: j['id'] as String,
    coursId: j['coursId'] as String,
    titre: j['titre'] as String,
    ordre: (j['ordre'] as num?)?.toInt() ?? 0,
  );

  RefChapitreRow toLocalRow() =>
      RefChapitreRow(id: id, coursId: coursId, titre: titre, ordre: ordre);
}

class PeriodeDto {
  final String id;
  final String academicYearId;
  final String schoolLevelGroupId;
  final int ordre;
  final String statut;
  final String? startDate;
  final String? endDate;

  const PeriodeDto({
    required this.id,
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.ordre,
    required this.statut,
    this.startDate,
    this.endDate,
  });

  factory PeriodeDto.fromJson(Map<String, dynamic> j) => PeriodeDto(
    id: j['id'] as String,
    academicYearId: j['academicYearId'] as String,
    schoolLevelGroupId: j['schoolLevelGroupId'] as String,
    ordre: (j['ordre'] as num?)?.toInt() ?? 0,
    statut: (j['statut'] as String?) ?? 'UNKNOWN',
    startDate: j['startDate'] as String?,
    endDate: j['endDate'] as String?,
  );

  RefPeriodeRow toLocalRow() => RefPeriodeRow(
    id: id,
    academicYearId: academicYearId,
    schoolLevelGroupId: schoolLevelGroupId,
    ordre: ordre,
    statut: statut,
    startDate: startDate,
    endDate: endDate,
  );
}

class SousPeriodeDto {
  final String id;
  final String periodeScolaireId;
  final int ordre;
  final String statut;
  final String? startDate;
  final String? endDate;

  const SousPeriodeDto({
    required this.id,
    required this.periodeScolaireId,
    required this.ordre,
    required this.statut,
    this.startDate,
    this.endDate,
  });

  factory SousPeriodeDto.fromJson(Map<String, dynamic> j) => SousPeriodeDto(
    id: j['id'] as String,
    periodeScolaireId: j['periodeScolaireId'] as String,
    ordre: (j['ordre'] as num?)?.toInt() ?? 0,
    statut: (j['statut'] as String?) ?? 'UNKNOWN',
    startDate: j['startDate'] as String?,
    endDate: j['endDate'] as String?,
  );

  RefSousPeriodeRow toLocalRow() => RefSousPeriodeRow(
    id: id,
    periodeScolaireId: periodeScolaireId,
    ordre: ordre,
    statut: statut,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Bundle complet — `serverTime` n'est pas persisté (indicatif, hors ETag).
class GradesReferentialBundleDto {
  final List<BrancheDto> branches;
  final List<LigneBaremeDto> ligneBaremes;
  final List<ChapitreDto> chapitres;
  final List<PeriodeDto> periodes;
  final List<SousPeriodeDto> sousPeriodes;

  const GradesReferentialBundleDto({
    required this.branches,
    required this.ligneBaremes,
    required this.chapitres,
    required this.periodes,
    required this.sousPeriodes,
  });

  factory GradesReferentialBundleDto.fromJson(Map<String, dynamic> j) =>
      GradesReferentialBundleDto(
        branches: _lenientList(j['branches'], BrancheDto.fromJson),
        ligneBaremes: _lenientList(j['ligneBaremes'], LigneBaremeDto.fromJson),
        chapitres: _lenientList(j['chapitres'], ChapitreDto.fromJson),
        periodes: _lenientList(j['periodes'], PeriodeDto.fromJson),
        sousPeriodes: _lenientList(j['sousPeriodes'], SousPeriodeDto.fromJson),
      );
}
