import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les filtres d'un registre : puces de statut à compteur, la barre d'outils
/// du module ([toolbar] : recherche, filtres propres, bascule), puis la
/// légende du geste et le nombre d'incidents à justifier.
class PresenceRegisterFilters extends StatelessWidget {
  final int total;
  final int Function(PresenceStatus status) countOf;

  /// `null` = tous les statuts.
  final PresenceStatus? selected;
  final ValueChanged<PresenceStatus?> onStatus;
  final Widget toolbar;
  final CollectionViewMode viewMode;

  /// La légende décrit un geste d'écriture : rien à dire sans lui.
  final bool showLegend;
  final int toJustify;

  const PresenceRegisterFilters({
    super.key,
    required this.total,
    required this.countOf,
    required this.selected,
    required this.onStatus,
    required this.toolbar,
    required this.viewMode,
    required this.showLegend,
    required this.toJustify,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            EteeloFilterChip(
              label: l10n.presenceMarkFilterAll,
              count: total,
              selected: selected == null,
              color: AppColors.bleuArdoise,
              soft: AppColors.bleuArdoiseSoft,
              ink: AppColors.bleuArdoise,
              onTap: () => onStatus(null),
            ),
            for (final status in PresenceStatus.values) _chip(l10n, status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        toolbar,
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.md,
          children: [
            if (showLegend)
              Text(
                viewMode == CollectionViewMode.grid
                    ? l10n.presenceMarkLegendGrid
                    : l10n.presenceMarkLegendList,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
            if (toJustify > 0)
              Text(
                l10n.presenceMarkToJustify(toJustify),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.presenceMarkLateInk,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(AppLocalizations l10n, PresenceStatus status) {
    final tone = PresenceTone.of(status);
    return EteeloFilterChip(
      label: PresenceLabels.filter(l10n, status),
      count: countOf(status),
      selected: selected == status,
      color: tone.color,
      soft: tone.soft,
      ink: tone.ink,
      icon: tone.icon,
      onTap: () => onStatus(selected == status ? null : status),
    );
  }
}
