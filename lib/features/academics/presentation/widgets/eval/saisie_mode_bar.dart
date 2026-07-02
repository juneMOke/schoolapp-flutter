import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/note_saisie_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Mode de saisie (spec §7) : Tableau (défaut) ou Focus.
enum SaisieMode { table, focus }

/// Barre au-dessus de la zone de saisie (spec §7) : bascule Tableau | Focus +
/// compteurs par statut recalculés **en direct** sur le brouillon.
class SaisieModeBar extends StatelessWidget {
  final SaisieMode mode;
  final ValueChanged<SaisieMode> onModeChanged;
  final SaisieDraftController draft;

  const SaisieModeBar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmented = SizedBox(
          width: 220,
          child: SegmentedTabFilter<SaisieMode>(
            selected: mode,
            onSelected: onModeChanged,
            expand: true,
            options: [
              SegmentedTabOption(
                label: l10n.evalModeTable,
                value: SaisieMode.table,
                icon: Icons.table_rows_rounded,
              ),
              SegmentedTabOption(
                label: l10n.evalModeFocus,
                value: SaisieMode.focus,
                icon: Icons.center_focus_strong_rounded,
              ),
            ],
          ),
        );

        final counts = AnimatedBuilder(
          animation: draft,
          builder: (context, _) => _StatusCounts(draft: draft),
        );

        // Empile sous ~520 dp pour éviter l'écrasement des compteurs.
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              segmented,
              const SizedBox(height: AppSpacing.md),
              counts,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            segmented,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: counts),
            ),
          ],
        );
      },
    );
  }
}

class _StatusCounts extends StatelessWidget {
  final SaisieDraftController draft;

  const _StatusCounts({required this.draft});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <Widget>[];
    for (final statut in noteStatutCountOrder) {
      final count = draft.countOf(statut);
      if (count == 0) continue; // masqués si 0 (spec §7)
      chips.add(
        _CountChip(
          color: noteStatutVisual(statut).color,
          label: noteStatutCountLabel(l10n, statut, count),
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: chips,
    );
  }
}

class _CountChip extends StatelessWidget {
  final Color color;
  final String label;

  const _CountChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
