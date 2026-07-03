import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe_stats.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/sous_periode_colonne.dart';

/// Vue classe : table roster × sous-période + synthèse de classe, pour un couple
/// (classe, grande période). Tout est calculé live côté backend (lecture seule).
///
/// [periodeOrdre] (1..N) est traduit côté UI en libellé T{n} / S{n} selon le
/// `periodType` du cycle. [sousPeriodes] et [lignes] arrivent **déjà ordonnés**
/// (non classés en fin) : ne pas re-trier.
class ResultatsClasse extends Equatable {
  final String classroomId;
  final String periodeScolaireId;
  final int periodeOrdre;

  /// Colonnes de la table (« 1ère P. », « 2ème P. »…).
  final List<SousPeriodeColonne> sousPeriodes;
  final ResultatsClasseStats stats;

  /// Lignes élèves (déjà triées : non classés en fin).
  final List<ResultatEleveLigne> lignes;

  const ResultatsClasse({
    required this.classroomId,
    required this.periodeScolaireId,
    required this.periodeOrdre,
    required this.sousPeriodes,
    required this.stats,
    required this.lignes,
  });

  @override
  List<Object?> get props => [
    classroomId,
    periodeScolaireId,
    periodeOrdre,
    sousPeriodes,
    stats,
    lignes,
  ];
}
