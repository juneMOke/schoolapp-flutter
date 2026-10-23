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
///
/// ## Ce que le poste sait et que le delta ne dit pas
///
/// `INSERT OR REPLACE` supprime la ligne avant de la réécrire : toute colonne
/// absente de la map retombe à `NULL`. Trois renseignements ne vivent que sur
/// le poste et sont donc **relus avant, puis réécrits** :
///  - `ticket_printed_at` — la trace d'impression, qui ne part jamais ;
///  - `receipt_number` obtenu par la réclamation, quand le delta tait le
///    numéro d'une pièce que le poste connaît déjà ;
///  - `beneficiary_name` des lignes — le delta ne porte que l'identifiant de
///    l'élève, et le nom figé à la vente se perdait au premier pull.
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
        final kept = await _localOnly(txn, sale.id);
        await txn.insert('boutique_sales', {
          'id': sale.id,
          'school_id': schoolId,
          'academic_year_id': sale.academicYearId,
          // Le triplet peut être vide sur une vente d'avant l'alignement du
          // contrat : on retombe alors sur le nom composé. Le redécouper serait
          // une invention — « Ndombo Lelo Willy » ne se redécoupe pas sans se
          // tromper.
          //
          // ⚠️ Et si les deux sont vides, la colonne reste `NULL` : la vente est
          // ANONYME (V114 serveur), pas au nom vide. Jusqu'à la v43 le
          // `NOT NULL` forçait un repli sur `''`, et le ticket imprimait alors
          // un cadre « Payeur » creux — qui se lit comme une mention effacée,
          // pas comme une absence.
          'payer_last_name': sale.payerLastName ?? sale.payerName,
          'payer_middle_name': sale.payerMiddleName,
          'payer_first_name': sale.payerFirstName,
          'payer_phone_number': sale.payerPhoneNumber,
          'payer_name': sale.payerName,
          'collected_by_id': sale.collectedById,
          'collected_by_name': sale.collectedByName,
          'sold_at': sale.soldAt,
          'receipt_document_id': sale.receiptDocumentId,
          // Le numéro descendu fait foi. À défaut, celui que le poste tient de
          // la réclamation — mais seulement pour la MÊME pièce : un numéro
          // n'est jamais inventé, ni reporté sur une pièce qu'il ne désigne pas.
          'receipt_number':
              sale.receiptNumber ??
              (sale.receiptDocumentId != null &&
                      sale.receiptDocumentId == kept.receiptDocumentId
                  ? kept.receiptNumber
                  : null),
          'ticket_printed_at': kept.ticketPrintedAt,
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
            // Le nom figé à la vente, s'il désigne toujours le même élève.
            'beneficiary_name':
                kept.beneficiaryNames[(line.id, line.beneficiaryStudentId)],
            'school_level_id': line.schoolLevelId,
            'size': line.size,
            'quantity': line.quantity,
            'unit_price_in_cents': line.unitPriceInCents,
            'line_total_in_cents': line.lineTotalInCents,
            'currency': line.currency,
            'position': index,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // ⚠️ **Remplacées seulement quand le serveur en envoie.**
        //
        // Une vente d'avant l'alignement du contrat redescend sans ligne
        // d'encaissement. Purger sur cette liste vide effacerait l'identité que
        // le backfill de la v42 a posée — et la vente se relirait comme si rien
        // n'était entré dans le tiroir, sur un poste où le ticket doit encore
        // pouvoir se réimprimer.
        //
        // Quand il en envoie, en revanche, il fait autorité : la fusion
        // laisserait vivre une ligne locale que l'ingestion a écartée, et la
        // caisse du soir ne retomberait plus.
        if (sale.tenders.isNotEmpty) {
          await txn.delete(
            'boutique_sale_tenders',
            where: 'sale_id = ?',
            whereArgs: [sale.id],
          );
          for (final tender in sale.tenders) {
            await txn.insert(
              'boutique_sale_tenders',
              {
                'id': tender.id,
                'sale_id': sale.id,
                'amount_in_cents': tender.amountInCents,
                'currency': tender.currency,
                'rate_micros': tender.rateMicros,
                // Le pivot vaut la devise reçue quand le serveur le tait : c'est
                // le cas d'un règlement sans conversion, où les deux se
                // confondent.
                'pivot_currency': tender.pivotCurrency ?? tender.currency,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    });

    return sales.length;
  }

  /// Ce que la réécriture effacerait, lu avant elle.
  static Future<_LocalOnly> _localOnly(Transaction txn, String saleId) async {
    final rows = await txn.query(
      'boutique_sales',
      columns: const [
        'receipt_document_id',
        'receipt_number',
        'ticket_printed_at',
      ],
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    final lines = await txn.query(
      'boutique_sale_lines',
      columns: const ['id', 'beneficiary_student_id', 'beneficiary_name'],
      where: 'sale_id = ? AND beneficiary_name IS NOT NULL',
      whereArgs: [saleId],
    );
    final row = rows.isEmpty ? null : rows.first;
    return _LocalOnly(
      receiptDocumentId: row?['receipt_document_id'] as String?,
      receiptNumber: row?['receipt_number'] as String?,
      ticketPrintedAt: row?['ticket_printed_at'] as int?,
      beneficiaryNames: {
        for (final line in lines)
          (line['id'] as String, line['beneficiary_student_id'] as String?):
              line['beneficiary_name'] as String,
      },
    );
  }
}

class _LocalOnly {
  final String? receiptDocumentId;
  final String? receiptNumber;
  final int? ticketPrintedAt;

  /// Clé (ligne, élève) : un nom ne survit que si la ligne désigne encore le
  /// même enfant.
  final Map<(String, String?), String> beneficiaryNames;

  const _LocalOnly({
    this.receiptDocumentId,
    this.receiptNumber,
    this.ticketPrintedAt,
    this.beneficiaryNames = const {},
  });
}
