import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Ligne locale + payload wire d'un **événement de transfert** (régime A).
///
/// Triple rôle (patron `classroom_member_dto`) : ligne sqflite
/// (`fromMap`/`toMap` de `classroom_transfers`) et corps de requête POST
/// (`toRequestJson`). `id` = uuid client honoré (idempotence). `transferredAt`
/// est stocké en **epoch ms** (convention du schéma) et sérialisé en **ISO-8601**
/// sur le fil (heure métier, contrat openapi_classroom_sync 1.1.0).
class ClassroomTransferRow extends Equatable {
  final String id;
  final String studentId;
  final String fromClassroomId;
  final String toClassroomId;
  final String schoolLevelId;
  final String academicYearId;

  /// Heure MÉTIER du transfert (epoch ms). Borne des intervalles d'appartenance
  /// du dénominateur d'assiduité (ADR-004).
  final int transferredAt;
  final String? transferredBy;
  final String? reason;
  final String syncStatus;

  /// Visibilité serveur (epoch ms), posée à l'ACK/au pull. Informatif — le
  /// curseur de pagination reste opaque dans `sync_meta`.
  final int? serverUpdatedAt;
  final int? syncedAt;

  const ClassroomTransferRow({
    required this.id,
    required this.studentId,
    required this.fromClassroomId,
    required this.toClassroomId,
    required this.schoolLevelId,
    required this.academicYearId,
    required this.transferredAt,
    this.transferredBy,
    this.reason,
    this.syncStatus = 'PENDING_SYNC',
    this.serverUpdatedAt,
    this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory ClassroomTransferRow.fromMap(Map<String, Object?> map) =>
      ClassroomTransferRow(
        id: map['id'] as String,
        studentId: map['student_id'] as String,
        fromClassroomId: map['from_classroom_id'] as String,
        toClassroomId: map['to_classroom_id'] as String,
        schoolLevelId: map['school_level_id'] as String,
        academicYearId: map['academic_year_id'] as String,
        transferredAt: _asIntOrNull(map['transferred_at']) ?? 0,
        transferredBy: map['transferred_by'] as String?,
        reason: map['reason'] as String?,
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
        syncedAt: _asIntOrNull(map['synced_at']),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'student_id': studentId,
    'from_classroom_id': fromClassroomId,
    'to_classroom_id': toClassroomId,
    'school_level_id': schoolLevelId,
    'academic_year_id': academicYearId,
    'transferred_at': transferredAt,
    'transferred_by': transferredBy,
    'reason': reason,
    'sync_status': syncStatus,
    'server_updated_at': serverUpdatedAt,
    'synced_at': syncedAt,
  };

  /// Corps de la requête POST `/sync/classroom-transfers` (figé dans l'outbox).
  /// `transferredAt` en ISO-8601 UTC (heure métier ; le serveur la clampe).
  Map<String, dynamic> toRequestJson() => <String, dynamic>{
    'transfer': <String, dynamic>{
      'id': id,
      'studentId': studentId,
      'fromClassroomId': fromClassroomId,
      'toClassroomId': toClassroomId,
      'academicYearId': academicYearId,
      'transferredAt': DateTime.fromMillisecondsSinceEpoch(
        transferredAt,
        isUtc: true,
      ).toIso8601String(),
      if (transferredBy != null) 'transferredBy': transferredBy,
      if (reason != null) 'reason': reason,
    },
  };

  bool get isSynced => syncStatus == SyncState.synced.dbValue;

  @override
  List<Object?> get props => [
    id,
    studentId,
    fromClassroomId,
    toClassroomId,
    schoolLevelId,
    academicYearId,
    transferredAt,
    transferredBy,
    reason,
    syncStatus,
    serverUpdatedAt,
    syncedAt,
  ];
}
