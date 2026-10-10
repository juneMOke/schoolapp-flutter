import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête de colonnes de la feuille : fond bleu pâle, encre bleu ardoise,
/// filet bas appuyé. « C.B » porte « Compétence de base » en infobulle.
class JournalSheetHeader extends StatelessWidget {
  const JournalSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.journalHead,
        border: Border(
          bottom: BorderSide(
            color: AppColors.journalLine,
            width: AppDimensions.journalHeadStroke,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: AppDimensions.journalHourColumn,
              child: _HeadCell(label: l10n.journalColumnHour, first: true),
            ),
            SizedBox(
              width: AppDimensions.journalBranchColumn,
              child: _HeadCell(label: l10n.journalColumnBranch),
            ),
            for (final field in JournalField.values)
              Expanded(
                flex: field.flex,
                child: _HeadCell(
                  label: field.label(l10n),
                  subLabel: field == JournalField.contenu
                      ? l10n.journalColumnContenuSub
                      : null,
                  tooltip: field == JournalField.cb
                      ? l10n.journalColumnCbTooltip
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String label;
  final String? subLabel;
  final String? tooltip;
  final bool first;

  const _HeadCell({
    required this.label,
    this.subLabel,
    this.tooltip,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.bleuArdoise,
      fontWeight: FontWeight.w700,
    );
    final cell = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(left: BorderSide(color: AppColors.journalLine)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textAlign: TextAlign.center, style: style),
          if (subLabel case final sub?)
            Text(
              sub,
              textAlign: TextAlign.center,
              style: style.copyWith(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
    return tooltip == null ? cell : Tooltip(message: tooltip, child: cell);
  }
}
