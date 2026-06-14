import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de contexte compacte du tableau de bord des présences.
///
/// Carte surélevée affichant en ligne trois repères de contexte (année
/// scolaire, fenêtre analysee, horodatage de génération) séparés par de fins
/// traits verticaux. Le [Wrap] permet le retour à la ligne sur largeur réduite.
class AttendanceOverviewContextBar extends StatelessWidget {
  final StatsContext context;

  const AttendanceOverviewContextBar({super.key, required this.context});

  @override
  Widget build(BuildContext buildContext) {
    final l10n = AppLocalizations.of(buildContext)!;

    final items = <Widget>[
      _ContextItem(
        icon: Icons.calendar_today_outlined,
        label: l10n.attendanceOverviewContextSchoolYear,
        value: context.schoolYear,
      ),
      _ContextItem(
        icon: Icons.date_range_outlined,
        label: l10n.attendanceOverviewContextWindow,
        value: AttendanceOverviewFormat.window(
          context.periodStart,
          context.periodEnd,
          buildContext,
        ),
      ),
      _ContextItem(
        icon: Icons.update_outlined,
        label: l10n.attendanceOverviewContextGeneratedAt,
        value: AttendanceOverviewFormat.generatedAt(
          context.generatedAt,
          buildContext,
        ),
      ),
    ];

    return Semantics(
      container: true,
      label: l10n.attendanceOverviewContextA11yLabel,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        // Une ligne avec séparateurs verticaux au-dessus de detailCompactMax ;
        // en deçà, repères enroulés SANS séparateurs (évite les traits
        // orphelins en début de run).
        child: LayoutBuilder(
          builder: (layoutContext, constraints) {
            if (constraints.maxWidth >= AppBreakpoints.detailCompactMax) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(width: AppDimensions.spacingL),
                      const _ContextDivider(),
                      const SizedBox(width: AppDimensions.spacingL),
                    ],
                    items[i],
                  ],
                ],
              );
            }
            return Wrap(
              spacing: AppDimensions.spacingL,
              runSpacing: AppDimensions.spacingM,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: items,
            );
          },
        ),
      ),
    );
  }
}

/// Repère de contexte : pastille d'icône + libellé majuscule discret + valeur.
class _ContextItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContextItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          child: Icon(icon, size: 18, color: AppColors.bleuArdoise),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              value,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Fin trait vertical (1 dp) séparant deux repères de contexte.
class _ContextDivider extends StatelessWidget {
  const _ContextDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: AppColors.border);
  }
}
