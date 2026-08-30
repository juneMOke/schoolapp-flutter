import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lecture de la caisse : les ventes d'une fenêtre, la plus récente en tête.
///
/// **Aucune écriture ici.** L'historique regarde l'argent, il n'y touche pas.
class BoutiqueSaleHistoryDao {
  final Database _db;

  const BoutiqueSaleHistoryDao(this._db);

  /// Les ventes de l'école, de l'année et de la fenêtre.
  ///
  /// Le compte d'articles vient d'une sous-requête agrégée et non d'une
  /// jointure : joindre les lignes dupliquerait la vente autant de fois qu'elle
  /// a d'articles, et le total de la fenêtre se compterait plusieurs fois.
  ///
  /// Le scope école n'est pas décoratif : la conception « une tablette, une
  /// école » a déjà produit dix flux à curseur nu, et l'omettre montrerait au
  /// guichet la caisse de l'établissement voisin.
  Future<List<SaleHistoryEntry>> salesSince({
    required String schoolId,
    required String academicYearId,
    required String soldAtBound,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        s.id AS id,
        s.payer_name AS payer_name,
        s.payer_last_name AS payer_last_name,
        s.payer_middle_name AS payer_middle_name,
        s.payer_first_name AS payer_first_name,
        s.payer_phone_number AS payer_phone_number,
        s.total_in_cents AS total_in_cents,
        s.currency AS currency,
        s.sold_at AS sold_at,
        s.receipt_number AS receipt_number,
        s.sync_status AS sync_status,
        (
          SELECT COALESCE(SUM(l.quantity), 0)
          FROM boutique_sale_lines l
          WHERE l.sale_id = s.id
        ) AS article_count
      FROM boutique_sales s
      WHERE s.school_id = ?
        AND s.academic_year_id = ?
        AND s.sold_at >= ?
      ORDER BY s.sold_at DESC
      ''',
      [schoolId, academicYearId, soldAtBound],
    );

    return [
      for (final row in rows)
        SaleHistoryEntry(
          id: row['id'] as String,
          payerName: _payerNameOf(row),
          payerPhoneNumber: row['payer_phone_number'] as String?,
          totalInCents: (row['total_in_cents'] as num).toInt(),
          currency: row['currency'] as String,
          soldAt: row['sold_at'] as String,
          receiptNumber: row['receipt_number'] as String?,
          syncStatus: row['sync_status'] as String,
          articleCount: (row['article_count'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  /// Une vente entière — en-tête et lignes — pour la fiche de détail et pour
  /// la réimpression de son ticket.
  ///
  /// Rend `null` si la vente n'existe pas **pour cette école** : le scope n'est
  /// pas décoratif, un identifiant deviné ouvrirait la vente de l'établissement
  /// voisin sur une tablette partagée.
  Future<RecordedSale?> saleById({
    required String schoolId,
    required String saleId,
  }) async {
    final rows = await _db.query(
      'boutique_sales',
      where: 'id = ? AND school_id = ?',
      whereArgs: [saleId, schoolId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final lines = await _db.query(
      'boutique_sale_lines',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      // L'ordre de composition, celui du ticket : le relire dans un autre ordre
      // que le papier remis au client ferait douter des deux.
      orderBy: 'position ASC',
    );

    return RecordedSale(
      sale: BoutiqueSaleLocalModel.fromMap(rows.first),
      lines: [
        for (final line in lines) BoutiqueSaleLineLocalModel.fromMap(line),
      ],
    );
  }

  /// Le ticket a-t-il déjà été sorti de l'imprimante pour cette vente ?
  ///
  /// Renseignement d'affichage seul : il **n'interdit jamais** de réimprimer.
  /// Un papier se déchire, une imprimante se bloque à mi-course, et un client
  /// repart parfois sans son ticket — refuser la seconde sortie sur la foi
  /// d'une trace locale laisserait le guichet sans recours.
  Future<DateTime?> ticketPrintedAt({
    required String schoolId,
    required String saleId,
  }) async {
    final rows = await _db.query(
      'boutique_sales',
      columns: const ['ticket_printed_at'],
      where: 'id = ? AND school_id = ?',
      whereArgs: [saleId, schoolId],
      limit: 1,
    );
    final at = rows.isEmpty ? null : rows.first['ticket_printed_at'] as int?;
    return at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
  }

  /// Note qu'un ticket est sorti. **Ne touche à aucun montant** : la trace
  /// d'impression n'est pas de l'argent, et elle ne part jamais au serveur.
  Future<void> markTicketPrinted({required String saleId, required int atMs}) =>
      _db.update(
        'boutique_sales',
        {'ticket_printed_at': atMs},
        where: 'id = ?',
        whereArgs: [saleId],
      );

  /// Le nom composé **rendu par le serveur** en priorité ; à défaut, les champs
  /// saisis dans l'ordre où le guichet les a remplis.
  ///
  /// Jamais l'inverse : recomposer alors que le serveur a répondu écraserait sa
  /// forme d'affichage par la nôtre, et les deux ne coïncident pas.
  static String _payerNameOf(Map<String, Object?> row) {
    final composed = row['payer_name'] as String?;
    if (composed != null && composed.trim().isNotEmpty) return composed;
    return [
      row['payer_last_name'] as String?,
      row['payer_middle_name'] as String?,
      row['payer_first_name'] as String?,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
  }
}
