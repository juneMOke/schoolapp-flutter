import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_list_item.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/pre_enrollment_candidate.dart';

/// Résultat d'une recherche de pré-inscription : le **vivier**
/// (candidats `ref_pre_enrollments`, filtrés par niveau souhaité) + les
/// **dossiers locaux de l'année courante** (dossiers PRE déjà démarrés).
///
/// La présentation superpose les deux **par id exact** (le candidat brut a le
/// même id que le dossier local une fois seedé — contrairement à RE, pas
/// besoin de dédup par `studentId`) : un candidat déjà démarré apparaît via
/// son dossier (repris si DRAFT, consulté si finalisé), jamais comme candidat
/// frais.
class PreEnrollmentSearchResult extends Equatable {
  final List<PreEnrollmentCandidate> candidates;
  final List<LocalEnrollmentListItem> localDossiers;

  const PreEnrollmentSearchResult({
    required this.candidates,
    required this.localDossiers,
  });

  @override
  List<Object?> get props => [candidates, localDossiers];
}
