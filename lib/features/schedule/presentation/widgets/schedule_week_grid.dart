import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_session_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

part 'schedule_week_grid_parts.dart';
part 'schedule_week_grid_break.dart';

/// Grille hebdomadaire (spec §3) : colonnes = jours (LUN→SAM), lignes =
/// créneaux ; la récréation s'insère en bande après son créneau. Colonne du jour
/// courant teintée. Scrollable horizontalement quand la grille dépasse ; sous
/// 760 dp le samedi est masqué (5 colonnes) et la min-largeur force le scroll.
class ScheduleWeekGrid extends StatelessWidget {
  static const double _gutter = 64;
  static const double _minColumn = 118;
  static const double _narrowBreakpoint = 760;
  static const double _minRowHeight = 54;

  final WeeklyTimetable timetable;
  final ScheduleClassPalette palette;
  final Weekday? today;
  final void Function(TimetableCell cell)? onOpenCell;

  const ScheduleWeekGrid({
    super.key,
    required this.timetable,
    required this.palette,
    required this.today,
    this.onOpenCell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Lignes triées par créneau croissant : l'entité documente cet invariant
    // mais ne le garantit pas (comme la vue Jour, on l'applique côté rendu).
    final rows = [...timetable.rows]
      ..sort((a, b) => a.timeSlot.order.compareTo(b.timeSlot.order));

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final days = _visibleDays(available);
        if (days.isEmpty) {
          return const SizedBox.shrink();
        }

        final columnWidth = ((available - _gutter) / days.length).clamp(
          _minColumn,
          double.infinity,
        );
        final totalWidth = _gutter + columnWidth * days.length;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GridHeader(
                    days: days,
                    columnWidth: columnWidth,
                    gutter: _gutter,
                    today: today,
                    l10n: l10n,
                  ),
                  for (final row in rows)
                    _isBreak(row)
                        ? _BreakBand(row: row, l10n: l10n)
                        : _SlotRow(
                            row: row,
                            days: days,
                            columnWidth: columnWidth,
                            gutter: _gutter,
                            minHeight: _minRowHeight,
                            today: today,
                            palette: palette,
                            l10n: l10n,
                            onOpenCell: onOpenCell,
                          ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Weekday> _visibleDays(double available) {
    if (available >= _narrowBreakpoint) {
      return timetable.days;
    }
    final withoutSat = timetable.days
        .where((day) => day != Weekday.sat)
        .toList(growable: false);
    return withoutSat.isEmpty ? timetable.days : withoutSat;
  }

  /// Ligne « récréation » : un créneau étiqueté (`label`) sans aucune séance sur
  /// **toute** la semaine (propriété structurelle des données, indépendante des
  /// colonnes affichées — donc évaluée sur `row.cells`, pas sur les jours
  /// visibles).
  static bool _isBreak(TimetableRow row) {
    final label = row.timeSlot.label?.trim();
    if (label == null || label.isEmpty) {
      return false;
    }
    return row.cells.values.every((cell) => cell == null);
  }
}
