import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_page_title.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_view.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_year_gate.dart';

/// « Cours ▸ Mon journal » côté professeur : son journal, lu sur la tablette,
/// ouvert sur aujourd'hui une fois l'année scolaire connue.
class JournalPage extends StatelessWidget {
  /// Ouvre la saisie d'une séance ; `null` : lecture seule.
  final ValueChanged<JournalLine>? onOpen;

  const JournalPage({super.key, this.onOpen});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    scrollable: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JournalPageTitle(),
        JournalYearGate(
          onReady: context.read<JournalDayCubit>().start,
          child: JournalView(onOpen: onOpen, editable: onOpen != null),
        ),
      ],
    ),
  );
}
