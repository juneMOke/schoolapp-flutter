import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Ligne sqflite `note_evaluation` — **régime C** (upsert clé naturelle
/// `(evaluation_id, student_id)` + last-write-wins arbitré par `updatedAt`).
///
/// `pointsObtenus` REAL (NULL si absent ; note exacte, jamais de la monnaie) ;
/// `statut` ∈ NOTEE | ABSENT_JUSTIFIE | ABSENT_NON_JUSTIFIE | EN_ATTENTE. `id`
/// = uuid de transport (la résolution d'upsert passe par la clé naturelle, pas
/// par cet id).
class NoteEvaluationRow extends Equatable {
  final String id;
  final String evaluationId;
  final String studentId;
  final double? pointsObtenus;
  final String statut;

  /// Horloge client (epoch ms) — **arbitre du last-write-wins**.
  final int updatedAt;

  /// Temps de visibilité serveur (epoch ms). Nul tant que non synchronisé.
  final int? serverUpdatedAt;
  final String syncStatus;
  final int? syncedAt;

  /// Motif du rejet serveur (`UNKNOWN_EVALUATION`/`PERIODE_CLOSE`/`INVALID: …`/
  /// `EVALUATION_CONTEXT_UNAVAILABLE`) — `null` tant qu'aucun rejet, posé
  /// seulement sur un outcome `REJECTED`, surfacé à l'UI.
  final String? rejectionReason;

  const NoteEvaluationRow({
    required this.id,
    required this.evaluationId,
    required this.studentId,
    this.pointsObtenus,
    required this.statut,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
    this.rejectionReason,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asDoubleOrNull(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory NoteEvaluationRow.fromMap(Map<String, Object?> map) =>
      NoteEvaluationRow(
        id: map['id'] as String,
        evaluationId: map['evaluation_id'] as String,
        studentId: map['student_id'] as String,
        pointsObtenus: _asDoubleOrNull(map['points_obtenus']),
        statut: map['statut'] as String,
        updatedAt: _asIntOrNull(map['updated_at']) ?? 0,
        serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncedAt: _asIntOrNull(map['synced_at']),
        rejectionReason: map['rejection_reason'] as String?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'evaluation_id': evaluationId,
    'student_id': studentId,
    'points_obtenus': pointsObtenus,
    'statut': statut,
    'updated_at': updatedAt,
    'server_updated_at': serverUpdatedAt,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
    'rejection_reason': rejectionReason,
  };

  SyncState get syncState => SyncState.fromDbValue(syncStatus);

  @override
  List<Object?> get props => [
    id,
    evaluationId,
    studentId,
    pointsObtenus,
    statut,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    syncedAt,
    rejectionReason,
  ];
}
