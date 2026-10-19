import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/selection/selectable_list_card.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Grand écran : les professeurs en colonne, à la place de la liste
/// déroulante — la direction passe d'un journal au suivant d'un clic.
class JournalTeacherList extends StatelessWidget {
  const JournalTeacherList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<JournalTeachersCubit, JournalTeachersState>(
      buildWhen: (prev, curr) =>
          prev.teachers != curr.teachers || prev.selectedId != curr.selectedId,
      builder: (context, state) => SelectableListCard(
        title: l10n.journalTeachersTitle,
        filterLabel: l10n.journalTeacherFilter,
        selectedId: state.selectedId,
        items: [
          for (final teacher in state.teachers)
            SelectableListItem(id: teacher.id, label: teacher.displayName),
        ],
        onSelected: context.read<JournalTeachersCubit>().select,
      ),
    );
  }
}
