import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/documents/data/local/ticket_print_job_writer.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

/// Lecture et suivi de `ticket_print_jobs` (continuité des tickets RC, lot D).
///
/// Les lignes naissent dans les DAO d'encaissement et de correction, par
/// [TicketPrintJobWriter] ; ce DAO dit lesquelles attendent encore un papier,
/// et note ce qu'il en advient.
class TicketPrintQueueDao {
  final DatabaseExecutor _db;

  const TicketPrintQueueDao(this._db);

  static const _live = [
    PaymentCorrectionStatus.pending,
    PaymentCorrectionStatus.applied,
    PaymentCorrectionStatus.localOnly,
  ];

  /// Les tickets pas encore sortis, avec ce qui décide de leur sort.
  ///
  /// Un ticket de caisse disparaît de la file dès qu'un papier de ce versement
  /// est sorti par un autre chemin (`payments.ticket_printed_at`, posé par
  /// l'impression depuis l'écran de succès ou le détail).
  ///
  /// Le versement manque (refusé puis effacé, R3) : la jointure interne écarte
  /// la ligne — il n'y a plus rien à imprimer.
  Future<List<TicketPrintJobRow>> pendingRows() async {
    final live = _live.map((s) => "'${s.dbValue}'").join(', ');
    final rows = await _db.rawQuery('''
      SELECT j.id, j.payment_id, j.kind, j.created_at, j.last_problem,
             p.paid_at, p.cancelled_at,
             c.status AS correction_status,
             EXISTS (
               SELECT 1 FROM payment_corrections lc
                WHERE lc.payment_id = j.payment_id
                  AND lc.status IN ($live)
             ) AS has_live_correction
        FROM ${TicketPrintJobWriter.table} j
        JOIN payments p ON p.id = j.payment_id
        LEFT JOIN payment_corrections c ON c.id = j.correction_id
       WHERE j.printed_at IS NULL
         AND NOT (j.kind = '${TicketPrintJobWriter.receipt}'
                  AND p.ticket_printed_at IS NOT NULL)
       ORDER BY j.created_at, j.id
    ''');
    return [for (final r in rows) TicketPrintJobRow.fromMap(r)];
  }

  /// Le papier est sorti : la ligne le garde comme preuve, et le versement le
  /// porte comme tout ticket imprimé — le détail affiche ainsi « imprimé le… ».
  Future<void> markPrinted({
    required String jobId,
    required String paymentId,
    required bool isReceipt,
    required int nowMs,
  }) async {
    await _db.update(
      TicketPrintJobWriter.table,
      {'printed_at': nowMs, 'last_problem': null},
      where: 'id = ?',
      whereArgs: [jobId],
    );
    if (isReceipt) {
      await _db.update(
        'payments',
        {'ticket_printed_at': nowMs},
        where: 'id = ?',
        whereArgs: [paymentId],
      );
    }
  }

  /// Le ticket d'annulation de [paymentId] est sorti hors de la file — depuis
  /// la fin du geste d'annulation, ou sa réimpression.
  Future<void> markCancellationPrinted(String paymentId, int nowMs) =>
      _db.update(
        TicketPrintJobWriter.table,
        {'printed_at': nowMs, 'last_problem': null},
        where: 'payment_id = ? AND kind = ? AND printed_at IS NULL',
        whereArgs: [paymentId, TicketPrintJobWriter.cancellation],
      );

  Future<void> recordProblem(String jobId, String problem) => _db.update(
    TicketPrintJobWriter.table,
    {'last_problem': problem},
    where: 'id = ?',
    whereArgs: [jobId],
  );
}

/// Une ligne de la file, avec l'état du versement et de sa correction.
class TicketPrintJobRow {
  final String id;
  final String paymentId;
  final String kind;
  final int createdAt;
  final String? lastProblem;
  final String paidAt;
  final int? paymentCancelledAt;

  /// Le statut de LA correction qui annule (ticket d'annulation), `null` pour
  /// un ticket de caisse.
  final PaymentCorrectionStatus? correctionStatus;

  /// Une correction en cours ou acquise écarte ce versement des soldes.
  final bool hasLiveCorrection;

  const TicketPrintJobRow({
    required this.id,
    required this.paymentId,
    required this.kind,
    required this.createdAt,
    required this.paidAt,
    this.lastProblem,
    this.paymentCancelledAt,
    this.correctionStatus,
    this.hasLiveCorrection = false,
  });

  factory TicketPrintJobRow.fromMap(Map<String, Object?> m) {
    final status = m['correction_status'] as String?;
    return TicketPrintJobRow(
      id: m['id']! as String,
      paymentId: m['payment_id']! as String,
      kind: m['kind']! as String,
      createdAt: m['created_at']! as int,
      lastProblem: m['last_problem'] as String?,
      paidAt: (m['paid_at'] as String?) ?? '',
      paymentCancelledAt: m['cancelled_at'] as int?,
      correctionStatus: status == null
          ? null
          : PaymentCorrectionStatus.fromDbValue(status),
      hasLiveCorrection: (m['has_live_correction'] as int? ?? 0) != 0,
    );
  }

  bool get isReceipt => kind == TicketPrintJobWriter.receipt;
}
