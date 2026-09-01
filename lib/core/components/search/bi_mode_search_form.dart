import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_form_actions.dart';
import 'package:school_app_flutter/core/components/search/search_level_mode_fields.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_name_fields.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellés **propres à la feature** de la carte de recherche bi-mode.
///
/// Tout ce qui est commun aux quatre modules — la bascule, ses aides, les noms
/// des champs d'identité, les actions — vient directement d'[AppLocalizations].
/// Un même geste ne doit pas s'appeler « Par classe » ici et « Par cycle et
/// niveau » ailleurs.
class BiModeSearchLabels {
  final String title;
  final String helpBanner;
  final String cycleLabel;
  final String levelLabel;
  final String levelPlaceholder;

  const BiModeSearchLabels({
    required this.title,
    required this.helpBanner,
    required this.cycleLabel,
    required this.levelLabel,
    required this.levelPlaceholder,
  });
}

/// Carte de recherche bi-mode : **par classe** (cycle → niveau) ou **par
/// identité** (nom, post-nom, prénom), au choix d'une bascule.
///
/// Les deux modes s'excluent : seuls les champs du mode actif s'affichent, et
/// seuls ses critères partent dans [onSearch]. La saisie de l'autre mode est
/// **conservée** — y revenir ne coûte pas de tout retaper.
///
/// Le mode « Par classe » porte en plus un affinage par nom **facultatif** :
/// c'est toujours la classe qui ouvre la recherche, le nom ne fait que
/// restreindre la liste (cf. [SearchRefineNameField]).
class BiModeSearchForm extends StatefulWidget {
  final List<SearchLevelOption> options;
  final bool isLoading;
  final ValueChanged<SearchRequest> onSearch;
  final BiModeSearchLabels labels;

  const BiModeSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.onSearch,
    required this.labels,
  });

  @override
  State<BiModeSearchForm> createState() => _BiModeSearchFormState();
}

class _BiModeSearchFormState extends State<BiModeSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();

  /// Affinage du mode « Par classe » — distinct du « Nom » du mode identité :
  /// chaque mode garde ses propres critères, y compris quand ils portent sur
  /// la même colonne.
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
  void didUpdateWidget(covariant BiModeSearchForm oldWidget) {
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

    if ((key != null && !levelStillValid && mounted) ||
        (_selectedGroupId != null && !groupStillValid && mounted)) {
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
  /// profit d'une classe ne doivent pas décider à sa place.
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

  void _submit() {
    if (!_canSearch) return;

    // Les critères de l'autre mode restent saisis mais ne partent pas : c'est
    // ce qui distingue une bascule d'un simple pliage de deux formulaires.
    final isIdentity = _mode == SearchMode.identity;
    final option = isIdentity ? null : _selectedOption;

    widget.onSearch(
      SearchRequest(
        firstName: isIdentity ? _firstNameController.text.trim() : '',
        // En mode classe, le nom d'affinage emprunte la colonne « Nom » : c'est
        // le seul critère de ce mode qui n'ouvre pas la recherche mais la
        // restreint.
        lastName: isIdentity
            ? _lastNameController.text.trim()
            : _refineNameController.text.trim(),
        surname: isIdentity ? _surnameController.text.trim() : '',
        schoolLevelGroupId: option?.schoolLevelGroupId ?? '',
        schoolLevelId: option?.schoolLevelId ?? '',
      ),
    );
  }

  /// Efface les critères des DEUX modes, sans changer de mode : « Effacer »
  /// remet la CARTE à blanc, il ne renvoie pas l'utilisateur ailleurs.
  ///
  /// ⚠️ Il ne touche PAS aux résultats déjà affichés : cette carte n'a aucun
  /// canal vers la liste, contrairement à `FeeControlSearchForm` (`onClear`) et
  /// à `FirstRegistrationSearchForm` (qui redispatche). Comportement d'origine,
  /// laissé tel quel — le corriger demande d'ouvrir un canal dans les quatre
  /// pages qui montent cette carte.
  void _reset() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _surnameController.clear();
      _refineNameController.clear();
      _selectedGroupId = null;
      _selectedLevelKey = null;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = widget.labels;

    return BiToneSectionCard(
      title: labels.title,
      subtitle: labels.helpBanner,
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
      cycleLabel: widget.labels.cycleLabel,
      levelLabel: widget.labels.levelLabel,
      levelPlaceholder: widget.labels.levelPlaceholder,
      onCycleChanged: _onCycleChanged,
      onLevelChanged: _onLevelChanged,
      refineNameController: _refineNameController,
      onRefineSubmitted: _submit,
    );
  }
}
