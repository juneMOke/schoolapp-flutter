import 'package:equatable/equatable.dart';

/// Bilan d'un cycle de pull keyset de la Discipline (diagnostic). `notModified`
/// = cycle sans nouveauté (304 / delta vide) ; `bootstrapComplete` = un cycle a
/// atteint `hasMore=false` (l'année entière des cas est en base) → sert de repère
/// de fraîcheur (« Mon poste » vs « École », ADR-002).
class DisciplinaryPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int syncedAt;
  final String? cursor;

  /// Horloge **serveur** (epoch ms, `page.serverTime`) de la dernière page
  /// appliquée — `null` sur un cycle `notModified` (pas de corps à parser).
  final int? serverTimeMs;

  const DisciplinaryPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const DisciplinaryPullOutcome.notModifiedAt(
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
