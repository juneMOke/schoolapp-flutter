import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_period_filter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête : la fenêtre exacte, la période, « Ouvrir la caisse » — et, hors
/// ligne, la date de la photo affichée.
///
/// Il reste en place sous un état vide ou une erreur : la période doit rester
/// accessible, c'est souvent elle qui fait sortir du vide.
class BoutiqueDashboardHeader extends StatelessWidget {
  final DashboardPeriod period;
  final DashboardWindow? window;
  final DateTime? cachedAt;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final VoidCallback onOpenTill;

  /// Relit la période retenue : rien d'autre ne fait revenir l'écran sur la
  /// journée qui a tourné, ni ne retire les tickets partis entre-temps.
  final VoidCallback onRefresh;

  const BoutiqueDashboardHeader({
    super.key,
    required this.period,
    required this.window,
    required this.onPeriodChanged,
    required this.onOpenTill,
    required this.onRefresh,
    this.cachedAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final window = this.window;
    final cachedAt = this.cachedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (window != null)
          Text(
            BoutiqueDashboardLabels.windowSubtitle(window, l10n),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        if (cachedAt != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          StatusBadge(
            icon: Icons.cloud_off_outlined,
            label: l10n.boutiqueDashboardCachedBadge(
              formatSchoolDateTime(cachedAt),
            ),
            color: AppColors.warning,
          ),
        ],
        const SizedBox(height: AppDimensions.spacingM),
        Wrap(
          spacing: AppDimensions.spacingM,
          runSpacing: AppDimensions.spacingS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            BoutiqueDashboardPeriodFilter(
              selected: period,
              onChanged: onPeriodChanged,
            ),
            EteeloButton.ghost(
              label: l10n.boutiqueDashboardRefresh,
              icon: Icons.refresh_rounded,
              onPressed: onRefresh,
              fullWidth: false,
            ),
            EteeloButton.primary(
              label: l10n.boutiqueDashboardOpenTill,
              icon: Icons.storefront_outlined,
              onPressed: onOpenTill,
              fullWidth: false,
            ),
          ],
        ),
      ],
    );
  }
}
