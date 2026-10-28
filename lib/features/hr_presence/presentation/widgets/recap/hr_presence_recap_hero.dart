import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_month.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_tiles.dart';
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
                status: recap == null || recap.totals.amounts == null
                    ? null
                    : _StatusPill(
                        frozen:
                            recap.payrollStatus ==
                            HrRecapPayrollStatus.validated,
                      ),
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
            HrPresenceRecapTiles(recap: recap, unsynced: state.unsynced),
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

/// « Prévu » ou « Figé » : les montants d'une paie validée ne bougent plus.
class _StatusPill extends StatelessWidget {
  final bool frozen;

  const _StatusPill({required this.frozen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.presenceMarkOnBannerMuted),
      ),
      child: Text(
        frozen
            ? l10n.hrPresenceRecapStatusFrozen
            : l10n.hrPresenceRecapStatusPlanned,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.presenceMarkOnBanner,
        ),
      ),
    );
  }
}
