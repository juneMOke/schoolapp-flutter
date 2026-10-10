import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_entry_launcher.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';

/// Le journal du professeur : ses séances s'ouvrent en saisie avec
/// `academics.programme.write` (le droit qui écrit le programme) ; sans lui,
/// la page se lit seulement.
class JournalCoordinatorPage extends StatelessWidget {
  const JournalCoordinatorPage({super.key});

  @override
  Widget build(BuildContext context) => PermissionHoldingBuilder(
    requires: ProgrammeWriteGate.requires,
    builder: (context, holding) => JournalPage(
      onOpen: holding == PermissionHolding.granted
          ? (line) => openJournalEntry(context, line)
          : null,
    ),
  );
}
