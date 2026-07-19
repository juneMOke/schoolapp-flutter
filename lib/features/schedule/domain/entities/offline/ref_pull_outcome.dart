import 'package:equatable/equatable.dart';

/// Bilan d'un cycle de pull d'une ressource de référence (emploi du temps).
///
/// [notModified] : rien de neuf (304 ou cycle vide) — le curseur est conservé.
/// [bootstrapComplete] : le premier passage complet (jusqu'à `hasMore = false`)
/// a eu lieu — la ressource locale est réputée exhaustive (ADR-002, fraîcheur).
class RefPullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int syncedAt;
  final String? cursor;

  const RefPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    required this.syncedAt,
    required this.cursor,
  });

  factory RefPullOutcome.notModifiedAt(
    int syncedAt,
    String? cursor, {
    required bool bootstrapComplete,
  }) => RefPullOutcome(
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
  ];
}
