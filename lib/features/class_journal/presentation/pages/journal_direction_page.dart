import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teacher_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/direction/journal_teacher_picker.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_entry_read_dialog.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_view.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_year_gate.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/states/journal_states.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les journaux lus par la direction, **en ligne** : le choix du professeur,
/// puis sa journée, jour par jour. Une séance s'ouvre en lecture seule.
class JournalDirectionPage extends StatelessWidget {
  const JournalDirectionPage({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    scrollable: true,
    child: BlocBuilder<JournalTeachersCubit, JournalTeachersState>(
      buildWhen: (prev, curr) =>
          prev.failure != curr.failure || prev.selectedId != curr.selectedId,
      builder: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          return JournalFailureView(
            failure: failure,
            onRetry: context.read<JournalTeachersCubit>().load,
          );
        }
        final teacherId = state.selectedId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const JournalTeacherPicker(),
            const SizedBox(height: AppSpacing.lg),
            if (teacherId == null)
              const _PickTeacher()
            else
              BlocProvider<JournalDayCubit>(
                key: ValueKey(teacherId),
                create: (_) =>
                    GetIt.instance<JournalTeacherDayCubit>(param1: teacherId),
                child: const _TeacherJournal(),
              ),
          ],
        );
      },
    ),
  );
}

class _TeacherJournal extends StatelessWidget {
  const _TeacherJournal();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JournalDayCubit>();
    return JournalYearGate(
      onReady: cubit.start,
      child: JournalView(
        onOpen: (line) =>
            showJournalEntryReadDialog(context, line, cubit.state.date),
      ),
    );
  }
}

class _PickTeacher extends StatelessWidget {
  const _PickTeacher();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.journalPickTeacherTitle,
      description: l10n.journalPickTeacherMessage,
      medallionIcon: Icons.person_search_rounded,
      fullWidthCard: true,
    );
  }
}
