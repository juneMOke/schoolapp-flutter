import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Quelle part du net l'école verse ce mois-ci (« ce mois, nous versons 60 %
/// à tout le personnel »). Le net dû ne change pas : la différence devient un
/// arriéré à la validation. Réglée en brouillon, dernier écrit gagne.
class PayrollPayoutPolicy extends Equatable {
  /// `YYYY-MM`.
  final String month;

  /// De 0 à 100.
  final int ratePercent;

  /// Requis sous 100 % ; lu par la direction et le registre des arriérés.
  final String? reason;
  final RecordSyncState syncState;
  final String? syncError;

  const PayrollPayoutPolicy({
    required this.month,
    required this.ratePercent,
    this.reason,
    this.syncState = RecordSyncState.synced,
    this.syncError,
  });

  static const int full = 100;

  bool get isReduced => ratePercent < full;

  @override
  List<Object?> get props => [month, ratePercent, reason, syncState, syncError];
}
