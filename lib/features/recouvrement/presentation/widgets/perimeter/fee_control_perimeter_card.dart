import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_form_actions.dart';
import 'package:school_app_flutter/core/components/search/search_level_cascade.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_form_fields.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_fee_slot.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_situation_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Le périmètre, puis la situation** — la première carte de l'écran.
///
/// Deux temps dans une seule carte, séparés par un filet : *de quoi parle-t-on*
/// (frais retenus, classe) puis *que cherche-t-on* (la situation, et
/// éventuellement un plancher).
///
/// ⚠️ La spec pose une liste de classes plate ; notre référentiel les range par
/// **cycle → niveau**, et c'est le niveau qui porte la grille tarifaire. La
/// cascade reste donc là où la maquette n'a qu'un menu : sans elle, il n'y
/// aurait ni frais à proposer ni classes à lister.
class FeeControlPerimeterCard extends StatefulWidget {
  final List<SearchLevelOption> options;

  /// Grille du niveau sélectionné, fournie par le BLoC.
  final List<LocalFeeTariff> tariffs;

  /// Classes du niveau sélectionné, fournies par le BLoC.
  final List<OfflineClassroom> classrooms;

  final bool isTariffsLoading;
  final bool isClassroomsLoading;

  /// Vrai quand la grille est absente de l'appareil (message distinct de
  /// « ce niveau n'a pas de frais »).
  final bool feeGridMissing;

  /// Vrai quand la lecture locale de la grille a ÉCHOUÉ — la seule des causes
  /// qui se répare en réessayant.
  final bool tariffsFailed;

  final bool isLoading;

  /// Émis à chaque changement de niveau pour charger grille et classes.
  final void Function(String schoolLevelGroupId, String schoolLevelId)
  onLevelSelected;

  final ValueChanged<FeeControlSearchRequest> onSearch;
  final VoidCallback onClear;

  /// Critères posés d'avance, quand l'écran est ouvert depuis le tableau de
  /// bord. Lus **une seule fois**, au montage : ce sont des valeurs initiales,
  /// pas un pilotage.
  final FeeControlIntent? initial;

  /// La situation du **résultat affiché**. Une tuile de compteur la change sans
  /// passer par cette carte : sans ce retour, les segments continueraient
  /// d'annoncer « Tous » sur une liste filtrée. `null` tant qu'aucune recherche
  /// n'a abouti — la carte garde alors son choix local.
  final FeeControlPaymentFilter? situation;

  /// Le titre que l'école donne à chaque nature. Il prime sur la grille dans
  /// les pastilles : c'est le nom que le tableau de bord écrit aussi.
  final FeeSectionTitlesState sectionTitles;

  const FeeControlPerimeterCard({
    super.key,
    this.initial,
    required this.options,
    required this.tariffs,
    required this.classrooms,
    required this.isTariffsLoading,
    required this.isClassroomsLoading,
    required this.feeGridMissing,
    required this.tariffsFailed,
    required this.isLoading,
    required this.onLevelSelected,
    required this.onSearch,
    required this.onClear,
    this.situation,
    this.sectionTitles = const FeeSectionTitlesState(),
  });

  @override
  State<FeeControlPerimeterCard> createState() =>
      _FeeControlPerimeterCardState();
}

