import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';

/// Ligne `evaluation_copie_log` — une diffusion de copie, **insert seul**.
///
/// L'id vient de la tablette ; le serveur ignore un rejeu. Les lignes des
/// autres tablettes descendent avec le delta d'évaluation, déjà `SYNCED`.
class CopieLogRow extends Equatable {
  final String id;
  final String evaluationId;
  final String kind;
  final String? canal;
  final bool corrige;

  /// epoch ms.
  final int occurredAt;
  final String? authorUserId;
  final String syncStatus;

  const CopieLogRow({
    required this.id,
    required this.evaluationId,
    required this.kind,
    this.canal,
    required this.corrige,
    required this.occurredAt,
    this.authorUserId,
    this.syncStatus = 'PENDING_SYNC',
  });

  factory CopieLogRow.fromMap(Map<String, Object?> map) => CopieLogRow(
    id: map['id'] as String,
    evaluationId: map['evaluation_id'] as String,
    kind: map['kind'] as String,
    canal: map['canal'] as String?,
    corrige: (map['corrige'] as num?) == 1,
    occurredAt: (map['occurred_at'] as num?)?.toInt() ?? 0,
    authorUserId: map['author_user_id'] as String?,
    syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'evaluation_id': evaluationId,
    'kind': kind,
    'canal': canal,
    'corrige': corrige ? 1 : 0,
    'occurred_at': occurredAt,
    'author_user_id': authorUserId,
    'sync_status': syncStatus,
  };

  SyncState get syncState => SyncState.fromDbValue(syncStatus);

  /// `null` si [kind] est illisible : la ligne est ignorée à l'affichage.
  CopieDiffusion? toEntity() {
    final parsedKind = CopieKind.fromApiValue(kind);
    if (parsedKind == null) return null;
    return CopieDiffusion(
      id: id,
      kind: parsedKind,
      canal: CopieCanal.fromApiValue(canal),
      corrige: corrige,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(occurredAt, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [
    id,
    evaluationId,
    kind,
    canal,
    corrige,
    occurredAt,
    authorUserId,
    syncStatus,
  ];
}
