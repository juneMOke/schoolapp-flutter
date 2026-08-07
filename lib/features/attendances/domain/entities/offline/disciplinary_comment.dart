import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Commentaire d'un cas disciplinaire (DF-B). **Append-only** : créé, jamais
/// modifié ni supprimé (régime A, uuid client honoré). `content` SENSIBLE
/// (mineur, base chiffrée SQLCipher) — chargé au détail seulement.
/// `createdAt` = epoch ms (heure métier, clampée).
class DisciplinaryComment extends Equatable {
  final String id;
  final String disciplinaryCaseId;
  final String content;
  final String? authorName;
  final int createdAt;
  final SyncState syncState;
  final int? syncedAt;

  const DisciplinaryComment({
    required this.id,
    required this.disciplinaryCaseId,
    required this.content,
    this.authorName,
    required this.createdAt,
    this.syncState = SyncState.pendingSync,
    this.syncedAt,
  });

  // `content` SENSIBLE (mineur) : jamais rendu par toString() (fuite debug).
  @override
  bool? get stringify => false;

  @override
  List<Object?> get props => [
    id,
    disciplinaryCaseId,
    content,
    authorName,
    createdAt,
    syncState,
    syncedAt,
  ];
}
