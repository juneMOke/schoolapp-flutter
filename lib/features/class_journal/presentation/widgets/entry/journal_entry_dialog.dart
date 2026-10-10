import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_chapter_block.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_entry_footer.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_fields_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La modale de saisie d'une séance : le bloc chapitre, les sept champs du
/// cahier, puis Vider / Annuler / Enregistrer. Le scrim ne ferme pas : une
/// saisie est du travail non enregistré. Sous le point de rupture, elle
/// occupe tout l'écran.
class JournalEntryDialog extends StatelessWidget {
  final JournalLine line;
  final DateTime date;

  const JournalEntryDialog({super.key, required this.line, required this.date});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = line.entry;
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
        child: BlocBuilder<JournalEntryCubit, JournalEntryState>(
          buildWhen: (prev, curr) =>
              (prev.status == JournalEntryStatus.loading) !=
                  (curr.status == JournalEntryStatus.loading) ||
              prev.failure != curr.failure,
          builder: (context, state) {
            if (state.status == JournalEntryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entry != null && entry.isRejected)
                  EteeloNotice.error(
                    l10n.journalRejectedNotice(entry.rejectionCode ?? ''),
                  ),
                if (state.failure != null)
                  EteeloNotice.error(l10n.journalSaveFailed),
                const JournalChapterBlock(),
                const SizedBox(height: AppSpacing.lg),
                const JournalFieldsGrid(),
              ],
            );
          },
        ),
      ),
      footer: [JournalEntryFooter(canClear: entry != null && !entry.isBlank)],
    );
    if (MediaQuery.sizeOf(context).width < AppDimensions.journalBreakpoint) {
      return Dialog.fullscreen(child: body);
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.journalModalWidth,
        ),
        child: body,
      ),
    );
  }
}
