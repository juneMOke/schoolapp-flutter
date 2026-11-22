import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_insight_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_figures.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// G · trois lectures (R13) : ce que les chiffres impliquent, chacune fondée
/// sur un bloc visible plus haut. **Aucune n'ordonne une sanction.**
///
/// Grille `minmax(260px, 1fr)` : une colonne au téléphone, 2 + 1 de 552 à
/// 708 reçus, trois en ligne dès 828.
class RecoveryInsightsRow extends StatelessWidget {
  final RecoveryDashboard dashboard;

  /// Le frais du bloc D : son classement nourrit « Écart entre classes ».
  final String? rankingFeeCode;
  final int unmanageableBelow;
  final VoidCallback onControlStudents;

  const RecoveryInsightsRow({
    super.key,
    required this.dashboard,
    required this.rankingFeeCode,
    required this.unmanageableBelow,
    required this.onControlStudents,
  });

  static const _gap = AppSpacing.gridGap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [?_worstFee(l10n), ?_spread(l10n), _simulation(l10n)];
    return LayoutBuilder(
      builder: (context, constraints) {
        const min = AppDimensions.recouvrementInsightMinWidth;
        final width = constraints.maxWidth;
        final columns = ((width + _gap) / (min + _gap)).floor().clamp(
          1,
          cards.length,
        );
        final cell = ((width - _gap * (columns - 1)) / columns).floorToDouble();
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final card in cards) SizedBox(width: cell, child: card),
          ],
        );
      },
    );
  }

  /// Le frais au plus petit taux ; un frais sans attendu (taux `null`) ne
  /// se classe pas.
  Widget? _worstFee(AppLocalizations l10n) {
    RecoveryFeeRate? worst;
    for (final rate in dashboard.feeRates) {
      final percent = rate.figures.ratePercent;
      if (percent == null) continue;
      if (worst == null || percent < worst.figures.ratePercent!) worst = rate;
    }
    if (worst == null) return null;
    return RecoveryInsightCard(
      icon: Icons.percent,
      tone: AppColors.error,
      title: l10n.recoveryInsightWorstFeeTitle,
      body: l10n.recoveryInsightWorstFeeBody(
        worst.label,
        worst.figures.ratePercent!,
        MoneyFormat.format(worst.figures.outstanding),
      ),
      actionLabel: l10n.recoveryInsightControl,
      onAction: onControlStudents,
    );
  }

  /// Le classement du bloc D — même choix : le frais choisi, sinon le
  /// premier. Muette sous deux classes classées.
  Widget? _spread(AppLocalizations l10n) {
    final rankings = dashboard.classRankings;
    if (rankings.isEmpty) return null;
    final ranking =
        rankings.where((r) => r.feeCode == rankingFeeCode).firstOrNull ??
        rankings.first;
    final ranked = [
      for (final row in ranking.ranked)
        if (row.ratePercent != null) row,
    ];
    if (ranked.length < 2) return null;
    final best = ranked.first;
    final worst = ranked.last;
    return RecoveryInsightCard(
      icon: Icons.school_outlined,
      tone: AppColors.bleuArdoise,
      title: l10n.recoveryInsightSpreadTitle,
      body: l10n.recoveryInsightSpreadBody(
        recoveryFeeInSentence(_feeLabel(ranking.feeCode)),
        best.ratePercent!,
        best.classroomName,
        worst.ratePercent!,
        worst.classroomName,
      ),
    );
  }

  String _feeLabel(String code) =>
      dashboard.fees.where((f) => f.code == code).firstOrNull?.label ??
      dashboard.feeRates.where((f) => f.feeCode == code).firstOrNull?.label ??
      code;

  Widget _simulation(AppLocalizations l10n) {
    final simulation = dashboard.simulation;
    final count = recoveryUnmanageableRows(
      simulation,
      unmanageableBelow,
    ).length;
    return RecoveryInsightCard(
      icon: count > 0
          ? Icons.warning_amber_rounded
          : Icons.check_circle_outline,
      tone: count > 0 ? AppColors.error : AppColors.vertSavane,
      title: l10n.recoveryInsightSimulationTitle,
      body: count > 0
          ? l10n.recoveryInsightSimulationUnmanageable(count, unmanageableBelow)
          : l10n.recoveryInsightSimulationTenable(
              unmanageableBelow,
              simulation.remainingHeadcount,
              simulation.headcount,
            ),
    );
  }
}

/// Le titre d'un frais au milieu d'une phrase : « Sur frais de scolarité »
/// comme la maquette — mais un sigle (« TENAFEP ») garde ses capitales.
String recoveryFeeInSentence(String label) {
  if (label.length < 2) return label;
  final second = label[1];
  if (second.toUpperCase() == second) return label;
  return label[0].toLowerCase() + label.substring(1);
}
