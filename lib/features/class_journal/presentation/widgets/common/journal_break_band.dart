import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La bande « 10:00 – 10:20 · Récréation » entre deux séances.
class JournalBreakBand extends StatelessWidget {
  final JournalBreak pause;

  const JournalBreakBand({super.key, required this.pause});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: AppColors.journalBreakStripe,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        l10n.journalBreak(journalHhmm(pause.start), journalHhmm(pause.end)),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
