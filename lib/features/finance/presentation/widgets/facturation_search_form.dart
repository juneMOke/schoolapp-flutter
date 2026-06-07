import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/bi_mode_search_form.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Option « cycle + niveau » proposée à la recherche de facturation.
class FacturationLevelOption {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;

  const FacturationLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';
}

/// Critères de recherche émis par le formulaire de facturation.
class FacturationSearchRequest {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const FacturationSearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });
}

/// Carte de recherche bi-mode de la Facturation (§01) — fine surcouche du
/// composant générique [BiModeSearchForm] avec les libellés facturation.
class FacturationSearchForm extends StatelessWidget {
  final List<FacturationLevelOption> options;
  final bool isLoading;
  final ValueChanged<FacturationSearchRequest> onSearch;

  const FacturationSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BiModeSearchForm(
      isLoading: isLoading,
      options: options
          .map(
            (o) => SearchLevelOption(
              schoolLevelGroupId: o.schoolLevelGroupId,
              schoolLevelId: o.schoolLevelId,
              label: o.label,
            ),
          )
          .toList(growable: false),
      onSearch: (request) => onSearch(
        FacturationSearchRequest(
          firstName: request.firstName,
          lastName: request.lastName,
          surname: request.surname,
          schoolLevelGroupId: request.schoolLevelGroupId,
          schoolLevelId: request.schoolLevelId,
        ),
      ),
      labels: BiModeSearchLabels(
        title: l10n.facturationSearchTitle,
        helpBanner: l10n.facturationSearchHelpBanner,
        byStudentGroup: l10n.facturationSearchByStudentGroup,
        byClassGroup: l10n.facturationSearchByClassGroup,
        orSeparator: l10n.facturationSearchOrSeparator,
        activeModeLabel: l10n.facturationSearchActiveModeLabel,
        studentBadge: l10n.facturationSearchModeStudentBadge,
        classBadge: l10n.facturationSearchModeClassBadge,
        cycleLabel: l10n.facturationSearchCycleLabel,
        levelLabel: l10n.facturationSearchLevelLabel,
        levelPlaceholder: l10n.facturationSearchLevelPlaceholder,
        firstNameLabel: l10n.firstName,
        lastNameLabel: l10n.lastName,
        surnameLabel: l10n.surname,
        searchLabel: l10n.search,
        clearLabel: l10n.clear,
      ),
    );
  }
}
