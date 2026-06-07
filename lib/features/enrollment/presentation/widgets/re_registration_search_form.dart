import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/bi_mode_search_form.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Option « cycle + niveau » proposée à la recherche de réinscription.
class ReRegistrationAcademicOption {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;

  const ReRegistrationAcademicOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';
}

/// Carte de recherche bi-mode de la Réinscription — recherche par nom OU par
/// cycle/niveau (ou les deux). Fine surcouche du composant générique
/// [BiModeSearchForm] avec les libellés réinscription.
class ReRegistrationSearchForm extends StatelessWidget {
  final List<ReRegistrationAcademicOption> options;
  final bool isLoading;
  final EnrollmentSearchDispatcher dispatch;

  const ReRegistrationSearchForm({
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
      nameInputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
      helpPill: l10n.reRegistrationSearchHelpPill,
      helpPillIcon: Icons.school_outlined,
      options: options
          .map(
            (o) => SearchLevelOption(
              schoolLevelGroupId: o.schoolLevelGroupId,
              schoolLevelId: o.schoolLevelId,
              label: o.label,
            ),
          )
          .toList(growable: false),
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
        title: l10n.reRegistrationSearchTitle,
        helpBanner: l10n.reRegistrationSearchHint,
        byStudentGroup: l10n.reRegistrationSearchByNameGroup,
        byClassGroup: l10n.reRegistrationSearchByLevelGroup,
        orSeparator: l10n.reRegistrationSearchOrSeparator,
        activeModeLabel: l10n.reRegistrationSearchActiveModeLabel,
        studentBadge: l10n.reRegistrationSearchModeNameBadge,
        classBadge: l10n.reRegistrationSearchModeLevelBadge,
        cycleLabel: l10n.targetCycleLabel,
        levelLabel: l10n.targetLevelLabel,
        levelPlaceholder: l10n.reRegistrationSearchLevelPlaceholder,
        firstNameLabel: l10n.firstName,
        lastNameLabel: l10n.lastName,
        surnameLabel: l10n.surname,
        searchLabel: l10n.search,
        clearLabel: l10n.clear,
      ),
    );
  }
}
