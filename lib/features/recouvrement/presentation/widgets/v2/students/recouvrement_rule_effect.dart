import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le rond radio d'un choix de règle.
class RecoveryRuleRadio extends StatelessWidget {
  final bool checked;

  const RecoveryRuleRadio({super.key, required this.checked});

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.recoveryStudentsRadioSize,
    height: AppDimensions.recoveryStudentsRadioSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.surfaceRaised,
      border: Border.all(
        color: checked ? AppColors.bleuProfond : AppColors.textMuted,
        width: AppDimensions.recoveryStudentsRadioBorderWidth,
      ),
    ),
    child: checked
        ? Container(
            width: AppDimensions.recoveryStudentsRadioDot,
            height: AppDimensions.recoveryStudentsRadioDot,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bleuProfond,
            ),
          )
        : null,
  );
}

/// La jauge et « {n} en ordre » (D8) — « saisissez un montant » sans montant.
class RecoveryRuleEffect extends StatelessWidget {
  final int? count;
  final bool awaitingAmount;
  final int total;

  const RecoveryRuleEffect({
    super.key,
    required this.count,
    required this.awaitingAmount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = count;
    final share = n == null || total <= 0 ? 0.0 : (n / total).clamp(0.0, 1.0);
    final text = awaitingAmount
        ? l10n.recoveryStudentsRuleEnterAmount
        : n == null
        ? null
        : l10n.recoveryStudentsRuleInOrderCount(n);
    return Row(
      spacing: AppDimensions.recoverySpace6,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.recoveryStudentsGaugeWidth,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.brPill,
              child: SizedBox(
                height: AppDimensions.recoveryStudentsGaugeHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: DashboardSense.manquant.withValues(alpha: 0.25),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: share,
                      child: const ColoredBox(color: DashboardSense.encaisse),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Un compteur ne passe jamais à la ligne : il se réduit plutôt.
        if (text != null)
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: n == null || awaitingAmount
                      ? AppColors.textMuted
                      : DashboardSense.encaisse,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
