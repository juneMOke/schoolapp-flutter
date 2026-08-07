import 'package:equatable/equatable.dart';

/// Lignes sqflite du bundle `grades-referential` (ETag, remplacement
/// d'ensemble à chaque pull — pas de delta, pas de `synced_at` par ligne : la
/// fraîcheur est portée globalement par `sync_meta` sur la ressource bundle).

int? _asIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// `ref_branche` — branche académique.
class RefBrancheRow extends Equatable {
  final String id;
  final String nom;
  final String? code;

  const RefBrancheRow({required this.id, required this.nom, this.code});

  factory RefBrancheRow.fromMap(Map<String, Object?> map) => RefBrancheRow(
    id: map['id'] as String,
    nom: map['nom'] as String,
    code: map['code'] as String?,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'nom': nom,
    'code': code,
  };

  @override
  List<Object?> get props => [id, nom, code];
}

/// `ref_ligne_bareme` — plafonds de saisie + pont vers la branche.
/// `maxExamenParPeriodeScolaire` **nullable** = branche sans examen (≠ 0).
class RefLigneBaremeRow extends Equatable {
  final String id;
  final String grilleId;
  final String rubriqueId;
  final String brancheId;
  final int ordre;
  final int maxJournalierParSousPeriode;
  final int? maxExamenParPeriodeScolaire;

  const RefLigneBaremeRow({
    required this.id,
    required this.grilleId,
    required this.rubriqueId,
    required this.brancheId,
    required this.ordre,
    required this.maxJournalierParSousPeriode,
    this.maxExamenParPeriodeScolaire,
  });

  factory RefLigneBaremeRow.fromMap(Map<String, Object?> map) =>
      RefLigneBaremeRow(
        id: map['id'] as String,
        grilleId: map['grille_id'] as String,
        rubriqueId: map['rubrique_id'] as String,
        brancheId: map['branche_id'] as String,
        ordre: _asIntOrNull(map['ordre']) ?? 0,
        maxJournalierParSousPeriode:
            _asIntOrNull(map['max_journalier_par_sous_periode']) ?? 0,
        maxExamenParPeriodeScolaire: _asIntOrNull(
          map['max_examen_par_periode_scolaire'],
        ),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'grille_id': grilleId,
    'rubrique_id': rubriqueId,
    'branche_id': brancheId,
    'ordre': ordre,
    'max_journalier_par_sous_periode': maxJournalierParSousPeriode,
    'max_examen_par_periode_scolaire': maxExamenParPeriodeScolaire,
  };

  @override
  List<Object?> get props => [
    id,
    grilleId,
    rubriqueId,
    brancheId,
    ordre,
    maxJournalierParSousPeriode,
    maxExamenParPeriodeScolaire,
  ];
}

/// `ref_chapitre` — chapitre d'un cours (`contenu` volontairement omis).
class RefChapitreRow extends Equatable {
  final String id;
  final String coursId;
  final String titre;
  final int ordre;

  const RefChapitreRow({
    required this.id,
    required this.coursId,
    required this.titre,
    required this.ordre,
  });

  factory RefChapitreRow.fromMap(Map<String, Object?> map) => RefChapitreRow(
    id: map['id'] as String,
    coursId: map['cours_id'] as String,
    titre: map['titre'] as String,
    ordre: _asIntOrNull(map['ordre']) ?? 0,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'cours_id': coursId,
    'titre': titre,
    'ordre': ordre,
  };

  @override
  List<Object?> get props => [id, coursId, titre, ordre];
}

/// `ref_periode` — période scolaire à plat, portée année × groupe de niveau.
class RefPeriodeRow extends Equatable {
  final String id;
  final String academicYearId;
  final String schoolLevelGroupId;
  final int ordre;
  final String statut;
  final String? startDate;
  final String? endDate;

  const RefPeriodeRow({
    required this.id,
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.ordre,
    required this.statut,
    this.startDate,
    this.endDate,
  });

  factory RefPeriodeRow.fromMap(Map<String, Object?> map) => RefPeriodeRow(
    id: map['id'] as String,
    academicYearId: map['academic_year_id'] as String,
    schoolLevelGroupId: map['school_level_group_id'] as String,
    ordre: _asIntOrNull(map['ordre']) ?? 0,
    statut: (map['statut'] as String?) ?? 'UNKNOWN',
    startDate: map['start_date'] as String?,
    endDate: map['end_date'] as String?,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'academic_year_id': academicYearId,
    'school_level_group_id': schoolLevelGroupId,
    'ordre': ordre,
    'statut': statut,
    'start_date': startDate,
    'end_date': endDate,
  };

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    schoolLevelGroupId,
    ordre,
    statut,
    startDate,
    endDate,
  ];
}

/// `ref_sous_periode` — sous-période à plat, lien parent + statut.
class RefSousPeriodeRow extends Equatable {
  final String id;
  final String periodeScolaireId;
  final int ordre;
  final String statut;
  final String? startDate;
  final String? endDate;

  const RefSousPeriodeRow({
    required this.id,
    required this.periodeScolaireId,
    required this.ordre,
    required this.statut,
    this.startDate,
    this.endDate,
  });

  factory RefSousPeriodeRow.fromMap(Map<String, Object?> map) =>
      RefSousPeriodeRow(
        id: map['id'] as String,
        periodeScolaireId: map['periode_scolaire_id'] as String,
        ordre: _asIntOrNull(map['ordre']) ?? 0,
        statut: (map['statut'] as String?) ?? 'UNKNOWN',
        startDate: map['start_date'] as String?,
        endDate: map['end_date'] as String?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'periode_scolaire_id': periodeScolaireId,
    'ordre': ordre,
    'statut': statut,
    'start_date': startDate,
    'end_date': endDate,
  };

  @override
  List<Object?> get props => [
    id,
    periodeScolaireId,
    ordre,
    statut,
    startDate,
    endDate,
  ];
}
