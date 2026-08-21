import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/bi_mode_search_form.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de recherche bi-mode de la Pré-inscription — recherche par nom OU par
/// cycle/niveau souhaité (ou les deux). Fine surcouche du composant générique
/// [BiModeSearchForm], en miroir de `ReRegistrationSearchForm` : mêmes
/// statuts (2, pas 3 — chaque résultat porte déjà son propre badge), pas de
/// filtre de statut dans le formulaire lui-même.
class PreRegistrationSearchForm extends StatelessWidget {
  final List<SearchLevelOption> options;
  final bool isLoading;
  final EnrollmentSearchDispatcher dispatch;

  const PreRegistrationSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.dispatch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BiModeSearchForm(
      isLoading: isLoading,
      options: options,
      onSearch: (request) => dispatch(
        AcademicInfoSearchCommand(
          firstName: request.firstName,
          lastName: request.lastName,
          surname: request.surname,
          schoolLevelGroupId: request.schoolLevelGroupId,
          schoolLevelId: request.schoolLevelId,
        ),
      ),
      labels: BiModeSearchLabels(
        title: l10n.preRegistrationSearchTitle,
        helpBanner: l10n.preRegistrationSearchHint,
        cycleLabel: l10n.targetCycleLabel,
        levelLabel: l10n.targetLevelLabel,
        levelPlaceholder: l10n.preRegistrationSearchLevelPlaceholder,
      ),
    );
  }
}