class _FeeControlPerimeterCardState extends State<FeeControlPerimeterCard> {
  final _thresholdController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedLevelKey;
  String? _selectedClassroomId;
  Set<String> _selectedFeeCodes = <String>{};
  FeeControlPaymentFilter _situation = FeeControlPaymentFilter.all;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _selectedGroupId = initial.schoolLevelGroupId;
    _selectedLevelKey = SearchLevelOption.keyFor(
      schoolLevelGroupId: initial.schoolLevelGroupId,
      schoolLevelId: initial.schoolLevelId,
    );
    _selectedClassroomId = initial.classroomId;
    _selectedFeeCodes = {initial.feeCode};
  }

  @override
  void didUpdateWidget(covariant FeeControlPerimeterCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Le résultat a changé de situation sous nos pieds (une tuile de compteur).
    // On suit — mais seulement sur un CHANGEMENT : recopier à chaque rebuild
    // écraserait le segment que l'opérateur vient de choisir et n'a pas encore
    // lancé.
    final incoming = widget.situation;
    if (incoming != null && incoming != oldWidget.situation) {
      // Le plancher n'a plus d'objet hors de son segment : le vider évite
      // qu'il ressurgisse en revenant sur « a payé au moins… ».
      if (!incoming.needsThreshold) _thresholdController.clear();
      _situation = incoming;
    }

    final key = _selectedLevelKey;
    final levelStale =
        key != null && !widget.options.any((option) => option.key == key);
    final groupStale =
        _selectedGroupId != null &&
        !widget.options.any((o) => o.schoolLevelGroupId == _selectedGroupId);
    // La grille change avec le niveau : un frais qui n'y figure plus doit
    // disparaître, sinon le bouton resterait armé sur un code fantôme.
    //
    // ⚠️ **Jamais pendant le chargement.** La liste est alors vide parce qu'on
    // ne sait pas encore, pas parce que les frais ont disparu : invalider ici
    // effacerait la sélection que le tableau de bord vient de poser, dont la
    // grille n'est pas encore descendue.
    final known = {for (final tariff in widget.tariffs) tariff.feeCode};
    final staleFees = widget.isTariffsLoading
        ? const <String>{}
        : _selectedFeeCodes.difference(known);
    // Même raison pour la classe, et même garde : les classes suivent le
    // niveau, et leur chargement n'est pas leur absence.
    final classroomStale =
        _selectedClassroomId != null &&
        !widget.isClassroomsLoading &&
        !widget.classrooms.any((c) => c.id == _selectedClassroomId);

    if (levelStale || groupStale || staleFees.isNotEmpty || classroomStale) {
      setState(() {
        if (levelStale) _selectedLevelKey = null;
        if (groupStale) _selectedGroupId = null;
        if (classroomStale) _selectedClassroomId = null;
        if (staleFees.isNotEmpty) {
          _selectedFeeCodes = _selectedFeeCodes.difference(staleFees);
        }
      });
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  List<SearchLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  SearchLevelOption? get _selectedOption => _uniqueOptions
      .where((option) => option.key == _selectedLevelKey)
      .firstOrNull;

  /// Devise **commune** aux frais retenus, `null` dès qu'ils en mêlent deux —
  /// ou qu'une nature seule en porte déjà deux. C'est elle qui autorise le
  /// montant plancher.
  String? get _currency {
    final currencies = <String>{};
    for (final option in buildFeeControlFeeOptions(widget.tariffs)) {
      if (!_selectedFeeCodes.contains(option.feeCode)) continue;
      final currency = option.currency;
      if (currency == null) return null;
      currencies.add(currency);
    }
    return currencies.length == 1 ? currencies.first : null;
  }

  /// Classe ET au moins un frais : les deux définissent le sujet.
  bool get _canSearch =>
      !widget.isLoading &&
      _selectedOption != null &&
      _selectedFeeCodes.isNotEmpty;

  void _onCycleChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
      _selectedFeeCodes = <String>{};
    });
  }

  void _onLevelChanged(String? levelKey) {
    setState(() {
      _selectedLevelKey = levelKey;
      _selectedClassroomId = null;
      _selectedFeeCodes = <String>{};
    });
    final option = _selectedOption;
    if (option == null) return;
    widget.onLevelSelected(option.schoolLevelGroupId, option.schoolLevelId);
  }

  /// Rejoue les deux lectures locales du niveau déjà sélectionné, par le même
  /// canal que la sélection de niveau : une base qui refuse la grille refuse en
  /// général aussi le roster, et deux portes pour la même panne divergeraient.
  void _retryLevelReads() {
    final option = _selectedOption;
    if (option == null) return;
    widget.onLevelSelected(option.schoolLevelGroupId, option.schoolLevelId);
  }

  /// La sentinelle « toutes les classes » revient à `null` côté critères.
  void _onClassroomChanged(String? classroomId) {
    setState(
      () => _selectedClassroomId =
          classroomId == FeeControlClassroomField.allClassroomsValue
          ? null
          : classroomId,
    );
  }

  void _reset() {
    setState(() {
      _thresholdController.clear();
      _selectedGroupId = null;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
      _selectedFeeCodes = <String>{};
      _situation = FeeControlPaymentFilter.all;
    });
    widget.onClear();
  }

  /// Le plancher saisi, ou `null` — hors du segment de seuil, en sélection
  /// mixte, ou sur un champ vide (qui vaut « tous ceux qui ont payé quelque
  /// chose ou rien »).
  Money? get _threshold {
    if (!_situation.needsThreshold) return null;
    final currency = _currency;
    if (currency == null) return null;
    final amount = parseMonetaryAmount(_thresholdController.text);
    if (amount == null) return null;
    return Money.parse((amount * 100).round(), currency);
  }

  void _submit() {
    final option = _selectedOption;
    if (!_canSearch || option == null) return;

    widget.onSearch(
      FeeControlSearchRequest(
        schoolLevelGroupId: option.schoolLevelGroupId,
        schoolLevelId: option.schoolLevelId,
        classroomId: _selectedClassroomId,
        // L'ordre de l'ÉCOLE — celui des pastilles —, jamais celui des clics :
        // la phrase qui rejoue la requête et la feuille d'appel ne doivent pas
        // changer selon l'ordre où l'on a coché.
        feeCodes: [
          for (final option in buildFeeControlFeeOptions(
            widget.tariffs,
            titles: widget.sectionTitles,
          ))
            if (_selectedFeeCodes.contains(option.feeCode)) option.feeCode,
        ],
        statusFilter: _situation,
        threshold: _threshold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycles = buildSearchCycles(_uniqueOptions);
    final selectedGroupId =
        cycles.any((cycle) => cycle.groupId == _selectedGroupId)
        ? _selectedGroupId
        : null;
    final hasLevel = _selectedOption != null;

    return BiToneSectionCard(
      title: l10n.feeControlSearchTitle,
      subtitle: l10n.feeControlSearchHelpBanner,
      icon: Icons.fact_check_outlined,
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingL - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => _scope(
              context,
              cycles: cycles,
              selectedGroupId: selectedGroupId,
              hasLevel: hasLevel,
              wide: constraints.maxWidth >= AppBreakpoints.formMediumMin,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FeeControlFeeSlot(
            tariffs: widget.tariffs,
            sectionTitles: widget.sectionTitles,
            selected: _selectedFeeCodes,
            hasLevel: hasLevel,
            isLoading: widget.isLoading || widget.isTariffsLoading,
            feeGridMissing: widget.feeGridMissing,
            loadFailed: widget.tariffsFailed,
            onChanged: (codes) => setState(() => _selectedFeeCodes = codes),
            onRetry: _retryLevelReads,
          ),
          // Le filet : la situation appartient à la même carte que le périmètre,
          // mais à un autre temps de la question.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
            child: Divider(height: 1, color: AppColors.border),
          ),
          FeeControlSituationField(
            selected: _situation,
            currency: _currency,
            thresholdController: _thresholdController,
            enabled: !widget.isLoading,
            onChanged: (value) => setState(() => _situation = value),
            onThresholdChanged: (_) => setState(() {}),
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

  Widget _scope(
    BuildContext context, {
    required List<SearchCycle> cycles,
    required String? selectedGroupId,
    required bool hasLevel,
    required bool wide,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final cascade = SearchLevelCascade(
      cycles: cycles,
      selectedGroupId: selectedGroupId,
      selectedLevelKey: hasLevel ? _selectedLevelKey : null,
      isLoading: widget.isLoading,
      cycleLabel: l10n.feeControlSearchCycleLabel,
      levelLabel: l10n.feeControlSearchLevelLabel,
      levelPlaceholder: l10n.feeControlSearchLevelPlaceholder,
      onCycleChanged: _onCycleChanged,
      onLevelChanged: _onLevelChanged,
    );
    final classroom = FeeControlClassroomField(
      classrooms: widget.classrooms,
      selectedClassroomId: _selectedClassroomId,
      hasLevel: hasLevel,
      isLoading: widget.isLoading || widget.isClassroomsLoading,
      onChanged: _onClassroomChanged,
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cascade,
          const SizedBox(height: AppDimensions.spacingS),
          classroom,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: cascade),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(child: classroom),
      ],
    );
  }
}
