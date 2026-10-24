import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card_frame.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_profile_badge.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_share_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La vue annuelle : une ligne par mois de l'année scolaire — barre
/// tricolore, trois taux, jours pointés, profil du mois. Vacances et mois à
/// venir se disent, et ne s'ouvrent pas ; un mois de classe ouvre sa vue
/// mensuelle.
class HrPresenceYearList extends StatelessWidget {
  final List<HrAttendanceMonthSummary> months;
  final ValueChanged<String> onOpenMonth;

  const HrPresenceYearList({
    super.key,
    required this.months,
    required this.onOpenMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PresenceCardFrame(
      title: l10n.hrPresenceYearTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final month in months) ...[
            _MonthRow(month: month, onOpen: onOpenMonth),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final HrAttendanceMonthSummary month;
  final ValueChanged<String> onOpen;

  const _MonthRow({required this.month, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final date = DateTime.tryParse('${month.month}-01');
    final name = date == null ? month.month : dates.formatMonthYear(date);
    String rate(int? pct) =>
        pct == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(pct);
    final presence = month.presenceRatePct;
    final late = month.lateRatePct ?? 0;
    final Widget figures = switch (month.state) {
      HrAttendanceMonthState.holiday => Text(
        l10n.hrPresenceMonthHoliday,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
      ),
      HrAttendanceMonthState.future => Text(
        l10n.hrPresenceMonthFuture,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
      ),
      HrAttendanceMonthState.classMonth => Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: AppDimensions.presenceShareBarWidth,
            child: PresenceShareBar(
              onTimePct: presence == null ? 0 : (presence - late).clamp(0, 100),
              latePct: late,
              absentPct: month.absenceRatePct ?? 0,
              semanticsLabel: l10n.hrPresenceProfileRatesA11y(
                rate(presence),
                rate(month.lateRatePct),
                rate(month.absenceRatePct),
              ),
            ),
          ),
          Text(
            l10n.hrPresenceProfileRates(
              rate(presence),
              rate(month.lateRatePct),
              rate(month.absenceRatePct),
            ),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            l10n.hrPresenceMonthScored(month.scored, month.classDays),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          PresenceProfileBadge(profile: month.profile),
        ],
      ),
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppDimensions.hrPresenceYearMonthWidth,
            child: Text(
              name,
              style: AppTypography.titleSmall.copyWith(
                color: month.isOpenable
                    ? AppColors.textPrimary
                    : AppColors.textMutedAa,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: figures),
          if (month.isOpenable)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
    if (!month.isOpenable) return row;
    return Semantics(
      button: true,
      label: name,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => onOpen(month.month),
        child: TouchTarget(child: row),
      ),
    );
  }
}
