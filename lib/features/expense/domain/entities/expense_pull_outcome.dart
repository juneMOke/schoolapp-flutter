import 'package:equatable/equatable.dart';

/// Bilan d'un cycle de pull du registre.
///
/// `notModified` distingue « rien de neuf » (304, ou delta vide) d'un cycle
/// qui a réellement écrit : le coordinateur ne doit pas annoncer une mise à
/// jour qui n'a rien changé.
class ExpensePullOutcome extends Equatable {
  final int upserted;
  final bool notModified;
  final int syncedAt;
  final String? cursor;

  /// Horloge serveur de la dernière page, en millisecondes.
  final int? serverTimeMs;

  const ExpensePullOutcome({
    required this.upserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const ExpensePullOutcome.notModifiedAt(this.syncedAt, this.cursor)
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
