import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte claire « Situation des {n} élèves » du bloc B : la barre à trois
/// parts, puis une ligne par situation — chacune ouvre Contrôle des frais sur
/// cette situation (R15, I3).
///
/// La barre se dessine **sans** sa légende (`showLegend: false`) : les trois
/// lignes cliquables la remplacent, chacune avec son mot, sa pastille et son
/// compteur — la couleur n'est jamais seule.
class RecoverySituationCard extends StatelessWidget {
  final RecoverySituationCounts counts;
  final int studentCount;
  final ValueChanged<StudentChargeStatus> onSituationTapped;

  const RecoverySituationCard({
    super.key,
    required this.counts,
    required this.studentCount,
    required this.onSituationTapped,
  });

  /// L'ordre de la maquette : rien payé, partiel, soldé — et leurs sens.
  static const situations = [
    (StudentChargeStatus.due, DashboardSense.manquant),
    (StudentChargeStatus.partial, DashboardSense.attente),
    (StudentChargeStatus.paid, DashboardSense.encaisse),
  ];

  static String labelOf(StudentChargeStatus status, AppLocalizations l10n) =>
      switch (status) {
        StudentChargeStatus.due => l10n.recoveryFiguresSituationNoPayment,
        StudentChargeStatus.partial => l10n.recoveryFiguresSituationPartial,
        StudentChargeStatus.paid => l10n.recoveryFiguresSituationSettled,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.insPaveMinHeight,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.insPavePaddingH,
        AppDimensions.insPavePaddingTop,
        AppDimensions.insPavePaddingH,
        AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.insPaveRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: DashboardTones.sectionShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: AppDimensions.insPaveMedallionIconSize,
                color: AppColors.bleuArdoise,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Semantics(
                  header: true,
                  label: l10n.recoveryFiguresSituationTitle(studentCount),
                  child: ExcludeSemantics(
                    child: Text(
                      l10n
                          .recoveryFiguresSituationTitle(studentCount)
                          .toUpperCase(),
                      style: AppTextStyles.badge.copyWith(
                        letterSpacing: AppDimensions.insPaveLabelLetterSpacing,
                        color: AppColors.textMutedAa,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          EteeloSplitBar(
            showLegend: false,
            height: AppDimensions.recoverySituationBarHeight,
            semanticsLabel: l10n.recoveryFiguresSituationBarA11y(
              counts.noPayment,
              counts.partial,
              counts.settled,
            ),
            segments: [
              for (final (status, color) in situations)
                EteeloSplitBarSegment(
                  label: labelOf(status, l10n),
                  valueLabel: '${counts.of(status)}',
                  value: counts.of(status),
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          for (final (status, color) in situations)
            _SituationRow(
              label: labelOf(status, l10n),
              count: counts.of(status),
              color: color,
              onTap: () => onSituationTapped(status),
            ),
        ],
      ),
    );
  }
}

/// Une ligne cliquable : pastille, mot, compteur, chevron — cible 48 dp.
class _SituationRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _SituationRow({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = DashboardTones.encreLisible(color);

    return Semantics(
      button: true,
      label: l10n.recoveryFiguresSituationRowA11y(label, count),
      hint: l10n.recoveryFiguresSituationRowHint,
      excludeSemantics: true,
      child: Tooltip(
        message: l10n.recoveryFiguresSituationRowHint,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.recouvrementCountDot,
                  height: AppDimensions.recouvrementCountDot,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.spacingXS / 2,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                // Le mot peut passer à la ligne ; le compteur jamais.
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '$count',
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: ink,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                const Icon(
                  Icons.chevron_right,
                  size: AppDimensions.recouvrementChevronSize,
                  color: AppColors.textMutedAa,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
