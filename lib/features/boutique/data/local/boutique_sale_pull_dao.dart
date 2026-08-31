import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_pull_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Application du delta des ventes.
///
/// ## Pourquoi un upsert ne perd rien
///
/// Le serveur ne connaît une vente **que** si elle lui a été poussée. Une vente
/// encore locale (`PENDING_SYNC`, jamais partie) ne peut donc pas descendre : il
/// n'y a aucun conflit à arbitrer, et rien à écraser.
///
/// Le seul recouvrement possible est celui d'une vente **réellement enregistrée
/// côté serveur** dont l'ACK s'est perdu : le delta la redescend, et l'appliquer
/// **répare** l'état local plutôt que de le corrompre — c'est ce qui fait passer
/// la vente en `SYNCED` et lui donne son reçu. L'outbox la repoussera peut-être
/// une fois de plus ; le POST est idempotent, elle rendra 200.
class BoutiqueSalePullDao {
  final Database _db;

  const BoutiqueSalePullDao(this._db);

  /// Applique une page de ventes. Rend le nombre de ventes écrites.
  Future<int> applySales(
    List<BoutiqueSaleDeltaDto> sales, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (sales.isEmpty) return 0;

    await _db.transaction((txn) async {
      for (final sale in sales) {
        await txn.insert('boutique_sales', {
          'id': sale.id,
          'school_id': schoolId,
          'academic_year_id': sale.academicYearId,
          // Le triplet peut être vide sur une vente d'avant l'alignement du
          // contrat : on retombe alors sur le nom composé, qui existe toujours.
          // Le redécouper serait une invention — « Ndombo Lelo Willy » ne se
          // redécoupe pas sans se tromper.
          'payer_last_name': sale.payerLastName ?? sale.payerName ?? '',
          'payer_middle_name': sale.payerMiddleName,
          'payer_first_name': sale.payerFirstName,
          'payer_phone_number': sale.payerPhoneNumber,
          'payer_name': sale.payerName,
          'collected_by_id': sale.collectedById,
          'collected_by_name': sale.collectedByName,
          'sold_at': sale.soldAt,
          'receipt_document_id': sale.receiptDocumentId,
          // ⚠️ Le delta ne porte PAS le numéro de la pièce, seulement son
          // identifiant d'archive. On ne l'invente pas : un ticket réimprimé
          // avec un faux numéro serait pire qu'un ticket provisoire honnête.
          // Le numéro arrive par la réclamation du reçu.
          'sync_status': 'SYNCED',
          'sync_error': null,
          'synced_at': nowMs,
          'server_updated_at': sale.serverUpdatedAt,
          'updated_at': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Les lignes sont REMPLACÉES, jamais fusionnées : le serveur fait
        // autorité sur le contenu du panier d'une vente qu'il a enregistrée.
        // Une fusion laisserait vivre une ligne locale que l'ingestion aurait
        // écartée, et le ticket ne se recompterait plus.
        await txn.delete(
          'boutique_sale_lines',
          where: 'sale_id = ?',
          whereArgs: [sale.id],
        );
        for (var index = 0; index < sale.lines.length; index++) {
          final line = sale.lines[index];
          await txn.insert('boutique_sale_lines', {
            'id': line.id,
            'sale_id': sale.id,
            'article_id': line.articleId,
            // Le libellé descendu s'il existe ; sinon l'identifiant, qui est
            // toujours préférable à une ligne muette sur un ticket.
            'article_label': line.articleLabel ?? line.articleId,
            'beneficiary_student_id': line.beneficiaryStudentId,
            'school_level_id': line.schoolLevelId,
            'size': line.size,
            'quantity': line.quantity,
            'unit_price_in_cents': line.unitPriceInCents,
            'line_total_in_cents': line.lineTotalInCents,
            'currency': line.currency,
            'position': index,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    return sales.length;
  }
}
