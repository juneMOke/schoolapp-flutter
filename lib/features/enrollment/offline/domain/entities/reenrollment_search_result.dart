import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_list_item.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/reenrollment_candidate.dart';

/// Résultat d'une recherche de réinscription : le **vivier N-1** (candidats de
/// la cohorte locale `ref_previous_year_students`, filtrés par niveau) + les
/// **dossiers locaux de l'année courante** (dossiers RE déjà démarrés).
///
/// La présentation superpose les deux **par `studentId`** (le dossier local
/// prime le candidat) — read-your-writes du parcours RE : un candidat déjà
/// (ré)inscrit apparaît via son dossier (repris si DRAFT, consulté si finalisé),
/// jamais comme candidat frais → pas de double réinscription.
class ReenrollmentSearchResult extends Equatable {
  final List<ReenrollmentCandidate> candidates;
  final List<LocalEnrollmentListItem> localDossiers;

  const ReenrollmentSearchResult({
    required this.candidates,
    required this.localDossiers,
  });

  @override
  List<Object?> get props => [candidates, localDossiers];
}
