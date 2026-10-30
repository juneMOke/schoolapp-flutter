import 'package:sqflite_common/sqlite_api.dart';

/// Ce que le ticket d'annulation lit d'un versement annulé (continuité des
/// tickets RC, lot B).
///
/// Tout est déjà là : l'accusé de la correction écrit l'instant et le motif
/// (`PaymentCorrectionSyncDao.applyAck`), le pull le confirme et nomme
/// l'auteur.
class CancellationTicketDao {
  final DatabaseExecutor _db;

  const CancellationTicketDao(this._db);

  /// `null` quand le versement n'existe pas en local.
  Future<CancellationRow?> find(String paymentId) async {
    final rows = await _db.query(
      'payments',
      columns: const [
        'cancelled_at',
        'cancelled_by_name',
        'cancellation_reason_code',
        'cancellation_reason',
        'cancellation_cash_moved',
      ],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CancellationRow(
      cancelledAt: r['cancelled_at'] as int?,
      cancelledByName: r['cancelled_by_name'] as String?,
      reasonCode: r['cancellation_reason_code'] as String?,
      reason: r['cancellation_reason'] as String?,
      cashMoved: (r['cancellation_cash_moved'] as int? ?? 0) != 0,
    );
  }
}

class CancellationRow {
  /// Epoch ms de l'annulation, `null` tant qu'elle n'est pas acquittée.
  final int? cancelledAt;
  final String? cancelledByName;
  final String? reasonCode;

  /// La précision libre saisie avec le motif.
  final String? reason;
  final bool cashMoved;

  const CancellationRow({
    this.cancelledAt,
    this.cancelledByName,
    this.reasonCode,
    this.reason,
    this.cashMoved = false,
  });
}
