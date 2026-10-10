import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix du professeur dont la direction lit le journal.
class JournalTeacherPicker extends StatelessWidget {
  const JournalTeacherPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<JournalTeachersCubit, JournalTeachersState>(
      buildWhen: (prev, curr) =>
          prev.loading != curr.loading ||
          prev.teachers != curr.teachers ||
          prev.selectedId != curr.selectedId,
      builder: (context, state) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.journalModalWidth,
        ),
        child: EteeloSelectInput<String>(
          label: l10n.journalTeacherLabel,
          placeholder: l10n.journalTeacherPlaceholder,
          value: state.selectedId,
          enabled: !state.loading,
          searchable: true,
          items: [
            for (final teacher in state.teachers)
              EteeloSelectItem(value: teacher.id, label: teacher.displayName),
          ],
          onChanged: context.read<JournalTeachersCubit>().select,
        ),
      ),
    );
  }
}
