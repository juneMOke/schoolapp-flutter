import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:school_app_flutter/core/components/keyboard/search_shortcuts.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_search_form_logic.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de sélection : la cascade Cycle → Niveau → Classe, et « Ouvrir la
/// saisie ». Changer de classe exige d'ouvrir à nouveau ; la portée, elle, se
/// règle sans recharger ([scopeBar]).
class CoteSelectionCard extends StatefulWidget {
  final List<ClassesListCycleOption> cycleOptions;

  /// La classe de l'adresse : la cascade s'y place dès que les classes arrivent.
  final String? initialClassroomId;
  final bool isOpening;
  final ValueChanged<OfflineClassroom> onOpen;
  final Widget? scopeBar;

  const CoteSelectionCard({
    super.key,
    required this.cycleOptions,
    required this.onOpen,
    this.initialClassroomId,
    this.isOpening = false,
    this.scopeBar,
  });

  @override
  State<CoteSelectionCard> createState() => _CoteSelectionCardState();
}

class _CoteSelectionCardState extends State<CoteSelectionCard> {
  static const double _gap = AppSpacing.sm;
  static const double _minFieldWidth = AppDimensions.coteSelectFieldMinWidth;

  String? _cycleId;
  String? _levelKey;
  String? _classroomId;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _placeFromAddress();
  }

  @override
  void didUpdateWidget(covariant CoteSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleOptions == widget.cycleOptions) return;
    _placeFromAddress();
    final sync = ClassesListSearchFormLogic.computeSelectionSync(
      options: widget.cycleOptions,
      selectedCycleId: _cycleId,
      selectedLevelKey: _levelKey,
      selectedClassroomId: _classroomId,
    );
    if (!sync.hasAny) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (sync.clearCycle) _cycleId = null;
        if (sync.clearLevel) _levelKey = null;
        if (sync.clearClassroom) _classroomId = null;
      });
    });
  }

  void _placeFromAddress() {
    final target = widget.initialClassroomId;
    if (_placed || target == null) return;
    for (final cycle in widget.cycleOptions) {
      for (final level in cycle.levels) {
        if (level.classrooms.any((c) => c.id == target)) {
          _cycleId = cycle.id;
          _levelKey = level.key;
          _classroomId = target;
          _placed = true;
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycle = ClassesListSearchFormLogic.findCycle(
      widget.cycleOptions,
      _cycleId,
    );
    final levels = cycle?.levels ?? const <ClassesListLevelOption>[];
    final level = ClassesListSearchFormLogic.findLevel(levels, _levelKey);
    final classrooms = level?.classrooms ?? const <OfflineClassroom>[];
    final classroom = ClassesListSearchFormLogic.findClassroom(
      classrooms,
      _classroomId,
    );
    final scopeBar = widget.scopeBar;
    return ResultatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.coteSaisieEyebrow.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.coteSaisieTitle,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.bleuProfond,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SearchFocusShortcut(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  _fields(l10n, constraints.maxWidth, levels, classrooms),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final open = EteeloButton.primary(
                label: l10n.coteSaisieOpen,
                icon: Icons.edit_outlined,
                fullWidth: false,
                isLoading: widget.isOpening,
                onPressed: classroom == null
                    ? null
                    : () => widget.onOpen(classroom),
              );
              if (scopeBar == null) {
                return Align(alignment: Alignment.centerRight, child: open);
              }
              if (constraints.maxWidth < AppBreakpoints.coteGridCompactMax) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    scopeBar,
                    const SizedBox(height: AppSpacing.md),
                    Align(alignment: Alignment.centerRight, child: open),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: scopeBar),
                  const SizedBox(width: AppSpacing.md),
                  open,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fields(
    AppLocalizations l10n,
    double width,
    List<ClassesListLevelOption> levels,
    List<OfflineClassroom> classrooms,
  ) {
    final fields = [
      EteeloSelectInput<String>(
        label: l10n.schoolCycle,
        value: _cycleId,
        enabled: widget.cycleOptions.isNotEmpty,
        minWidth: 0,
        onChanged: (value) => setState(() {
          _cycleId = value;
          _levelKey = null;
          _classroomId = null;
        }),
        items: [
          for (final option in widget.cycleOptions)
            EteeloSelectItem<String>(value: option.id, label: option.label),
        ],
      ),
      EteeloSelectInput<String>(
        label: l10n.schoolLevelLabel,
        value: _levelKey,
        enabled: levels.isNotEmpty,
        minWidth: 0,
        onChanged: (value) => setState(() {
          _levelKey = value;
          final options = levels.where((l) => l.key == value).firstOrNull;
          final only = options?.classrooms;
          _classroomId = only != null && only.length == 1
              ? only.first.id
              : null;
        }),
        items: [
          for (final option in levels)
            EteeloSelectItem<String>(value: option.key, label: option.label),
        ],
      ),
      EteeloSelectInput<String>(
        label: l10n.resultatsFieldClassroom,
        value: _classroomId,
        enabled: classrooms.isNotEmpty,
        minWidth: 0,
        onChanged: (value) => setState(() => _classroomId = value),
        items: [
          for (final classroom in classrooms)
            EteeloSelectItem<String>(
              value: classroom.id,
              label: classroom.name,
            ),
        ],
      ),
    ];
    final perRow = ((width + _gap) / (_minFieldWidth + _gap)).floor().clamp(
      1,
      fields.length,
    );
    final fieldWidth = (width - _gap * (perRow - 1)) / perRow;
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final field in fields) SizedBox(width: fieldWidth, child: field),
      ],
    );
  }
}
