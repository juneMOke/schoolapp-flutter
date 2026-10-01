import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// L'annulation d'un fait de paie (avance, versement) : un geste avec motif,
/// jamais une suppression. Partagée par les deux faits qui s'annulent.
class PayrollCancellation extends Equatable {
  final String id;
  final String reason;

  /// Quand le serveur l'a enregistrée ; `null` tant qu'elle n'est pas accusée.
  final String? cancelledAt;
  final RecordSyncState syncState;
  final String? syncError;

  const PayrollCancellation({
    required this.id,
    required this.reason,
    required this.syncState,
    this.cancelledAt,
    this.syncError,
  });

  /// Refusée : le fait reste vivant.
  bool get isRefused => syncState == RecordSyncState.failed;

  @override
  List<Object?> get props => [id, reason, cancelledAt, syncState, syncError];
}
