import 'package:equatable/equatable.dart';

/// Bilan d'un cycle de pull des ventes.
///
/// `notModified` distingue « rien de neuf » (304, ou delta vide) d'un cycle qui
/// a réellement écrit : le coordinateur en a besoin pour ne pas annoncer une
/// mise à jour qui n'a rien changé.
class BoutiquePullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final int syncedAt;

  /// Jeton mémorisé à l'issue du cycle.
  final String? cursor;

  /// Horloge serveur de la dernière page, en millisecondes.
  final int? serverTimeMs;

  const BoutiquePullOutcome({
    required this.upserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const BoutiquePullOutcome.notModifiedAt(this.syncedAt, this.cursor)
    : upserted = 0,
      notModified = true,
      serverTimeMs = null;

  @override
  List<Object?> get props => [
    upserted,
    notModified,
    syncedAt,
    cursor,
    serverTimeMs,
  ];
}
