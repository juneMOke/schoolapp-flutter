import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_legend_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La légende-filtre (spec §4.6 L, maquette `CalDetail`) : une puce à
/// compteur par nature — pleine de sa couleur quand elle est montrée, barrée
/// quand elle est masquée (I8) — et à droite la clé « national / interne ».
/// Les compteurs suivent la source ([elements] est déjà filtré par elle, I9).
///
/// En [compact] (sous 600) : les puces tiennent sur une ligne qui défile de
/// côté, et la clé passe dessous (« plein » / « tirets »). Au-delà, elles
/// passent à la ligne.
class CalendarLegend extends StatefulWidget {
  final List<CalendarElement> elements;
  final Set<CalendarNature> hidden;
  final ValueChanged<CalendarNature> onToggle;
  final bool compact;

  const CalendarLegend({
    super.key,
    required this.elements,
    required this.hidden,
    required this.onToggle,
    this.compact = false,
  });

  @override
  State<CalendarLegend> createState() => _CalendarLegendState();
}

class _CalendarLegendState extends State<CalendarLegend> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final touch = !expectsPhysicalKeyboard;
    final chips = [
      for (final nature in CalendarNature.values)
        CalendarLegendChip(
          label: CalendarLabels.natureShort(l10n, nature),
          count: widget.elements.where((e) => e.nature == nature).length,
          shown: !widget.hidden.contains(nature),
          nature: nature,
          touch: touch || widget.compact,
          onTap: () => widget.onToggle(nature),
        ),
    ];
    if (!widget.compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xs + AppSpacing.xs / 2,
              runSpacing: AppSpacing.xs + AppSpacing.xs / 2,
              children: chips,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: CalendarSourceKey(compact: false),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                for (final (i, chip) in chips.indexed) ...[
                  if (i > 0)
                    const SizedBox(width: AppSpacing.xs + AppSpacing.xs / 2),
                  chip,
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const CalendarSourceKey(compact: true),
      ],
    );
  }
}
