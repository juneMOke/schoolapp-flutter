import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Dernière diffusion : … · Historique » (spec S5), puis, déplié, les
/// diffusions de la plus récente à la plus ancienne.
class CopieHistory extends StatefulWidget {
  /// La plus récente d'abord.
  final List<CopieDiffusion> log;

  const CopieHistory({super.key, required this.log});

  @override
  State<CopieHistory> createState() => _CopieHistoryState();
}

class _CopieHistoryState extends State<CopieHistory> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final log = widget.log;
    if (log.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.copieLastDiffusion(diffusionLabel(context, log.first)),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _open = !_open),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.bleuArdoise,
              ),
              child: Text(l10n.copieHistory),
            ),
          ],
        ),
        if (_open)
          for (final diffusion in log)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    diffusion.kind == CopieKind.print
                        ? Icons.print_outlined
                        : Icons.share_outlined,
                    size: AppDimensions.sujetIconSize,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      diffusionLabel(context, diffusion),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (diffusion.corrige) ...[
                    const SizedBox(width: AppSpacing.sm),
                    NotationPill(
                      color: AppColors.academicsScoreGood,
                      soft: AppColors.academicsScoreGoodSoft,
                      label: l10n.copieCorrigePill,
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}
