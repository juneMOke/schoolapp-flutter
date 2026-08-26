import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_form_actions.dart';
import 'package:school_app_flutter/core/components/search/search_level_cascade.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_name_fields.dart';
import 'package:school_app_flutter/core/components/search/search_refine_name_field.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_search_form_logic.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de recherche bi-mode de la liste des classes : **par classe**
/// (cycle → niveau → classe facultative, affinable par nom) ou **par identité**
/// (nom, post-nom, prénom), au choix d'une bascule.
///
/// Même anatomie que [BiModeSearchForm] — briques partagées de
/// `core/components/search` — sans l'envelopper : le mode « Par classe » porte
/// ici un **troisième** sélecteur (la classe) que le générique n'a pas, comme
/// `FirstRegistrationSearchForm` porte son statut.
///
/// Les deux modes s'excluent : seuls les champs du mode actif s'affichent, et
/// seuls ses critères partent dans [onSearch]. La saisie de l'autre mode est
/// **conservée** — y revenir ne coûte pas de tout retaper.
class ClassesListSearchForm extends StatefulWidget {
  final List<ClassesListCycleOption> options;
  final bool isSearching;
  final ValueChanged<ClassesListSearchRequest> onSearch;

  const ClassesListSearchForm({
    super.key,
    required this.options,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  State<ClassesListSearchForm> createState() => _ClassesListSearchFormState();
}

class _ClassesListSearchFormState extends State<ClassesListSearchForm> {
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

  String? _selectedCycleId;
  String? _selectedLevelKey;
  String? _selectedClassroomId;

  @override
  void initState() {
    super.initState();
    _mode = _defaultMode();
  }

  /// Sans référentiel, « Par classe » n'offre que des listes grisées et un
  /// affinage qui n'arme rien : on ouvre alors sur l'identité, seule porte
  /// praticable sur une tablette dont le référentiel n'est pas encore descendu.
  SearchMode _defaultMode() =>
      widget.options.isEmpty ? SearchMode.identity : SearchMode.level;

  @override
  void didUpdateWidget(covariant ClassesListSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Le référentiel arrive souvent après le premier rendu. Tant que rien n'est
    // engagé, le mode par défaut le suit ; dès que l'utilisateur a touché à
    // quoi que ce soit, on ne lui reprend plus la main.
    if (_isPristine && _mode != _defaultMode()) {
      setState(() => _mode = _defaultMode());
    }

    if (oldWidget.options == widget.options) {
      return;
    }

    // Une sélection dont l'option a disparu du référentiel est effacée, en
    // cascade : un niveau sans son cycle, une classe sans son niveau.
    final sync = ClassesListSearchFormLogic.computeSelectionSync(
      options: widget.options,
      selectedCycleId: _selectedCycleId,
      selectedLevelKey: _selectedLevelKey,
      selectedClassroomId: _selectedClassroomId,
    );
    if (!sync.hasAny) {
      return;
    }
    setState(() {
      if (sync.clearCycle) _selectedCycleId = null;
      if (sync.clearLevel) _selectedLevelKey = null;
      if (sync.clearClassroom) _selectedClassroomId = null;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _refineNameController.dispose();
    super.dispose();
  }

  ClassesListCycleOption? get _selectedCycle =>
      ClassesListSearchFormLogic.findCycle(widget.options, _selectedCycleId);

  ClassesListLevelOption? get _selectedLevel =>
      ClassesListSearchFormLogic.findLevel(
        _selectedCycle?.levels ?? const <ClassesListLevelOption>[],
        _selectedLevelKey,
      );

  bool _hasAllNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  /// Seul le mode actif arme la recherche : des noms saisis puis abandonnés au
  /// profit d'une classe ne décident pas à sa place.
  bool get _canSearch =>
      !widget.isSearching &&
      switch (_mode) {
        SearchMode.level => _selectedLevel != null,
        SearchMode.identity => _hasAllNames(),
      };

  void _submit() {
    if (!_canSearch) return;

    final isIdentity = _mode == SearchMode.identity;
    final level = isIdentity ? null : _selectedLevel;

    widget.onSearch(
      ClassesListSearchRequest(
        mode: _mode,
        firstName: isIdentity ? _firstNameController.text.trim() : '',
        // En mode classe, le nom d'affinage emprunte la colonne « Nom » : c'est
        // le seul critère de ce mode qui n'ouvre pas la recherche mais la
        // restreint.
        lastName: isIdentity
            ? _lastNameController.text.trim()
            : _refineNameController.text.trim(),
        surname: isIdentity ? _surnameController.text.trim() : '',
        selectedCycle: isIdentity ? null : _selectedCycle,
        selectedLevel: level,
        selectedClassroom: level == null
            ? null
            : ClassesListSearchFormLogic.findClassroom(
                level.classrooms,
                _selectedClassroomId,
              ),
      ),
    );
  }

  /// Efface les critères des DEUX modes, sans changer de mode : « Effacer »
  /// remet la carte à blanc, il ne renvoie pas l'utilisateur ailleurs.
  void _reset() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _surnameController.clear();
      _refineNameController.clear();
      _selectedCycleId = null;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
    });
  }

  void _onModeChanged(SearchMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _isPristine = false;
    });
  }

  void _onNameChanged(String _) => setState(() => _isPristine = false);

  void _onCycleChanged(String? cycleId) {
    setState(() {
      _isPristine = false;
      _selectedCycleId = cycleId;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
    });
  }

  void _onLevelChanged(String? levelKey) {
    setState(() {
      _isPristine = false;
      _selectedLevelKey = levelKey;
      _selectedClassroomId = null;
    });
  }

  void _onClassroomChanged(String? classroomId) {
    setState(() {
      _isPristine = false;
      _selectedClassroomId = classroomId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BiToneSectionCard(
      title: l10n.classesListSearchTitle,
      subtitle: l10n.classesListSearchHint.isEmpty
          ? null
          : l10n.classesListSearchHint,
      icon: Icons.search_rounded,
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingL - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchModeSwitch(
            selected: _mode,
            onChanged: _onModeChanged,
            enabled: !widget.isSearching,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _fields(l10n),
          const SizedBox(height: AppDimensions.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: SearchFormActions(
              isLoading: widget.isSearching,
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
        enabled: !widget.isSearching,
        onChanged: _onNameChanged,
      );
    }

    final level = _selectedLevel;
    final classrooms = level?.classrooms ?? const [];
    // Un niveau non réparti n'a pas de classes à proposer : le sélecteur reste
    // grisé plutôt qu'absent, pour que la cascade garde la même forme d'un
    // niveau à l'autre.
    final classroomEnabled =
        !widget.isSearching &&
        (level?.splitIntoClassrooms ?? false) &&
        classrooms.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchLevelCascade(
          cycles: _cycles(),
          selectedGroupId: _selectedCycleId,
          selectedLevelKey: _selectedLevelKey,
          isLoading: widget.isSearching,
          cycleLabel: l10n.schoolCycle,
          levelLabel: l10n.schoolLevelLabel,
          levelPlaceholder: l10n.classesListSearchLevelPlaceholder,
          onCycleChanged: _onCycleChanged,
          onLevelChanged: _onLevelChanged,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        EteeloSelectInput<String>(
          label: l10n.classesListClassroomOptionalLabel,
          // Deux raisons distinctes de ne rien pouvoir choisir, deux messages :
          // dire « aucune classe pour ce niveau » avant même qu'un niveau soit
          // choisi ferait passer une étape manquante pour un référentiel vide.
          placeholder: classroomEnabled
              ? null
              : (level == null
                    ? l10n.classesListClassroomPlaceholder
                    : l10n.classesListClassroomNonePlaceholder),
          value: classrooms.any((c) => c.id == _selectedClassroomId)
              ? _selectedClassroomId
              : null,
          enabled: classroomEnabled,
          onChanged: _onClassroomChanged,
          items: classrooms
              .map((c) => EteeloSelectItem<String>(value: c.id, label: c.name))
              .toList(growable: false),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        SearchRefineNameField(
          controller: _refineNameController,
          enabled: !widget.isSearching,
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }

  /// Projette les options de la feature sur les briques génériques de la
  /// cascade. Le libellé du cycle est pris tel quel (et non dérivé du préfixe
  /// d'un libellé de niveau comme `buildSearchCycles` le fait) : ici la
  /// hiérarchie est déjà explicite dans les options.
  List<SearchCycle> _cycles() => widget.options
      .map(
        (cycle) => SearchCycle(
          groupId: cycle.id,
          label: cycle.label,
          levels: cycle.levels
              .map(
                (level) => SearchLevelOption(
                  schoolLevelGroupId: level.schoolLevelGroupId,
                  schoolLevelId: level.schoolLevelId,
                  label: level.label,
                ),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false);
}
