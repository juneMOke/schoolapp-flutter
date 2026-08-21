import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/bi_mode_search_form.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Option « cycle + niveau » proposée à la recherche du module Documents.
class DocumentsLevelOption {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;

  const DocumentsLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';
}

/// Critères de recherche émis par le formulaire du module Documents.
class DocumentsSearchRequest {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const DocumentsSearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });
}

/// Carte de recherche bi-mode du module Documents (§01 de la spec) — surcouche
/// du composant générique [BiModeSearchForm], strictement identique à celle de
/// la Facturation à ses libellés près, comme la spec l'exige.
class DocumentsSearchForm extends StatelessWidget {
  final List<DocumentsLevelOption> options;
  final bool isLoading;
  final ValueChanged<DocumentsSearchRequest> onSearch;

  const DocumentsSearchForm({
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
        DocumentsSearchRequest(
          firstName: request.firstName,
          lastName: request.lastName,
          surname: request.surname,
          schoolLevelGroupId: request.schoolLevelGroupId,
          schoolLevelId: request.schoolLevelId,
        ),
      ),
      labels: BiModeSearchLabels(
        title: l10n.documentsSearchTitle,
        helpBanner: l10n.documentsSearchHelpBanner,
        cycleLabel: l10n.documentsSearchCycleLabel,
        levelLabel: l10n.documentsSearchLevelLabel,
        levelPlaceholder: l10n.documentsSearchLevelPlaceholder,
      ),
    );
  }
}
