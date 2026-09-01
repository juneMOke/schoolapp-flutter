import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_form_actions.dart';
import 'package:school_app_flutter/core/components/search/search_level_mode_fields.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_name_fields.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_filter_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de recherche bi-mode de la Première inscription — par classe (cycle →
/// niveau) OU par identité, toujours bornée au statut actif de l'onglet.
///
/// Même anatomie que [BiModeSearchForm] (bascule de mode, aide, champs du mode
/// actif — briques partagées via `core/components/search`) sans l'envelopper :
/// le statut est ici un champ à part entière, qui redéclenche immédiatement la
/// recherche courante hors de la logique d'armement du bouton Rechercher.
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

  /// Affinage du mode « Par classe » — distinct du « Nom » du mode identité :
  /// chaque mode garde ses propres critères, y compris sur la même colonne.
  final _refineNameController = TextEditingController();
  SearchMode _mode = SearchMode.level;

  /// Vrai tant que l'utilisateur n'a rien engagé — ni bascule, ni saisie, ni
  /// sélection. Tant qu'on est là, le mode par défaut peut encore suivre le
  /// référentiel ; après, il n'appartient plus qu'à l'utilisateur.
  bool _isPristine = true;
  String? _selectedGroupId;
  String? _selectedLevelKey;

  @override
  void initState() {
    super.initState();
    _mode = _defaultMode();
  }

  /// Sans référentiel, « Par classe » n'offre que deux listes grisées et un
  /// affinage qui n'arme rien : on ouvre alors sur l'identité, seule porte
  /// praticable. Avant la bascule, le groupe « par nom » restait visible dans
  /// ce cas — le perdre serait une régression silencieuse sur une tablette dont
  /// le référentiel n'est pas encore descendu.
  SearchMode _defaultMode() =>
      widget.options.isEmpty ? SearchMode.identity : SearchMode.level;

  @override
  void didUpdateWidget(covariant FirstRegistrationSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Le référentiel arrive souvent après le premier rendu. Tant que rien n'est
    // engagé, le mode par défaut le suit ; dès que l'utilisateur a touché à
    // quoi que ce soit, on ne lui reprend plus la main.
    if (_isPristine && _mode != _defaultMode()) {
      setState(() => _mode = _defaultMode());
    }

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
    _refineNameController.dispose();
    super.dispose();
  }

  /// Un seul nom suffit à armer la recherche : les trois se combinent en OU
  /// côté filtrage, exiger les trois ici rendrait ce OU inatteignable — on ne
  /// peut pas chercher quelqu'un dont on ne connaît qu'un nom si le bouton
  /// reste éteint tant que les deux autres sont vides.
  bool _hasAnyName() =>
      _firstNameController.text.trim().isNotEmpty ||
      _lastNameController.text.trim().isNotEmpty ||
      _surnameController.text.trim().isNotEmpty;

  bool _hasLevel() =>
      _selectedLevelKey != null &&
      widget.options.any((option) => option.key == _selectedLevelKey);

  /// Seul le mode actif arme la recherche : des noms saisis puis abandonnés au
  /// profit d'une classe ne décident pas à sa place.
  bool get _canSearch =>
      !widget.isLoading &&
      switch (_mode) {
        SearchMode.level => _hasLevel(),
        SearchMode.identity => _hasAnyName(),
      };

  List<SearchLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  SearchLevelOption? get _selectedOption => _uniqueOptions
      .where((option) => option.key == _selectedLevelKey)
      .firstOrNull;

  /// Rejoue les critères du **mode actif** sous le [status] donné. Utilisé à
  /// la fois par « Rechercher » et par le changement de statut, qui doit
  /// préserver — pas effacer — une recherche déjà engagée.
  ///
  /// Les critères de l'autre mode restent saisis mais ne partent pas : c'est ce
  /// qui distingue une bascule d'un formulaire replié en deux. Sans critère
  /// armé, seul le statut voyage — l'onglet se recharge sans filtre.
  void _dispatchForCriteria(String status) {
    if (_mode == SearchMode.level && _hasLevel()) {
      final option = _selectedOption;
      widget.dispatch(
        AcademicInfoSearchCommand(
          firstName: '',
          // Le nom d'affinage emprunte la colonne « Nom » : seul critère de ce
          // mode qui n'ouvre pas la recherche mais la restreint (raffinement
          // partiel côté `EnrollmentLocalListProjector`).
          lastName: _refineNameController.text.trim(),
          surname: '',
          schoolLevelGroupId: option?.schoolLevelGroupId ?? '',
          schoolLevelId: option?.schoolLevelId ?? '',
          status: status,
        ),
      );
      return;
    }
    if (_mode == SearchMode.identity && _hasAnyName()) {
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
      _refineNameController.clear();
      _selectedGroupId = null;
      _selectedLevelKey = null;
    });
    widget.dispatch(StandardSearchCommand(status: widget.status));
  }

  void _onModeChanged(SearchMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _isPristine = false;
    });
  }

  void _onNameChanged(String _) => setState(() => _isPristine = false);

  void _onCycleChanged(String? groupId) {
    setState(() {
      _isPristine = false;
      _selectedGroupId = groupId;
      _selectedLevelKey = null;
    });
  }

  void _onLevelChanged(String? levelKey) {
    setState(() {
      _isPristine = false;
      _selectedLevelKey = levelKey;
    });
  }

  void _onStatusChanged(String newStatus) {
    widget.onStatusChanged?.call(newStatus);
    _dispatchForCriteria(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final statusField = SearchFormStatusFilterField(
      selectedStatus: widget.status,
      onChanged: _onStatusChanged,
    );

    return BiToneSectionCard(
      title: l10n.searchStudents,
      subtitle: l10n.searchFormSubtitleFirstRegistration,
      icon: Icons.search_rounded,
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingL - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchModeSwitch(
            selected: _mode,
            onChanged: _onModeChanged,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _fields(l10n),
          const SizedBox(height: AppDimensions.spacingM),
          // Le statut borne les DEUX modes : il reste hors de la bascule.
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: AppDimensions.searchFieldMinWidth * 1.6,
              child: statusField,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: SearchFormActions(
              isLoading: widget.isLoading,
              canSearch: _canSearch,
              onClear: _reset,
              onSearch: _submit,
              clearLabel: l10n.clear,
              searchLabel: l10n.search,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fields(AppLocalizations l10n) {
    if (_mode == SearchMode.identity) {
      return SearchNameFields(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        surnameController: _surnameController,
        firstNameLabel: l10n.firstName,
        lastNameLabel: l10n.lastName,
        surnameLabel: l10n.surname,
        enabled: !widget.isLoading,
        onChanged: _onNameChanged,
      );
    }

    final options = _uniqueOptions;
    final cycles = buildSearchCycles(options);

    return SearchLevelModeFields(
      cycles: cycles,
      selectedGroupId: cycles.any((cycle) => cycle.groupId == _selectedGroupId)
          ? _selectedGroupId
          : null,
      selectedLevelKey: options.any((o) => o.key == _selectedLevelKey)
          ? _selectedLevelKey
          : null,
      isLoading: widget.isLoading,
      cycleLabel: l10n.targetCycleLabel,
      levelLabel: l10n.targetLevelLabel,
      levelPlaceholder: l10n.firstRegistrationSearchLevelPlaceholder,
      onCycleChanged: _onCycleChanged,
      onLevelChanged: _onLevelChanged,
      refineNameController: _refineNameController,
      onRefineSubmitted: _submit,
    );
  }
}
