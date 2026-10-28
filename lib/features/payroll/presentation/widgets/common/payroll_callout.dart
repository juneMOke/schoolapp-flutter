import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';

/// L'habillage d'un [PayrollCallout].
enum PayrollCalloutKind {
  /// Voile et bord de sa teinte : ce qui demande d'agir (arriérés, taux
  /// réduit).
  tinted,

  /// Carte blanche bordée : le geste du mois.
  plain,

  /// Contour pointillé : une possibilité, rien n'est engagé.
  dashed,
}

/// Un bandeau du livre en carte : un carreau d'icône, un titre et ses lignes
/// de détail, le geste à droite — dessous sur un écran étroit.
class PayrollCallout extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> details;

  /// Le ou les boutons ; `null` : le bandeau se lit seulement.
  final Widget? action;
  final PayrollCalloutKind kind;

  /// La teinte d'un bandeau [PayrollCalloutKind.tinted].
  final PayrollTone? tone;

  const PayrollCallout({
    super.key,
    required this.icon,
    required this.title,
    this.details = const [],
    this.action,
    this.kind = PayrollCalloutKind.plain,
    this.tone,
  }) : assert(kind != PayrollCalloutKind.tinted || tone != null);

  @override
  Widget build(BuildContext context) {
    final tone = kind == PayrollCalloutKind.tinted ? this.tone : null;
    final ink = tone?.ink ?? AppColors.textPrimary;
    final tile = Container(
      width: AppDimensions.payrollCalloutIcon,
      height: AppDimensions.payrollCalloutIcon,
      decoration: BoxDecoration(
        color: tone == null ? AppColors.surfaceAlt : AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(
        icon,
        size: AppSpacing.xl,
        color: tone?.ink ?? AppColors.textSecondary,
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final detail in details)
          Text(
            detail,
            style: AppTypography.bodySmall.copyWith(
              color: tone?.ink ?? AppColors.textSecondary,
            ),
          ),
      ],
    );
    final action = this.action;
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final lead = Row(
          children: [
            tile,
            const SizedBox(width: AppSpacing.md),
            Expanded(child: texts),
          ],
        );
        if (action == null) return lead;
        if (constraints.maxWidth < AppBreakpoints.dataTableCardsMax) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              lead,
              const SizedBox(height: AppSpacing.md),
              Align(alignment: AlignmentDirectional.centerEnd, child: action),
            ],
          );
        }
        // Le texte prend trois parts, le geste deux, calé à droite :
        // plusieurs boutons passent à la ligne plutôt que de déborder.
        return Row(
          children: [
            Expanded(flex: 3, child: lead),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: action,
              ),
            ),
          ],
        );
      },
    );
    const padding = EdgeInsets.all(AppSpacing.md);
    if (kind == PayrollCalloutKind.dashed) {
      return EteeloDashedContainer(
        backgroundColor: AppColors.surfaceRaised,
        borderColor: AppColors.border,
        borderRadius: AppRadius.brLg,
        padding: padding,
        child: body,
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tone?.soft ?? AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: tone?.color ?? AppColors.border),
      ),
      child: body,
    );
  }
}
