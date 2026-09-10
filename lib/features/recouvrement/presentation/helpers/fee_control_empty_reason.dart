import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une liste vide a plusieurs causes qui appellent des gestes différents. Les
/// confondre envoie chercher une erreur de saisie là où il manque une
/// synchronisation — ou l'inverse.
///
/// **Le droit manquant passe en tête** (ADR-015 F1). Les deux messages de
/// synchronisation ci-dessous promettent une mise à jour qui n'arrivera
/// jamais : le flux qui remplirait ces tables est sauté à chaque cycle faute
/// de permission. Placés avant, ils enverraient le caissier attendre
/// indéfiniment un pull qui a déjà eu lieu et qui l'a délibérément sauté.
String feeControlEmptyReason(
  FeeControlState state,
  AppLocalizations l10n, {
  required PermissionHolding enrollment,
  required PermissionHolding classroom,
}) {
  if (enrollment == PermissionHolding.missing) {
    return l10n.feeControlEmptyEnrollmentWithheld;
  }
  // ⚠️ La maille décide du VOCABULAIRE autant que des causes. Les messages de
  // classe (« de cette classe ») étaient les seuls écrits, si bien qu'une
  // recherche « toutes les classes du niveau » ne pouvait qu'échouer vers
  // « modifiez le formulaire » — on envoyait l'opérateur corriger des
  // critères qui n'y peuvent rien.
  final scopedToClassroom = state.lastQuery?.classroomId != null;
  if (scopedToClassroom && classroom == PermissionHolding.missing) {
    return l10n.feeControlEmptyClassroomWithheld;
  }

  if (state.studentsInScope == 0) {
    // Maille NIVEAU : deux causes se ressemblent et l'appareil ne peut pas
    // les départager — le niveau n'a réellement aucun élève, ou le flux
    // Inscription n'a pas atterri. Le message dit donc ce qui est vrai des
    // deux côtés (« sur cet appareil ») et n'offre le geste qu'en condition.
    if (!scopedToClassroom) return l10n.feeControlEmptyNoEnrollmentForLevel;
    // Maille CLASSE : le roster tranche, lui. Absent, rien à croiser.
    if (state.classroomRosterSize == 0) {
      return l10n.feeControlEmptyRosterMissing;
    }
    // Roster connu, mais aucun de ses élèves n'a de dossier d'inscription
    // local sur l'année — décalage d'identifiants ou pull Inscription partiel.
    return l10n.feeControlEmptyNoLocalEnrollment;
  }

  // Des élèves, mais aucun ne porte ce frais : la grille ne l'a pas généré.
  // Mesuré AVANT le filtre de statut (cf. `FeeControlProjector.join`), donc
  // « personne n'est concerné », jamais « le filtre a tout écarté ».
  if (state.breakdown.isEmpty) {
    return scopedToClassroom
        ? l10n.feeControlNoChargeDescription
        : l10n.feeControlNoChargeForLevelDescription;
  }
  // Il reste des élèves concernés : c'est bien la saisie qui n'a rien laissé
  // passer, et « modifiez le formulaire » est enfin le bon conseil.
  return l10n.feeControlNoResultsDescription;
}
