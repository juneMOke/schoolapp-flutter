import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Chap. 3 · séance 2 » sous le contenu d'une séance rattachée ; le titre
/// complet du chapitre en infobulle.
class JournalChapterChip extends StatelessWidget {
  final JournalChapterTag tag;

  const JournalChapterChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seanceNo = tag.seanceNo;
    final label = seanceNo == null
        ? l10n.journalChapterTagShort(tag.number)
        : l10n.journalChapterTag(tag.number, seanceNo);
    return Tooltip(
      message: tag.title,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.chipPaddingH,
          vertical: AppSpacing.xs / 2,
        ),
        decoration: const BoxDecoration(
          color: AppColors.terreCuiteSoft,
          borderRadius: AppRadius.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.link_rounded,
              size: AppDimensions.journalTagIconSize,
              color: AppColors.terreCuiteDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.terreCuiteDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
