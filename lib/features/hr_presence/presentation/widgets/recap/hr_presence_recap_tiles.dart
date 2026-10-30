import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_tile.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les chiffres du bandeau, tels que le serveur les compte. Pour qui lit la
/// paie, d'abord ce que coûte la paie du mois (le brut après absences, par
/// devise) et la retenue ; puis le taux de présence, les absences non
/// justifiées, les jours non pointés, les heures de vacation, et ce que la
/// tablette n'a pas encore envoyé.
///
/// Toutes en ligne au large, deux par ligne en deçà, une seule sur un
/// téléphone étroit ; chaque rangée à la hauteur de sa plus haute tuile.
class HrPresenceRecapTiles extends StatelessWidget {
  final HrAttendanceRecap recap;
  final int unsynced;

  const HrPresenceRecapTiles({
    super.key,
    required this.recap,
    required this.unsynced,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fits =
            ((width + AppSpacing.md) /
                    (AppDimensions.hrPresenceRecapTileMin + AppSpacing.md))
                .floor();
        final wide = width >= AppBreakpoints.hrPresenceRecapTilesInRowMin;
        final perRow = (wide ? fits : 2).clamp(1, fits.clamp(1, tiles.length));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < tiles.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < start + perRow; i++) ...[
                      if (i > start) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: i < tiles.length
                            ? tiles.elementAt(i)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _tiles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final totals = recap.totals;
    final rate = totals.presenceRatePct;
    final amounts = [
      for (final amount in totals.amounts ?? const <HrAttendanceRecapAmount>[])
        if (amount.grossInCents > 0) amount,
    ];
    String money(int cents, String currency) =>
        MoneyFormat.format(Money(cents, currency));
    // Ce qui demande un geste avant la clôture prend l'or du bandeau.
    Color alert(int count) =>
        count > 0 ? AppColors.orDoux : AppColors.presenceMarkOnBanner;
    final deducted = amounts.fold(
      0,
      (sum, amount) => sum + amount.absenceDeductionInCents,
    );
    final hours = totals.hourAmounts ?? const <Money>[];
    return [
      if (amounts.isNotEmpty)
        KubaBannerTile(
          label: l10n.hrPresenceRecapCost(
            PresenceLabels.month(dates, recap.month),
          ),
          values: [
            for (final amount in amounts)
              money(amount.grossAfterAbsenceInCents, amount.currency),
          ],
          detail: recap.payrollStatus == HrRecapPayrollStatus.validated
              ? l10n.hrPresenceRecapCostFrozen
              : l10n.hrPresenceRecapCostPlanned(
                  PresenceLabels.month(
                    dates,
                    SchoolDayCalendar.addMonths(recap.month, 1),
                  ),
                ),
        ),
      if (amounts.isNotEmpty && recap.absenceDeductionEnabled)
        KubaBannerTile(
          label: l10n.hrPresenceRecapDeduction,
          values: [
            for (final amount in amounts)
              amount.absenceDeductionInCents == 0
                  ? money(0, amount.currency)
                  : '− ${money(amount.absenceDeductionInCents, amount.currency)}',
          ],
          valueColor: alert(deducted),
          detail: recap.workingDays > 0
              ? l10n.hrPresenceRecapDeductionDetail(recap.workingDays)
              : null,
        ),
      KubaBannerTile(
        label: l10n.presenceMarkTotalRate,
        values: [
          rate == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(rate),
        ],
        detail: l10n.hrPresenceRecapRateDetail,
      ),
      KubaBannerTile(
        label: l10n.presenceMarkTotalUnjustified,
        values: ['${totals.unjustifiedAbsences}'],
        valueColor: alert(totals.unjustifiedAbsences),
      ),
      KubaBannerTile(
        label: l10n.presenceMarkTotalNotMarked,
        values: ['${recap.unscored}'],
        valueColor: alert(recap.unscored),
      ),
      if (totals.workedMinutes > 0)
        KubaBannerTile(
          label: l10n.staffAttendanceTotalHours,
          values: [PresenceLabels.hours(l10n, totals.workedMinutes)],
          // Le montant, par devise, payé avec le mois (formule 3).
          detail: hours.isEmpty
              ? null
              : hours.map(MoneyFormat.format).join(' · '),
        ),
      if (unsynced > 0)
        KubaBannerTile(
          label: l10n.hrPresenceRecapUnsynced,
          values: ['$unsynced'],
          valueColor: AppColors.orDoux,
        ),
    ];
  }
}
