import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// La clôture d'un mois pour une classe, telle que la tablette la connaît.
class ClassPresenceClosure extends Equatable {
  /// ISO-8601 ; l'heure de la saisie, puis celle du serveur.
  final String? closedAt;

  /// Le nom donné par le serveur ; `null` tant qu'il ne l'a pas dit.
  final String? closedBy;
  final SyncState sync;

  /// La raison d'un refus définitif ; `null` sinon.
  final String? refusal;

  const ClassPresenceClosure({
    this.closedAt,
    this.closedBy,
    this.sync = SyncState.synced,
    this.refusal,
  });

  /// Une clôture refusée ne fige rien.
  bool get closes => !sync.isError;

  RecordSyncState get recordSync => switch (sync) {
    SyncState.synced => RecordSyncState.synced,
    SyncState.syncError => RecordSyncState.failed,
    _ => RecordSyncState.pending,
  };

  @override
  List<Object?> get props => [closedAt, closedBy, sync, refusal];
}
