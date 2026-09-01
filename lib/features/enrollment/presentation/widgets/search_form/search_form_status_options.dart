import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Valeur de l'option « Tous les statuts » : **la chaîne vide**, et pas un
/// sentinelle inventé. Tout le chemin de recherche (bloc → use case → DAO)
/// traduit déjà « vide » en « pas de clause `status` » (`_nullIfEmpty`) ;
/// un `ALL` maison aurait dû être défait à chaque étage, et le premier oubli
/// aurait cherché des dossiers de statut « ALL » — c'est-à-dire aucun.
const String kEnrollmentStatusFilterAll = '';

class SearchFormStatusOption {
  final String value;
  final String label;

  const SearchFormStatusOption({required this.value, required this.label});
}

/// Options du filtre de statut, **« Tous » en tête** : c'est le défaut de
/// l'écran. Ouvrir le listing sur un statut donné cachait les autres dossiers
/// sans le dire — un dossier complété était introuvable tant qu'on n'avait pas
/// pensé à changer le filtre.
List<SearchFormStatusOption> buildEnrollmentStatusOptions(
  AppLocalizations l10n,
) => [
  SearchFormStatusOption(
    value: kEnrollmentStatusFilterAll,
    label: l10n.enrollmentStatusFilterAll,
  ),
  SearchFormStatusOption(
    value: 'IN_PROGRESS',
    label: l10n.enrollmentStatusInProgress,
  ),
  SearchFormStatusOption(
    value: 'COMPLETED',
    label: l10n.enrollmentStatusCompleted,
  ),
];
