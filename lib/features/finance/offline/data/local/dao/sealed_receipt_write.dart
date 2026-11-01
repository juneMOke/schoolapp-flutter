import 'package:sqflite_common/sqlite_api.dart';

/// L'écriture d'un reçu scellé sur sa ligne `generated_documents` — la même à
/// l'accusé de synchro et à la récupération du reçu.
///
/// Le numéro définitif remplace le `PROV-…`, et avec lui les faits de CE
/// numéro : son jour d'émission (v71), son URL de vérification (v72) et son
/// édition (v73), qui datent et signent le ticket.
///
/// ⚠️ **Un fait absent ne survit pas à un changement de numéro.** Un serveur
/// antérieur (ou une réédition) peut rendre un autre numéro sans jour ni URL :
/// garder ceux de l'ancien daterait le ticket d'un autre jour et le ferait
/// vérifier contre une autre pièce. Une autre édition du même numéro est une
/// autre pièce au même titre. Même pièce, en revanche, le fait connu reste : un
/// rejeu qui ne le porte pas ne l'efface pas.
abstract final class SealedReceiptWrite {
  static Future<void> seal(
    DatabaseExecutor db, {
    required String paymentId,
    required String docType,
    required String number,
    required String status,
    String? emittedOn,
    String? verificationUrl,
    int? edition,
  }) async {
    const where = 'payment_id = ? AND doc_domain = ? AND doc_type = ?';
    final args = [paymentId, 'PAYMENT', docType];

    final dropped = <String, Object?>{
      if (emittedOn == null) 'emitted_on': null,
      if (verificationUrl == null) 'verification_url': null,
      if (edition == null) 'edition': null,
    };
    if (dropped.isNotEmpty) {
      await db.update(
        'generated_documents',
        dropped,
        where: edition == null
            ? '$where AND number <> ?'
            : '$where AND (number <> ? OR COALESCE(edition, 1) <> ?)',
        whereArgs: [...args, number, ?edition],
      );
    }
    await db.update(
      'generated_documents',
      {
        'number': number,
        'status': status,
        'emitted_on': ?emittedOn,
        'verification_url': ?verificationUrl,
        'edition': ?edition,
      },
      where: where,
      whereArgs: args,
    );
  }
}
