import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/chapitre_option.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Champ « Chapitres concernés » : checklist des chapitres du cours (bundle
/// `grades-referential`, cochables, couverture intra-agrégat de l'évaluation).
/// Vide (bundle pas encore pullé / cours sans chapitre) → message muet, jamais
/// un champ vide silencieux.
class EvalChaptersField extends StatelessWidget {
  final List<ChapitreOption> options;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  const EvalChaptersField({
    super.key,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.evalCreateFieldChapitres,
          style: AppTypography.labelFormMedium.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (options.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: AppColors.borderStrong),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.evalCreateChapitresEmpty,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option.titre),
                  selected: selectedIds.contains(option.id),
                  onSelected: (checked) {
                    final next = {...selectedIds};
                    if (checked) {
                      next.add(option.id);
                    } else {
                      next.remove(option.id);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
      ],
    );
  }
}
