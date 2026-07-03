import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';

/// Légende des classes (spec §6) : une puce couleur + libellé par classe
/// présente dans la semaine. La couleur seule n'est jamais porteuse de sens —
/// le libellé accompagne toujours la teinte (contrat AA).
class ScheduleLegend extends StatelessWidget {
  final List<ScheduleLegendEntry> entries;

  const ScheduleLegend({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.gridGap,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.visual.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                entry.classroomLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
