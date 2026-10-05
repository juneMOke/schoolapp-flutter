import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// Où en est l'envoi d'un élément du programme — rien quand le serveur l'a :
/// « Sur la tablette » tant qu'il attend, « Échec d'envoi » s'il est refusé.
class ProgrammeSyncPill extends StatelessWidget {
  final ProgrammeSyncState state;

  const ProgrammeSyncPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) => switch (state) {
    ProgrammeSyncState.synced => const SizedBox.shrink(),
    ProgrammeSyncState.pending => const RecordSyncPill(
      state: RecordSyncState.pending,
    ),
    ProgrammeSyncState.rejected => const RecordSyncPill(
      state: RecordSyncState.failed,
    ),
  };
}
