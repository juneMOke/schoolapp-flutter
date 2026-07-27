import 'package:equatable/equatable.dart';

/// Bilan d'un cycle de pull keyset des classes (CF2). `notModified` = cycle
/// sans nouveauté (304 / delta vide).
class ClassroomPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final int syncedAt;
  final String? cursor;

  /// Horloge **serveur** (epoch ms, `page.serverTime`) de la dernière page
  /// appliquée — `null` sur un cycle `notModified` (pas de corps à parser).
  final int? serverTimeMs;

  const ClassroomPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const ClassroomPullOutcome.notModifiedAt(int syncedAt, String? cursor)
    : this(upserted: 0, notModified: true, syncedAt: syncedAt, cursor: cursor);

  @override
  List<Object?> get props => [
    upserted,
    notModified,
    syncedAt,
    cursor,
    serverTimeMs,
  ];
}
