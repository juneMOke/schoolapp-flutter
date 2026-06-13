import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_distribution_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Zone de synthese : surface unique teintee (degrade + filigrane Kuba) qui
/// regroupe l'en-tete, la bande de cartes KPI partagee ([EteeloKpiBand]) et la
/// barre de repartition.
class PresenceSummaryCard extends StatelessWidget {
  final PresenceSummaryViewData data;

  /// Libelle de plage affiche en en-tete (ex. « Annee scolaire 2025-2026 »).
  final String rangeLabel;

  const PresenceSummaryCard({
    super.key,
    required this.data,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AppDimensions.sectionCardRadius);

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.presenceSummaryA11yLabel(data.ratePercent),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.presenceSummaryTintTop,
              AppColors.presenceSummaryTintBottom,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // KubaPatternLayer se place directement dans le Stack : il
              // fournit lui-meme son Positioned.fill (cf. AppPageBackground).
              const KubaPatternLayer(),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryHeader(
                      title: l10n.presenceSummaryTitle,
                      meta:
                          '$rangeLabel · ${l10n.presenceSchoolDaysCount(data.total)}',
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    EteeloKpiBand(cards: _cards(l10n)),
                    const SizedBox(height: AppDimensions.spacingM),
                    PresenceDistributionBar(data: data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EteeloKpiCardData> _cards(AppLocalizations l10n) => [
    EteeloKpiCardData(
      label: l10n.presenceKpiRate,
      valueText: l10n.presenceRateValue(data.ratePercent),
      accent: data.rateColor,
      accentSoft: data.rateColor.withValues(alpha: 0.12),
      icon: Icons.percent_rounded,
    ),
    _statusCard(l10n, AttendanceDayStatus.present, data.present),
    _statusCard(l10n, AttendanceDayStatus.justified, data.justified),
    _statusCard(l10n, AttendanceDayStatus.unjustified, data.unjustified),
  ];

  EteeloKpiCardData _statusCard(
    AppLocalizations l10n,
    AttendanceDayStatus status,
    int value,
  ) => EteeloKpiCardData(
    label: status.label(l10n),
    value: value,
    accent: status.color,
    accentSoft: status.softColor,
    icon: status.icon,
  );
}

class _SummaryHeader extends StatelessWidget {
  final String title;
  final String meta;

  const _SummaryHeader({required this.title, required this.meta});

  @override
  Widget build(BuildContext context) {
    final medallion = Container(
      width: AppDimensions.presenceMedallionSize,
      height: AppDimensions.presenceMedallionSize,
      decoration: BoxDecoration(
        color: AppColors.bleuArdoise,
        borderRadius: BorderRadius.circular(
          AppDimensions.presenceMedallionRadius,
        ),
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        size: AppDimensions.detailMiniIconSize,
        color: Colors.white,
      ),
    );
    final titleText = Text(
      title,
      style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
    );
    final metaText = Text(
      meta,
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  medallion,
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(child: titleText),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              metaText,
            ],
          );
        }
        return Row(
          children: [
            medallion,
            const SizedBox(width: AppDimensions.spacingS),
            titleText,
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: metaText),
            ),
          ],
        );
      },
    );
  }
}
