import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

/// Notation d'une sous-période : moyenne de classe, nombre d'élèves notés /
/// au-dessus de 50 %, moyennes par élève et évaluations groupées par type.
class SousPeriodeNotation extends Equatable {
  final String sousPeriodeId;
  final int ordre;
  final StatutPeriode statut;

  /// Moyenne générale de la classe (%) sur les élèves notés ; `null` si aucun.
  final double? moyenneClasse;
  final int nombreElevesNotes;

  /// Nombre d'élèves notés avec une moyenne >= 50 %.
  final int nombreEleves50;
  final List<MoyenneEleve> moyennesEleves;
  final List<EvaluationGroupe> evaluationsParType;

  /// Le nom que la grille donne à la sous-période (« Étape 3 ») ; `null` d'un
  /// serveur plus ancien.
  final IntituleColonne? intitule;

  const SousPeriodeNotation({
    required this.sousPeriodeId,
    required this.ordre,
    required this.statut,
    this.moyenneClasse,
    required this.nombreElevesNotes,
    required this.nombreEleves50,
    required this.moyennesEleves,
    required this.evaluationsParType,
    this.intitule,
  });

  @override
  List<Object?> get props => [
    sousPeriodeId,
    ordre,
    statut,
    moyenneClasse,
    nombreElevesNotes,
    nombreEleves50,
    moyennesEleves,
    evaluationsParType,
    intitule,
  ];
}
