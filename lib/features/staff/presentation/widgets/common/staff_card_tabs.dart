import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le badge d'un onglet : un libellé court sur une pastille teintée.
typedef StaffTabBadge = ({String label, Color soft, Color ink});

/// Un onglet en carte : icône, titre jamais tronqué, sous-titre court et
/// badge d'état facultatif.
class StaffCardTab<T> {
  final T id;
  final IconData icon;
  final String title;
  final String subtitle;
  final StaffTabBadge? badge;

  const StaffCardTab({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });
}

/// Les onglets en cartes des écrans RH (Pointage, Paie) : une rangée de cartes
/// de même largeur, l'active sur le bandeau sombre.
class StaffCardTabs<T> extends StatelessWidget {
  final List<StaffCardTab<T>> tabs;
  final T active;
  final ValueChanged<T> onSelect;

  const StaffCardTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Autant de colonnes que la largeur en tient à la largeur plancher
      // d'une carte : quatre onglets passent en 2 × 2 sur un écran étroit,
      // plutôt que de casser leur titre lettre par lettre.
      final fit =
          ((constraints.maxWidth + AppSpacing.sm) /
                  (AppDimensions.staffAttendanceCardMinWidth + AppSpacing.sm))
              .floor();
      final columns = fit.clamp(1, tabs.length);
      final width =
          (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final tab in tabs)
            SizedBox(
              width: width,
              child: _TabCard(
                data: tab,
                active: tab.id == active,
                onTap: () => onSelect(tab.id),
              ),
            ),
        ],
      );
    },
  );
}

class _TabCard extends StatelessWidget {
  final StaffCardTab<Object?> data;
  final bool active;
  final VoidCallback onTap;

  const _TabCard({
    required this.data,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = active
        ? AppColors.staffAttendanceOnBanner
        : AppColors.textPrimary;
    final muted = active
        ? AppColors.staffAttendanceOnBannerMuted
        : AppColors.textSecondary;
    final badge = data.badge;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              color: active ? null : AppColors.surfaceRaised,
              gradient: active
                  ? const LinearGradient(
                      colors: [
                        AppColors.staffAttendanceBannerStart,
                        AppColors.staffAttendanceBannerMid,
                      ],
                    )
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: active ? AppColors.terreCuite : AppColors.border,
                  width: AppSpacing.xs,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.lg + AppSpacing.xs,
                  backgroundColor: active
                      ? AppColors.terreCuite
                      : AppColors.surfaceAlt,
                  child: Icon(
                    data.icon,
                    color: active
                        ? AppColors.staffAttendanceOnBanner
                        : AppColors.bleuArdoise,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTypography.titleSmall.copyWith(color: ink),
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            data.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: muted,
                            ),
                          ),
                          if (badge != null) _Badge(badge),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final StaffTabBadge badge;

  const _Badge(this.badge);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(
      color: badge.soft,
      borderRadius: AppRadius.brPill,
    ),
    child: Text(
      badge.label,
      style: AppTypography.labelSmall.copyWith(color: badge.ink),
    ),
  );
}
