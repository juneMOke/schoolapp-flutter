import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix de la classe (EDT §4.6 A) : Cycle → Niveau → Classe, en grille de
/// champs d'une, deux ou trois colonnes selon la largeur de la carte. Sur
/// un téléphone, une classe choisie se résume en une ligne (« 6e A · 1er
/// cycle · 6e ») avec « Changer de classe » : les trois listes empilées
/// repoussaient l'emploi du temps de près de 300 dp.
class ClassPicker extends StatefulWidget {
  final List<TimetableClassOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const ClassPicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<ClassPicker> createState() => _ClassPickerState();
}

class _ClassPickerState extends State<ClassPicker> {
  String? _cycle;
  String? _level;
  bool _changing = false;

  @override
  void initState() {
    super.initState();
    _syncFromSelection();
  }

  @override
  void didUpdateWidget(covariant ClassPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _syncFromSelection();
  }

  void _syncFromSelection() {
    for (final o in widget.options) {
      if (o.classroomId == widget.selectedId) {
        _cycle = o.cycleCode;
        _level = o.levelCode;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycles = <String, String>{
      for (final o in widget.options) o.cycleCode: o.cycleName,
    };
    final levels = <String, String>{
      for (final o in widget.options)
        if (o.cycleCode == _cycle) o.levelCode: o.levelName,
    };
    final classes = [
      for (final o in widget.options)
        if (o.cycleCode == _cycle && o.levelCode == _level) o,
    ];
    final fields = [
      EteeloSelectInput<String>(
        label: l10n.classTimetableCycle,
        value: _cycle,
        minWidth: 0,
        onChanged: (v) => setState(() {
          _cycle = v;
          _level = null;
          widget.onSelected(null);
        }),
        items: [
          for (final e in cycles.entries)
            EteeloSelectItem(value: e.key, label: e.value),
        ],
      ),
      EteeloSelectInput<String>(
        label: l10n.classTimetableLevel,
        value: _level,
        minWidth: 0,
        enabled: _cycle != null,
        onChanged: (v) => setState(() {
          _level = v;
          widget.onSelected(null);
        }),
        items: [
          for (final e in levels.entries)
            EteeloSelectItem(value: e.key, label: e.value),
        ],
      ),
      EteeloSelectInput<String>(
        label: l10n.classTimetableClass,
        value: classes.any((c) => c.classroomId == widget.selectedId)
            ? widget.selectedId
            : null,
        minWidth: 0,
        enabled: _level != null,
        onChanged: (v) {
          setState(() => _changing = false);
          widget.onSelected(v);
        },
        items: [
          for (final c in classes)
            EteeloSelectItem(value: c.classroomId, label: c.name),
        ],
      ),
    ];
    final selected = widget.options
        .where((o) => o.classroomId == widget.selectedId)
        .firstOrNull;
    // Pas de titre : la page porte déjà « Emplois du temps par classe ».
    return EteeloPanelCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final phone = constraints.maxWidth < AppBreakpoints.formGridTwoColMin;
          if (phone && selected != null && !_changing) {
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  [
                    selected.name,
                    selected.cycleName,
                    selected.levelName,
                  ].join(' · '),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _changing = true),
                  child: Text(l10n.classTimetableChangeClass),
                ),
              ],
            );
          }
          final columns =
              constraints.maxWidth >= AppBreakpoints.formGridThreeColMin
              ? 3
              : constraints.maxWidth >= AppBreakpoints.formGridTwoColMin
              ? 2
              : 1;
          final width =
              (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final f in fields) SizedBox(width: width, child: f),
            ],
          );
        },
      ),
    );
  }
}
