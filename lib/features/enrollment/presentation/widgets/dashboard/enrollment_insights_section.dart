import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_dashboard_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Lectures & alertes » — ce que les chiffres au-dessus ne disent pas seuls.
///
/// ## Aucune carte n'est rendue pour remplir la ligne
///
/// C'est la règle de ce bloc, et elle est stricte : chaque carte a sa
/// condition, et une rangée à une seule carte est un rendu normal. Une carte
/// « Pic » sur une série vide, ou « demandes à traiter » quand il n'y en a
/// aucune, dirait quelque chose de faux avec l'autorité d'un encadré.
///
/// Deux cartes de la spec — Croissance et Saturation — n'apparaissent qu'à
/// partir de la deuxième année scolaire et ne sont donc pas encore ici : elles
/// dépendent du drapeau d'établissement, qui arrive avec son lot.
class EnrollmentInsightsSection extends StatelessWidget {
  final EnrollmentStats stats;

  /// Ouvre l'écran des pré-inscriptions. `null` retire l'action sans retirer
  /// la carte : l'information reste vraie même sans raccourci.
  final VoidCallback? onOpenPreRegistrations;

  const EnrollmentInsightsSection({
    super.key,
    required this.stats,
    this.onOpenPreRegistrations,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = <Widget>[
      ..._peakCard(l10n),
      _parityCard(l10n),
      ..._pendingCard(l10n),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.enrollmentDashboardInsightsTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppDimensions.spacingM;
            const min = AppDimensions.enrollmentDashboardInsightMinWidth;
            final columns = ((constraints.maxWidth + gap) / (min + gap))
                .floor()
                .clamp(1, cards.length);
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Le bucket le plus fort — **seulement s'il compte quelque chose**.
  ///
  /// Le titre suit le grain : un « jour le plus fort » sur une série mensuelle
  /// serait un contresens.
  List<Widget> _peakCard(AppLocalizations l10n) {
    final buckets = stats.evolution.buckets;
    if (buckets.isEmpty) return const [];

    final peak = buckets.reduce((a, b) => b.value > a.value ? b : a);
    if (peak.value <= 0) return const [];

    final title = switch (stats.evolution.granularity) {
      EvolutionGranularity.day => l10n.enrollmentDashboardInsightPeakDay,
      EvolutionGranularity.week => l10n.enrollmentDashboardInsightPeakWeek,
      EvolutionGranularity.month => l10n.enrollmentDashboardInsightPeakMonth,
    };

    return [
      _InsightCard(
        icon: Icons.trending_up_rounded,
        accent: AppColors.enrollmentStatsFirst,
        accentSoft: AppColors.enrollmentStatsFirstSoft,
        title: title,
        body: l10n.enrollmentDashboardInsightPeakBody(
          peak.longLabel.isEmpty ? peak.shortLabel : peak.longLabel,
          l10n.enrollmentDashboardStudentsCount(peak.value),
        ),
      ),
    ];
  }

  /// La parité — **toujours rendue**, avec un commentaire différencié.
  ///
  /// Le seuil de 45–55 % n'est pas une norme à atteindre : c'est la fourchette
  /// dans laquelle un écart ne se commente pas. En dehors, la carte le dit
  /// sans porter de jugement.
  Widget _parityCard(AppLocalizations l10n) {
    final girls = stats.headcount.segments
        .where((s) => s.code == GenderSegmentCode.female)
        .fold<int>(0, (sum, s) => sum + s.value);
    final share = EnrollmentDashboardFormat.share(girls, stats.headcount.total);
    final balanced = share >= 45 && share <= 55;

    return _InsightCard(
      icon: Icons.balance_rounded,
      accent: balanced ? AppColors.vertSavane : AppColors.terreCuite,
      accentSoft: balanced
          ? AppColors.enrollmentStatsFirstSoft
          : AppColors.terreCuiteSoft,
      title: l10n.enrollmentDashboardInsightParityTitle,
      body: balanced
          ? l10n.enrollmentDashboardInsightParityBalanced(share)
          : l10n.enrollmentDashboardInsightParitySkewed(share),
    );
  }

  /// Les demandes en ligne — **seulement s'il y en a**.
  List<Widget> _pendingCard(AppLocalizations l10n) {
    final pending = stats.kpis.preEnrollments.value;
    if (pending <= 0) return const [];

    return [
      _InsightCard(
        icon: Icons.public_rounded,
        accent: AppColors.enrollmentStatsPre,
        accentSoft: AppColors.enrollmentStatsPreSoft,
        title: l10n.enrollmentDashboardInsightPreTitle,
        body: l10n.enrollmentDashboardInsightPreBody(pending),
        action: onOpenPreRegistrations == null
            ? null
            : EteeloButton.ghost(
                label: l10n.enrollmentDashboardInsightPreAction,
                icon: Icons.arrow_forward_rounded,
                onPressed: onOpenPreRegistrations,
                fullWidth: false,
              ),
      ),
    ];
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String body;
  final Widget? action;

  const _InsightCard({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppDimensions.enrollmentDashboardInsightBadgeSize,
                    height: AppDimensions.enrollmentDashboardInsightBadgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingS,
                      ),
                    ),
                    child: Icon(icon, size: 16, color: accent),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          body,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppDimensions.spacingS),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
