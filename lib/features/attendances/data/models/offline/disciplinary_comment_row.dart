import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';

/// Ligne sqflite `disciplinary_case_comments` (DF-B). `content` SENSIBLE (base
/// chiffrée). Append-only : jamais mis à jour ni supprimé après insertion.
class DisciplinaryCommentRow extends Equatable {
  final String id;
  final String disciplinaryCaseId;
  final String content;
  final String? authorName;
  final int createdAt;
  final String syncStatus;
  final int? syncedAt;

  const DisciplinaryCommentRow({
    required this.id,
    required this.disciplinaryCaseId,
    required this.content,
    this.authorName,
    required this.createdAt,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory DisciplinaryCommentRow.fromMap(Map<String, Object?> map) =>
      DisciplinaryCommentRow(
        id: map['id'] as String,
        disciplinaryCaseId: map['disciplinary_case_id'] as String,
        content: map['content'] as String,
        authorName: map['author_name'] as String?,
        createdAt: _asIntOrNull(map['created_at']) ?? 0,
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncedAt: _asIntOrNull(map['synced_at']),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'disciplinary_case_id': disciplinaryCaseId,
    'content': content,
    'author_name': authorName,
    'created_at': createdAt,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
  };

  // `content` SENSIBLE (mineur) : jamais rendu par toString() (fuite debug).
  @override
  bool? get stringify => false;

  DisciplinaryComment toEntity() => DisciplinaryComment(
    id: id,
    disciplinaryCaseId: disciplinaryCaseId,
    content: content,
    authorName: authorName,
    createdAt: createdAt,
    syncState: SyncState.fromDbValue(syncStatus),
    syncedAt: syncedAt,
  );

  @override
  List<Object?> get props => [
    id,
    disciplinaryCaseId,
    content,
    authorName,
    createdAt,
    syncStatus,
    syncedAt,
  ];
}
