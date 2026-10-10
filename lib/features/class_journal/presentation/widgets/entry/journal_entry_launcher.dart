import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_display.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_entry_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la saisie de [line] au jour affiché par le [JournalDayCubit] de
/// l'arbre ; à l'enregistrement (ou au vidage), la modale se ferme, un toast
/// le dit et la page se relit.
Future<void> openJournalEntry(BuildContext context, JournalLine line) async {
  final dayCubit = context.read<JournalDayCubit>();
  final dayState = dayCubit.state;
  if (dayState is! JournalDayReady) return;
  final day = dayState.day;
  final cubit = GetIt.instance<JournalEntryCubit>()
    ..open(line, date: day.date, slotOrder: day.slotOrder);
  final outcome = await showDialog<JournalEntryStatus>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider<JournalEntryCubit>.value(
      value: cubit,
      child: BlocListener<JournalEntryCubit, JournalEntryState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (dialogContext, state) {
          if (state.status == JournalEntryStatus.saved ||
              state.status == JournalEntryStatus.cleared) {
            Navigator.of(dialogContext).pop(state.status);
          }
        },
        child: JournalEntryDialog(line: line, date: day.date),
      ),
    ),
  );
  await cubit.close();
  if (!context.mounted || outcome == null) return;
  final l10n = AppLocalizations.of(context)!;
  AppSnackBar.showSuccess(
    context,
    outcome == JournalEntryStatus.cleared
        ? l10n.journalCleared
        : journalSavedMessage(line, l10n),
  );
  await dayCubit.refresh();
}
