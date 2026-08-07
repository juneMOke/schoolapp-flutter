import 'dart:convert';

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

  /// Couverture de chapitres (intra-agrégat, régime A donc immuable après
  /// création), sérialisée en JSON (`chapitre_ids_json`, défaut `'[]'`).
  final String chapitreIdsJson;

  /// Code du backstop `422` terminal (`PERIOD_CLOSED`/`EXAM_NOT_ALLOWED`/
  /// `MAX_REACHED`) ayant rejeté la création — `null` tant qu'aucun rejet.
  final String? rejectionCode;

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
    this.chapitreIdsJson = '[]',
    this.rejectionCode,
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

  /// Encode une liste d'ids de chapitres en JSON (pour [chapitreIdsJson]).
  static String encodeChapitreIds(List<String> ids) => jsonEncode(ids);

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
    chapitreIdsJson: (map['chapitre_ids_json'] as String?) ?? '[]',
    rejectionCode: map['rejection_code'] as String?,
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
    'chapitre_ids_json': chapitreIdsJson,
    'rejection_code': rejectionCode,
  };

  SyncState get syncState => SyncState.fromDbValue(syncStatus);

  /// Ids de chapitres couverts, décodés tolérant : JSON illisible ou entrées
  /// non-string → liste vide (jamais de crash sur une ligne mal formée).
  List<String> get chapitreIds {
    try {
      final decoded = jsonDecode(chapitreIdsJson);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

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
    chapitreIdsJson,
    rejectionCode,
  ];
}
