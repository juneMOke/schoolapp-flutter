import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';

/// Une période de désactivation d'un élève inscrit.
///
/// Ouverte tant que [reactivatedAt] est nul. Le dossier d'inscription reste
/// `COMPLETED` : la désactivation est une suspension, jamais une radiation.
class StudentSuspension extends Equatable {
  /// Longueur maximale de [precision], bornée aussi par le serveur.
  static const int precisionMaxLength = 140;

  final String id;
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final DateTime suspendedAt;
  final String? suspendedBy;
  final SuspensionReason? reason;
  final String? precision;
  final DateTime? reactivatedAt;

  /// Ce que le dernier geste local est devenu.
  final RecordSyncState syncState;

  /// Raison d'un refus du serveur, si [syncState] est en échec.
  final String? syncError;

  const StudentSuspension({
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.suspendedAt,
    this.suspendedBy,
    this.reason,
    this.precision,
    this.reactivatedAt,
    this.syncState = RecordSyncState.synced,
    this.syncError,
  });

  bool get isOpen => reactivatedAt == null;

  @override
  List<Object?> get props => [
    id,
    enrollmentId,
    studentId,
    academicYearId,
    suspendedAt,
    suspendedBy,
    reason,
    precision,
    reactivatedAt,
    syncState,
    syncError,
  ];
}
