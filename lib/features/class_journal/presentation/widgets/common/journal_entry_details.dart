import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_chapter_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui a été saisi à une séance, en « libellé / valeur » — les seuls champs
/// remplis — puis l'étiquette chapitre. Partagé par la carte d'une séance et
/// la lecture seule de la direction.
class JournalEntryDetails extends StatelessWidget {
  final JournalFields fields;
  final JournalChapterTag? chapter;

  const JournalEntryDetails({super.key, required this.fields, this.chapter});

  /// Les champs remplis, dans l'ordre du cahier.
  static List<JournalField> filledOf(JournalFields fields) => [
    for (final field in JournalField.values)
      if (field.valueOf(fields).trim().isNotEmpty) field,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    final valueStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in filledOf(fields))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: AppDimensions.journalCardLabelColumn,
                  child: Text(field.label(l10n), style: labelStyle),
                ),
                Expanded(child: Text(field.valueOf(fields), style: valueStyle)),
              ],
            ),
          ),
        if (chapter case final tag?) JournalChapterChip(tag: tag),
      ],
    );
  }
}
