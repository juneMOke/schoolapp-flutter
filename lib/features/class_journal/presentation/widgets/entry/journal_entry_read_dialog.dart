import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_entry_details.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/common/journal_status_pill.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_dialog_frame.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre une séance en lecture seule — la direction lit, n'écrit jamais.
Future<void> showJournalEntryReadDialog(
  BuildContext context,
  JournalLine line,
  DateTime date,
) => showDialog<void>(
  context: context,
  builder: (_) => JournalEntryReadDialog(line: line, date: date),
);

/// La séance telle que le professeur l'a écrite : statut, champs remplis,
/// étiquette chapitre ; ni Enregistrer ni Vider.
class JournalEntryReadDialog extends StatelessWidget {
  final JournalLine line;
  final DateTime date;

  const JournalEntryReadDialog({
    super.key,
    required this.line,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = line.entry?.fields ?? JournalFields.empty;
    final empty = JournalEntryDetails.filledOf(fields).isEmpty;
    final body = EteeloDialogBody(
      header: EteeloDialogDarkHeader(
        eyebrow: l10n.journalEntryEyebrow(
          journalRankLabel(line, l10n),
          journalSlotRange(line, l10n),
          date,
        ),
        title: l10n.journalEntryTitle(line.subjectLabel, line.classroomLabel),
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JournalStatusPill(status: line.status),
            const SizedBox(height: AppSpacing.md),
            if (empty)
              Text(
                l10n.journalEntryNotFilled,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              JournalEntryDetails(fields: fields, chapter: line.chapter),
          ],
        ),
      ),
      footer: [
        Align(
          alignment: Alignment.centerRight,
          child: EteeloButton.secondary(
            label: l10n.journalClose,
            onPressed: () => Navigator.of(context).pop(),
            fullWidth: false,
          ),
        ),
      ],
    );
    return JournalDialogFrame(child: body);
  }
}
