import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mois d'une personne, lundi → vendredi : une case par jour, dans la teinte
/// de son statut ; jours à venir estompés, non pointés en pointillé. Une case
/// écrit son détail (arrivée, retard, motif) quand l'appelant le donne.
class PresenceMonthCalendar extends StatelessWidget {
  final List<PresenceCalendarDay?> days;

  /// `null` : les cases se lisent seulement. Sinon un jour passé s'ouvre
  /// (jamais un jour à venir).
  final ValueChanged<String>? onTapDay;

  const PresenceMonthCalendar({super.key, required this.days, this.onTapDay});

  static const int _columns = 5;

  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context);
    // `narrowWeekdays` commence au dimanche ; on garde lundi → vendredi.
    final weekdays = dates.narrowWeekdays.sublist(1, 1 + _columns);
    final cells = [...days];
    while (cells.length % _columns != 0) {
      cells.add(null);
    }
    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var week = 0; week < cells.length; week += _columns)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                for (final cell in cells.sublist(week, week + _columns))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs / 2,
                      ),
                      child: cell == null
                          ? const SizedBox(
                              height:
                                  AppDimensions.presenceMarkCalendarCellHeight,
                            )
                          : _DayCell(day: cell, onTap: onTapDay),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final PresenceCalendarDay day;
  final ValueChanged<String>? onTap;

  const _DayCell({required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceTone.of(day.status);
    final marked = day.status != PresenceStatus.none;
    final detail = day.detail;
    final date = PresenceLabels.longDay(
      MaterialLocalizations.of(context),
      day.day,
    );
    return Tooltip(
      message: day.upcoming
          ? date
          : [
              date,
              PresenceLabels.status(l10n, day.status),
              ?detail,
              if (day.pending) l10n.presenceCalendarPending,
            ].join(' · '),
      child: Opacity(
        opacity: day.upcoming ? AppDimensions.presenceMarkUpcomingOpacity : 1,
        child: _tappable(
          Container(
            height: AppDimensions.presenceMarkCalendarCellHeight,
            decoration: BoxDecoration(
              color: marked ? tone.soft : AppColors.surfaceRaised,
              borderRadius: AppRadius.brSm,
              border: Border.all(
                color: marked ? tone.border : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${int.parse(day.day.substring(8))}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!day.upcoming && detail != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(color: tone.ink),
                    ),
                  )
                else if (!day.upcoming)
                  Icon(
                    marked ? tone.icon : Icons.more_horiz,
                    size: AppSpacing.lg,
                    color: tone.ink,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// La case, et par-dessus la marque « à envoyer » ; touchable quand la
  /// fiche le permet et que le jour est passé — 56 dp de haut, la cible tient.
  Widget _tappable(Widget cell) {
    final onTap = this.onTap;
    final marked = day.pending
        ? Stack(
            children: [
              cell,
              const Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: AppSpacing.md,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          )
        : cell;
    if (onTap == null || day.upcoming) return marked;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onTap(day.day),
        borderRadius: AppRadius.brSm,
        child: marked,
      ),
    );
  }
}
