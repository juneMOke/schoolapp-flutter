import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_search_form_logic.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_search_mode.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_search_request.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de recherche (spec §1) : bascule Par classe / Par élève, cascade
/// Cycle → Niveau → Classe (réinitialisation en cascade), champs Nom / Postnom /
/// Prénom(s) en mode élève, et bouton d'action.
///
/// Auto-contenue (état de sélection interne, préservé par l'`IndexedStack` du
/// coordinateur). Notifie le parent des changements structurants : sélection de
/// cycle ([onCycleChanged], pour charger les périodes + réinitialiser la période)
/// et validation ([onSubmit]). L'activation du bouton dépend aussi d'une période
/// sélectionnée ([periodeSelected]), gérée par la barre de période du parent.
class ResultatsSearchCard extends StatefulWidget {
  final List<ClassesListCycleOption> cycleOptions;
  final bool periodeSelected;
  final bool isSubmitting;
  final ValueChanged<ResultatsSearchMode> onModeChanged;
  final ValueChanged<ClassesListCycleOption?> onCycleChanged;

  /// Notifie la classe sélectionnée (ou `null` au reset de la cascade) : le
  /// parent charge alors les périodes de cette classe (endpoint scopé classe).
  final ValueChanged<BootstrapClassroom?> onClassroomChanged;
  final ValueChanged<ResultatsSearchRequest> onSubmit;

  const ResultatsSearchCard({
    super.key,
    required this.cycleOptions,
    required this.periodeSelected,
    required this.isSubmitting,
    required this.onModeChanged,
    required this.onCycleChanged,
    required this.onClassroomChanged,
    required this.onSubmit,
  });

  @override
  State<ResultatsSearchCard> createState() => _ResultatsSearchCardState();
}

class _ResultatsSearchCardState extends State<ResultatsSearchCard> {
  static const double _minFieldWidth = 172;
  static const double _gap = AppSpacing.sm;

  final _nomController = TextEditingController();
  final _postnomController = TextEditingController();
  final _prenomController = TextEditingController();

  ResultatsSearchMode _mode = ResultatsSearchMode.classe;
  String? _selectedCycleId;
  String? _selectedLevelKey;
  String? _selectedClassroomId;

  @override
  void dispose() {
    _nomController.dispose();
    _postnomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResultatsSearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleOptions == widget.cycleOptions) {
      return;
    }
    final sync = ClassesListSearchFormLogic.computeSelectionSync(
      options: widget.cycleOptions,
      selectedCycleId: _selectedCycleId,
      selectedLevelKey: _selectedLevelKey,
      selectedClassroomId: _selectedClassroomId,
    );
    if (!sync.hasAny) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (sync.clearCycle) _selectedCycleId = null;
        if (sync.clearLevel) _selectedLevelKey = null;
        if (sync.clearClassroom) _selectedClassroomId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCycle = ClassesListSearchFormLogic.findCycle(
      widget.cycleOptions,
      _selectedCycleId,
    );
    final levelOptions =
        selectedCycle?.levels ?? const <ClassesListLevelOption>[];
    final selectedLevel = ClassesListSearchFormLogic.findLevel(
      levelOptions,
      _selectedLevelKey,
    );
    final classroomOptions = selectedLevel?.classrooms ?? const [];
    final classroomEnabled =
        (selectedLevel?.splitIntoClassrooms ?? false) &&
        classroomOptions.isNotEmpty;

