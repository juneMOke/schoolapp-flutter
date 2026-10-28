import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_month.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_tile.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau du récapitulatif : le mois et sa navigation, puis les totaux
/// du mois tels que le serveur les compte — taux de présence (hors
/// vacataires à l'heure), absences non justifiées, jours non pointés, heures
/// de vacation (et leur montant, par devise, pour qui lit la paie), et ce
/// que la tablette n'a pas encore envoyé.
///
/// Le mois reste à l'écran pendant le chargement et sur une erreur : il
/// pilote tout l'écran.
class HrPresenceRecapHero extends StatelessWidget {
  final HrPresenceRecapState state;

  const HrPresenceRecapHero({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceRecapCubit>();
    final recap = state.recap;
    final showTotals = recap != null && recap.classDays > 0;
    return KubaBanner(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              KubaBannerMonth(
                eyebrow: l10n.hrPresenceRecapEyebrow,
                month: state.month,
                status: null,
                onPrevious: state.canStepBack
                    ? () => unawaited(cubit.stepMonth(-1))
                    : null,
                onNext: state.isCurrentMonth
                    ? null
                    : () => unawaited(cubit.stepMonth(1)),
                onCurrent: state.isCurrentMonth
                    ? null
                    : () => unawaited(cubit.goCurrentMonth()),
                onPick: () => unawaited(_pick(context, cubit)),
              ),
              if (recap != null && recap.classDays > 0)
                Text(
                  recap.toDate
                      ? l10n.hrPresenceRecapClassDaysToDate(recap.classDays)
                      : l10n.hrPresenceRecapClassDays(recap.classDays),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.presenceMarkOnBannerMuted,
                  ),
                ),
            ],
          ),
          if (showTotals) ...[
            const SizedBox(height: AppSpacing.lg),
            _Tiles(recap: recap, unsynced: state.unsynced),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, HrPresenceRecapCubit cubit) async {
    final picked = await pickPresenceMonth(
      context,
      month: state.month,
      firstMonth: state.firstMonth,
      lastMonth: state.currentMonth,
    );
    if (picked != null && !cubit.isClosed) unawaited(cubit.showMonth(picked));
  }
}

/// Les tuiles : toutes en ligne au large, deux par ligne en deçà, une seule
/// sur un téléphone étroit.
class _Tiles extends StatelessWidget {
  final HrAttendanceRecap recap;
  final int unsynced;

  const _Tiles({required this.recap, required this.unsynced});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totals = recap.totals;
    final rate = totals.presenceRatePct;
    // Ce qui demande un geste avant la clôture prend l'or du bandeau.
    Color alert(int count) =>
        count > 0 ? AppColors.orDoux : AppColors.presenceMarkOnBanner;
    final tiles = [
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
      KubaBannerTile(
        label: l10n.staffAttendanceTotalHours,
        values: [PresenceLabels.hours(l10n, totals.workedMinutes)],
        // Montant indicatif, par devise : la Paie paie ces heures (A1).
        detail: switch (totals.amounts) {
          final amounts? when amounts.isNotEmpty =>
            amounts.map(MoneyFormat.format).join(' · '),
          _ => null,
        },
      ),
      if (unsynced > 0)
        KubaBannerTile(
          label: l10n.hrPresenceRecapUnsynced,
          values: ['$unsynced'],
          valueColor: AppColors.orDoux,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        var perRow =
            constraints.maxWidth >= AppBreakpoints.hrPresenceRecapTilesInRowMin
            ? tiles.length
            : 2;
        final width =
            (constraints.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;
        if (width < AppDimensions.hrPresenceRecapTileMin) perRow = 1;
        // Rangée par rangée, à la hauteur de la plus haute tuile : une
        // tuile sans ligne de détail ne reste pas plus courte que sa voisine.
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
}
