import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Ligne sqflite `evaluation` — **régime A** (insert-only, uuid client honoré).
///
/// Le FAIT « évaluation » est immuable après création (le serveur applique
/// `ON CONFLICT (id) DO NOTHING`). `evalDate` en epoch ms ; `maxPoints` REAL ;
/// `poids` > 0. Un seul rattachement temporel est renseigné selon le `type` :
/// `sousPeriodeId` (INTERRO/DEVOIR) ou `periodeScolaireId` (EXAMEN).
class EvaluationRow extends Equatable {
  final String id;
  final String coursId;
  final String type;

  /// epoch ms.
  final int evalDate;
  final double maxPoints;
  final int poids;
  final String? sousPeriodeId;
  final String? periodeScolaireId;

  /// Horloge client (epoch ms). Pour le régime A, sert la traçabilité et la
  /// garde de réalignement post-ACK (pas d'arbitrage LWW — le fait est immuable).
  final int updatedAt;

  /// Temps de visibilité serveur (epoch ms). Nul tant que non synchronisé ;
  /// posé au pull / à l'ACK. Non-curseur (le curseur vit dans `sync_meta`).
  final int? serverUpdatedAt;
  final String syncStatus;
  final int? syncedAt;

  const EvaluationRow({
    required this.id,
    required this.coursId,
    required this.type,
    required this.evalDate,
    required this.maxPoints,
    required this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
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

  factory EvaluationRow.fromMap(Map<String, Object?> map) => EvaluationRow(
    id: map['id'] as String,
    coursId: map['cours_id'] as String,
    type: map['type'] as String,
    evalDate: _asIntOrNull(map['eval_date']) ?? 0,
    maxPoints: _asDoubleOrNull(map['max_points']) ?? 0,
    poids: _asIntOrNull(map['poids']) ?? 0,
    sousPeriodeId: map['sous_periode_id'] as String?,
    periodeScolaireId: map['periode_scolaire_id'] as String?,
    updatedAt: _asIntOrNull(map['updated_at']) ?? 0,
    serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
    syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
    syncedAt: _asIntOrNull(map['synced_at']),
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'cours_id': coursId,
    'type': type,
    'eval_date': evalDate,
    'max_points': maxPoints,
    'poids': poids,
    'sous_periode_id': sousPeriodeId,
    'periode_scolaire_id': periodeScolaireId,
    'updated_at': updatedAt,
    'server_updated_at': serverUpdatedAt,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
  };

  SyncState get syncState => SyncState.fromDbValue(syncStatus);

  @override
  List<Object?> get props => [
    id,
    coursId,
    type,
    evalDate,
    maxPoints,
    poids,
    sousPeriodeId,
    periodeScolaireId,
    updatedAt,
    serverUpdatedAt,
    syncStatus,
    syncedAt,
  ];
}
