import 'package:sqflite_common/sqlite_api.dart';

/// Ce que la base de l'ÉCOLE sait du reçu d'un versement.
class PaymentReceiptLocalRow {
  /// Le versement existe localement.
  final bool paymentFound;

  /// `payments.receipt_id` : l'identifiant serveur de la pièce, descendu par
  /// le pull des versements et par l'ACK.
  final String? receiptId;

  /// `payments.cancelled_at`, posé par le serveur seul.
  final int? paymentCancelledAt;

  /// Numéro de la ligne RC locale (`generated_documents`), `null` sans ligne.
  final String? documentNumber;

  /// Numéro provisoire de cette ligne. Il survit au scellement, là où
  /// [documentNumber] est écrasé par le numéro définitif.
  final String? provisionalNumber;

  /// `DEFINITIVE` | `PROVISIONAL` | autre.
  final String? documentStatus;

  const PaymentReceiptLocalRow({
    this.paymentFound = false,
    this.receiptId,
    this.paymentCancelledAt,
    this.documentNumber,
    this.provisionalNumber,
    this.documentStatus,
  });
}

/// Lectures de la base de l'école pour `PaymentReceiptResolver` (T0, R1).
///
/// ⚠️ **Aucune jointure vers le cache des pièces.** Celui-ci vit dans
/// `device.db` depuis la v49 ; `payments` et `generated_documents` vivent ici.
/// Une requête qui les joindrait passerait sous `openFullOfflineDb()` — qui met
/// tout dans une seule base — et casserait en production.
class PaymentReceiptLookupDao {
  final Database _db;

  const PaymentReceiptLookupDao(this._db);

  Future<PaymentReceiptLocalRow> find(String paymentId) async {
    final payments = await _db.query(
      'payments',
      columns: const ['receipt_id', 'cancelled_at'],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    // Même requête que `FinanceLedgerReadDao.getPaymentReceipt` : la ligne RC
    // la plus récente du versement.
    final documents = await _db.query(
      'generated_documents',
      columns: const ['number', 'provisional_number', 'status'],
      where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
      whereArgs: [paymentId, 'PAYMENT', 'RC'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    final payment = payments.isEmpty ? null : payments.first;
    final document = documents.isEmpty ? null : documents.first;
    return PaymentReceiptLocalRow(
      paymentFound: payment != null,
      receiptId: _text(payment?['receipt_id']),
      paymentCancelledAt: payment?['cancelled_at'] as int?,
      documentNumber: _text(document?['number']),
      provisionalNumber: _text(document?['provisional_number']),
      documentStatus: document?['status'] as String?,
    );
  }

  static String? _text(Object? value) {
    final text = (value as String?)?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
