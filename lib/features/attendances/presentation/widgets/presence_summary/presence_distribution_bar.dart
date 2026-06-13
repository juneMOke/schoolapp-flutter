import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre proportionnelle de repartition des jours par statut + sous-titre.
///
/// A11y : `Semantics(image)` portant un libelle global ; chaque segment porte
/// un `Tooltip` « {statut} · {n} ». Les statuts a 0 sont omis.
class PresenceDistributionBar extends StatelessWidget {
  final PresenceSummaryViewData data;

  const PresenceDistributionBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final segments = <({AttendanceDayStatus status, int count})>[
      (status: AttendanceDayStatus.present, count: data.present),
      (status: AttendanceDayStatus.justified, count: data.justified),
      (status: AttendanceDayStatus.unjustified, count: data.unjustified),
    ].where((s) => s.count > 0).toList();

    final bar = Semantics(
      image: true,
      label: l10n.presenceDistributionA11yLabel,
      child: Container(
        height: AppDimensions.presenceDistributionBarHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              Expanded(
                flex: segments[i].count,
                child: Tooltip(
                  message:
                      '${segments[i].status.label(l10n)} · ${segments[i].count}',
                  child: ColoredBox(color: segments[i].status.cellColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final subtitle = Text(
      l10n.presencePresentOutOfTotal(data.present, data.total),
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar,
              const SizedBox(height: AppDimensions.spacingS),
              subtitle,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: bar),
            const SizedBox(width: AppDimensions.spacingM),
            subtitle,
          ],
        );
      },
    );
  }
}
