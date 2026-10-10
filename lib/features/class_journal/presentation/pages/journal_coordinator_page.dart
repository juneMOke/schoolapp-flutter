import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_direction_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_entry_launcher.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';

/// Le journal de classe selon qui regarde :
/// - la direction (`teacher.read`) : le journal d'un professeur, lu en ligne,
///   en lecture seule. Elle détient aussi `academics.programme.write`
///   (gabarit `FULL_SCHOOL_ACCESS`) : c'est `teacher.read`, absent du gabarit
///   `TEACHER`, qui la distingue ;
/// - le professeur (`academics.programme.write`) : son journal, sur la
///   tablette, ses séances s'ouvrent en saisie ;
/// - sinon : son journal en lecture seule.
class JournalCoordinatorPage extends StatelessWidget {
  const JournalCoordinatorPage({super.key});

  @override
  Widget build(BuildContext context) => PermissionHoldingBuilder(
    requires: const [Perm.teacherRead],
    builder: (context, read) {
      if (read == PermissionHolding.granted) {
        return BlocProvider<JournalTeachersCubit>(
          create: (_) => GetIt.instance<JournalTeachersCubit>()..load(),
          child: const JournalDirectionPage(),
        );
      }
      return PermissionHoldingBuilder(
        requires: ProgrammeWriteGate.requires,
        builder: (context, write) =>
            _OwnJournal(editable: write == PermissionHolding.granted),
      );
    },
  );
}

class _OwnJournal extends StatelessWidget {
  final bool editable;

  const _OwnJournal({required this.editable});

  @override
  Widget build(BuildContext context) => BlocProvider<JournalDayCubit>(
    create: (_) => GetIt.instance<JournalDayCubit>(),
    child: Builder(
      builder: (context) => JournalPage(
        onOpen: editable ? (line) => openJournalEntry(context, line) : null,
      ),
    ),
  );
}
