import 'package:equatable/equatable.dart';

/// Bilan d'un cycle de pull keyset des transferts (F5). `notModified` = cycle
/// sans nouveauté (304 / delta vide) ; `bootstrapComplete` = un cycle a atteint
/// `hasMore=false` (tout l'historique de l'année est en base) → **prérequis du
/// dénominateur d'assiduité par intervalles** (F6 : un historique partiel donne
/// un taux faux mais plausible, donc indétectable).
class ClassroomTransferPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int syncedAt;
  final String? cursor;

  /// Horloge **serveur** (epoch ms, `page.serverTime`) de la dernière page
  /// appliquée — `null` sur un cycle `notModified` (pas de corps à parser).
  final int? serverTimeMs;

  const ClassroomTransferPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const ClassroomTransferPullOutcome.notModifiedAt(
    int syncedAt,
    String? cursor, {
    bool bootstrapComplete = false,
  }) : this(
         upserted: 0,
         notModified: true,
         bootstrapComplete: bootstrapComplete,
         syncedAt: syncedAt,
         cursor: cursor,
       );

  @override
  List<Object?> get props => [
    upserted,
    notModified,
    bootstrapComplete,
    syncedAt,
    cursor,
    serverTimeMs,
  ];
}
