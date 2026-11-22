import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recouvrement_rule_choice.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bloc de la règle (§4.3) sur son fond chaud : « Est en ordre l'élève
/// qui… », les trois choix, la ligne rouge du contraire et, francs et dollars
/// cochés ensemble, la ligne ambre.
class RecoveryRuleBlock extends StatelessWidget {
  final RecoveryDashboard dashboard;
  final RecoveryRuleKind rule;
  final int? thresholdInCents;
  final bool narrow;
  final ValueChanged<RecoveryRuleKind> onRuleChanged;
  final ValueChanged<int?> onThresholdChanged;

  const RecoveryRuleBlock({
    super.key,
    required this.dashboard,
    required this.rule,
    required this.thresholdInCents,
    required this.narrow,
    required this.onRuleChanged,
    required this.onThresholdChanged,
  });

  /// Fond `#FFFBF4 → #F6EEE4`, bord `#EADBC9` : la terre cuite très diluée.
  static const _fondStart = 3;
  static const _fondEnd = 8;
  static const _bord = 22;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown =
        rule == RecoveryRuleKind.atLeast && !dashboard.atLeastAvailable
        ? RecoveryRuleKind.somePayment
        : rule;
    final threshold = recoveryThresholdText(
      thresholdInCents,
      dashboard.currencies,
    );
    return Container(
      padding: narrow
          ? const EdgeInsets.all(AppSpacing.md)
          : const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.gridGap,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardTones.teinte(AppColors.terreCuite, _fondStart),
            DashboardTones.teinte(AppColors.terreCuite, _fondEnd),
          ],
        ),
        border: Border.all(
          color: ColorMix.tint(AppColors.border, AppColors.terreCuite, _bord),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimensions.recoverySpace10,
        children: [
          Wrap(
            spacing: AppDimensions.recoverySpace10,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                l10n.recoveryStudentsRuleHeading,
                style: AppTypography.displayMedium.copyWith(
                  fontSize: AppDimensions.recoveryStudentsRuleHeadingSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  height: 1.25,
                  color: AppColors.bleuProfond,
                ),
              ),
              Text(
                l10n.recoveryStudentsRuleHint,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          RecouvrementRuleChoice(
            rule: rule,
            thresholdInCents: thresholdInCents,
            counts: dashboard.ruleCounts,
            studentCount: dashboard.studentCount,
            atLeastAvailable: dashboard.atLeastAvailable,
            currency: dashboard.currencies.length == 1
                ? dashboard.currencies.single
                : null,
            onRuleChanged: onRuleChanged,
            onThresholdChanged: onThresholdChanged,
            narrow: narrow,
          ),
          _Line(
            icon: Icons.cancel_outlined,
            color: RecoveryStudentsTones.contraryInk,
            text: recoveryRuleContrary(l10n, shown, threshold),
            style: AppTypography.labelMedium,
          ),
          if (dashboard.isMixed || !dashboard.atLeastAvailable)
            _Line(
              icon: Icons.warning_amber_rounded,
              color: RecoveryStudentsTones.mixedInk,
              text: l10n.recouvrementFeesMixedNotice,
              style: AppTypography.labelSmall,
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final TextStyle style;

  const _Line({
    required this.icon,
    required this.color,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppDimensions.recoverySpace7,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: AppDimensions.recoveryIconSize14, color: color),
      ),
      Expanded(
        child: Text(text, style: style.copyWith(color: color)),
      ),
    ],
  );
}
