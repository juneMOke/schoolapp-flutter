import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Un geste du circuit, posé sur cette tablette ou descendu du serveur.
class PayrollGesture extends Equatable {
  final String id;

  /// `YYYY-MM`.
  final String month;
  final PayrollGestureKind kind;
  final String? reason;
  final String recordedAt;
  final String? authorName;

  /// Ce qui a été vu en confirmant (`SUBMIT`, `VALIDATE`).
  final PayrollFingerprint? expected;

  /// Les chiffres du serveur, rendus par un refus `PAYROLL_STALE`.
  final PayrollFingerprint? serverState;
  final RecordSyncState syncState;
  final String? syncError;
  final String? syncErrorCode;

  const PayrollGesture({
    required this.id,
    required this.month,
    required this.kind,
    required this.recordedAt,
    required this.syncState,
    this.reason,
    this.authorName,
    this.expected,
    this.serverState,
    this.syncError,
    this.syncErrorCode,
  });

  static const String staleCode = 'PAYROLL_STALE';

  bool get isInFlight => syncState == RecordSyncState.pending;

  bool get isRefused => syncState == RecordSyncState.failed;

  bool get isStale => isRefused && syncErrorCode == staleCode;

  @override
  List<Object?> get props => [
    id,
    month,
    kind,
    reason,
    recordedAt,
    authorName,
    expected,
    serverState,
    syncState,
    syncError,
    syncErrorCode,
  ];
}
