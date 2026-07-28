import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_form_actions.dart';
import 'package:school_app_flutter/core/components/search/search_group_box.dart';
import 'package:school_app_flutter/core/components/search/search_level_cascade.dart';
import 'package:school_app_flutter/core/components/search/search_mode_badges.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_name_fields.dart';
import 'package:school_app_flutter/core/components/search/search_two_groups_layout.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_filter_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de recherche bi-mode de la Première inscription — recherche par élève
/// (nom/prénom/postnom) OU par niveau visé (cycle/niveau), toujours bornée au
/// statut actif de l'onglet. Inspirée de [ReRegistrationSearchForm] : même
/// anatomie (groupes + « OU » + badges de mode, briques partagées avec
/// [BiModeSearchForm] via `core/components/search`), mais sans l'envelopper —
/// le statut est un champ à part entière qui redéclenche immédiatement la
/// recherche courante, hors de la logique d'armement du bouton Rechercher.
class FirstRegistrationSearchForm extends StatefulWidget {
  final List<SearchLevelOption> options;
  final bool isLoading;
  final String status;
  final EnrollmentSearchDispatcher dispatch;
  final ValueChanged<String>? onStatusChanged;

  const FirstRegistrationSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.status,
    required this.dispatch,
    this.onStatusChanged,
  });

  @override
  State<FirstRegistrationSearchForm> createState() =>
      _FirstRegistrationSearchFormState();
}

class _FirstRegistrationSearchFormState
    extends State<FirstRegistrationSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedLevelKey;

  @override
  void didUpdateWidget(covariant FirstRegistrationSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    final key = _selectedLevelKey;
    final levelStillValid =
        key != null && widget.options.any((option) => option.key == key);
    final groupStillValid =
        _selectedGroupId != null &&
        widget.options.any((o) => o.schoolLevelGroupId == _selectedGroupId);

    if ((key != null && !levelStillValid) ||
        (_selectedGroupId != null && !groupStillValid)) {
      setState(() {
        if (!levelStillValid) _selectedLevelKey = null;
        if (!groupStillValid) _selectedGroupId = null;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  bool _hasAllNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  bool _hasLevel() =>
      _selectedLevelKey != null &&
      widget.options.any((option) => option.key == _selectedLevelKey);

  bool get _canSearch => !widget.isLoading && (_hasAllNames() || _hasLevel());

  List<SearchLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  SearchLevelOption? get _selectedOption => _uniqueOptions
      .where((option) => option.key == _selectedLevelKey)
      .firstOrNull;

  /// Rejoue les critères actuellement saisis (élève OU niveau, sinon rien)
  /// sous le [status] donné. Utilisé à la fois par « Rechercher » et par le
  /// changement de statut (qui doit préserver, pas effacer, une recherche déjà
  /// engagée — cf. le comportement historique de `SearchForm`).
  ///
  /// Le niveau est prioritaire : quand un niveau est choisi, les noms déjà
  /// saisis (même partiels) sont transmis EN PLUS via `AcademicInfoSearchCommand`
  /// (raffinement nom côté projector, cf. `EnrollmentLocalListProjector.project`)
  /// plutôt qu'ignorés — les deux badges de `SearchModeBadges` peuvent
  /// s'afficher armés ensemble sans qu'aucun critère ne soit silencieusement
  /// perdu.
  void _dispatchForCriteria(String status) {
    if (_hasLevel()) {
      final option = _selectedOption;
      widget.dispatch(
        AcademicInfoSearchCommand(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          surname: _surnameController.text.trim(),
          schoolLevelGroupId: option?.schoolLevelGroupId ?? '',
          schoolLevelId: option?.schoolLevelId ?? '',
          status: status,
        ),
      );
      return;
    }
    if (_hasAllNames()) {
      widget.dispatch(
        StandardSearchCommand(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          surname: _surnameController.text.trim(),
          status: status,
        ),
      );
      return;
    }
    widget.dispatch(StandardSearchCommand(status: status));
  }

  void _submit() {
    if (!_canSearch) return;
    _dispatchForCriteria(widget.status);
  }

  void _reset() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _surnameController.clear();
      _selectedGroupId = null;
      _selectedLevelKey = null;
    });
    widget.dispatch(StandardSearchCommand(status: widget.status));
  }

  void _onNameChanged(String _) => setState(() {});

  void _onCycleChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedLevelKey = null;
    });
  }

  void _onLevelChanged(String? levelKey) {
    setState(() => _selectedLevelKey = levelKey);
  }

  void _onStatusChanged(String newStatus) {
    widget.onStatusChanged?.call(newStatus);
    _dispatchForCriteria(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _uniqueOptions;
    final cycles = buildSearchCycles(options);
    final selectedGroupId =
        cycles.any((cycle) => cycle.groupId == _selectedGroupId)
        ? _selectedGroupId
        : null;
    final selectedLevelKey =
        options.any((option) => option.key == _selectedLevelKey)
        ? _selectedLevelKey
        : null;

    final hasNames = _hasAllNames();
    final hasLevel = _hasLevel();

    final studentGroup = SearchGroupBox(
      icon: Icons.person_outline,
      title: l10n.firstRegistrationSearchByStudentGroup,
      isComplete: hasNames,
      child: SearchNameFields(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        surnameController: _surnameController,
        firstNameLabel: l10n.firstName,
        lastNameLabel: l10n.lastName,
        surnameLabel: l10n.surname,
        enabled: !widget.isLoading,
        inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
        onChanged: _onNameChanged,
      ),
    );

    final classGroup = SearchGroupBox(
      icon: Icons.grid_view_rounded,
      title: l10n.firstRegistrationSearchByLevelGroup,
      isComplete: hasLevel,
      child: SearchLevelCascade(
        cycles: cycles,
        selectedGroupId: selectedGroupId,
        selectedLevelKey: selectedLevelKey,
        isLoading: widget.isLoading,
        cycleLabel: l10n.targetCycleLabel,
        levelLabel: l10n.targetLevelLabel,
        levelPlaceholder: l10n.firstRegistrationSearchLevelPlaceholder,
        onCycleChanged: _onCycleChanged,
        onLevelChanged: _onLevelChanged,
      ),
    );

    final modeBadges = SearchModeBadges(
      activeModeLabel: l10n.firstRegistrationSearchActiveModeLabel,
      studentBadgeLabel: l10n.firstRegistrationSearchModeStudentBadge,
      classBadgeLabel: l10n.firstRegistrationSearchModeLevelBadge,
      studentArmed: hasNames,
      classArmed: hasLevel,
    );

    final statusField = SearchFormStatusFilterField(
      selectedStatus: widget.status,
      onChanged: _onStatusChanged,
    );

    final actions = SearchFormActions(
      isLoading: widget.isLoading,
      canSearch: _canSearch,
      onClear: _reset,
      onSearch: _submit,
      clearLabel: l10n.clear,
      searchLabel: l10n.search,
    );

    return BiToneSectionCard(
      title: l10n.searchStudents,
      subtitle: l10n.searchFormSubtitleFirstRegistration,
      icon: Icons.search_rounded,
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingL - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchTwoGroupsLayout(
            studentGroup: studentGroup,
            classGroup: classGroup,
            orSeparatorLabel: l10n.firstRegistrationSearchOrSeparator,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: AppDimensions.searchFieldMinWidth * 1.6,
              child: statusField,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: modeBadges),
              const SizedBox(width: AppDimensions.spacingM),
              actions,
            ],
          ),
        ],
      ),
    );
  }
}