    return ResultatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(l10n),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              return Column(
                children: [
                  if (_mode == ResultatsSearchMode.eleve) ...[
                    _autoFitRow(_nameFields(l10n), maxWidth),
                    const SizedBox(height: _gap),
                  ],
                  _autoFitRow(
                    _cascadeFields(
                      l10n,
                      classroomOptions: classroomOptions,
                      levelOptions: levelOptions,
                      classroomEnabled: classroomEnabled,
                    ),
                    maxWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: EteeloButton.primary(
              label: _mode == ResultatsSearchMode.classe
                  ? l10n.resultatsSearchActionClasse
                  : l10n.resultatsSearchActionEleve,
              icon: Icons.search_rounded,
              isLoading: widget.isSubmitting,
              fullWidth: false,
              onPressed: _canSubmit(selectedCycle, selectedLevel)
                  ? () => _submit(selectedCycle!, selectedLevel!)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.resultatsSearchEyebrow.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.terreCuite,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.resultatsSearchTitle,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.bleuProfond,
              ),
            ),
          ],
        ),
        SegmentedTabFilter<ResultatsSearchMode>(
          selected: _mode,
          onSelected: _onModeChanged,
          semanticsLabel: l10n.resultatsSearchModeSemantics,
          options: [
            SegmentedTabOption<ResultatsSearchMode>(
              label: l10n.resultatsSearchByClass,
              value: ResultatsSearchMode.classe,
              icon: Icons.groups_outlined,
            ),
            SegmentedTabOption<ResultatsSearchMode>(
              label: l10n.resultatsSearchByStudent,
              value: ResultatsSearchMode.eleve,
              icon: Icons.person_search_outlined,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _nameFields(AppLocalizations l10n) => [
    EteeloTextInput(
      controller: _nomController,
      label: l10n.resultatsFieldLastName,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.next,
    ),
    EteeloTextInput(
      controller: _postnomController,
      label: l10n.resultatsFieldMiddleName,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.next,
    ),
    EteeloTextInput(
      controller: _prenomController,
      label: l10n.resultatsFieldFirstName,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.done,
    ),
  ];

  List<Widget> _cascadeFields(
    AppLocalizations l10n, {
    required List<ClassesListLevelOption> levelOptions,
    required List<BootstrapClassroom> classroomOptions,
    required bool classroomEnabled,
  }) => [
    EteeloSelectInput<String>(
      label: l10n.schoolCycle,
      value: _selectedCycleId,
      enabled: widget.cycleOptions.isNotEmpty,
      minWidth: 0,
      onChanged: _onCycleSelected,
      items: widget.cycleOptions
          .map((o) => EteeloSelectItem<String>(value: o.id, label: o.label))
          .toList(growable: false),
    ),
    EteeloSelectInput<String>(
      label: l10n.schoolLevelLabel,
      value: _selectedLevelKey,
      enabled: levelOptions.isNotEmpty,
      minWidth: 0,
      onChanged: (value) {
        setState(() {
          _selectedLevelKey = value;
          _selectedClassroomId = null;
        });
        // Le changement de niveau réinitialise la classe → périodes à recharger.
        widget.onClassroomChanged(null);
      },
      items: levelOptions
          .map((o) => EteeloSelectItem<String>(value: o.key, label: o.label))
          .toList(growable: false),
    ),
    EteeloSelectInput<String>(
      label: l10n.resultatsFieldClassroom,
      value: _selectedClassroomId,
      enabled: classroomEnabled,
      minWidth: 0,
      onChanged: (value) {
        setState(() => _selectedClassroomId = value);
        widget.onClassroomChanged(
          ClassesListSearchFormLogic.findClassroom(classroomOptions, value),
        );
      },
      items: [
        for (final c in classroomOptions)
          EteeloSelectItem<String>(value: c.id, label: c.name),
      ],
    ),
  ];

  void _onModeChanged(ResultatsSearchMode mode) {
    if (mode == _mode) {
      return;
    }
    setState(() => _mode = mode);
    widget.onModeChanged(mode);
  }

  void _onCycleSelected(String? value) {
    setState(() {
      _selectedCycleId = value;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
    });
    widget.onCycleChanged(
      ClassesListSearchFormLogic.findCycle(widget.cycleOptions, value),
    );
    // Le changement de cycle réinitialise la classe → périodes à recharger.
    widget.onClassroomChanged(null);
  }

  bool _canSubmit(
    ClassesListCycleOption? selectedCycle,
    ClassesListLevelOption? selectedLevel,
  ) {
    if (widget.isSubmitting || !widget.periodeSelected) {
      return false;
    }
    // Classe requise dans les deux modes (scope de la recherche/synthèse).
    final classroom = selectedLevel == null
        ? null
        : ClassesListSearchFormLogic.findClassroom(
            selectedLevel.classrooms,
            _selectedClassroomId,
          );
    return selectedCycle != null && selectedLevel != null && classroom != null;
  }

  void _submit(
    ClassesListCycleOption selectedCycle,
    ClassesListLevelOption selectedLevel,
  ) {
    final classroom = ClassesListSearchFormLogic.findClassroom(
      selectedLevel.classrooms,
      _selectedClassroomId,
    );
    if (classroom == null) {
      return;
    }
    widget.onSubmit(
      ResultatsSearchRequest(
        mode: _mode,
        cycle: selectedCycle,
        level: selectedLevel,
        classroom: classroom,
        nom: _nomController.text.trim(),
        postnom: _postnomController.text.trim(),
        prenom: _prenomController.text.trim(),
      ),
    );
  }

  /// Dispose [fields] en colonnes auto-fit (repli 3 → 2 → 1 selon la largeur).
  Widget _autoFitRow(List<Widget> fields, double maxWidth) {
    var columns = fields.length;
    while (columns > 1 &&
        maxWidth < (columns * _minFieldWidth) + ((columns - 1) * _gap)) {
      columns--;
    }
    final fieldWidth = (maxWidth - ((columns - 1) * _gap)) / columns;
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final field in fields) SizedBox(width: fieldWidth, child: field),
      ],
    );
  }
}
