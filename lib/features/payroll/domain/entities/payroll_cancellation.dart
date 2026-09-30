import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// L'annulation d'un fait de paie (avance, versement) : un geste avec motif,
/// jamais une suppression. Partagée par les deux faits qui s'annulent.
class PayrollCancellation extends Equatable {
  final String id;
  final String reason;

  /// Quand le serveur l'a enregistrée ; `null` tant qu'elle n'est pas accusée.
  final String? cancelledAt;
  final StaffSyncState syncState;
  final String? syncError;

  const PayrollCancellation({
    required this.id,
    required this.reason,
    required this.syncState,
    this.cancelledAt,
    this.syncError,
  });

  /// Refusée : le fait reste vivant.
  bool get isRefused => syncState == StaffSyncState.failed;

  @override
  List<Object?> get props => [id, reason, cancelledAt, syncState, syncError];
}
