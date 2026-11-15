import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_in_force_sql.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// [CashPendingProbe] sur la base de la tablette.
///
/// L'outbox partagée ne porte ni devise ni date : on compte donc **sur les
/// tables métier**, par la devise reçue (lignes de perçu pour les versements
/// et les ventes, colonne unique pour les dépenses et la paie).
///
/// **Aucune borne de date.** La sonde ne sert qu'aujourd'hui, et tout fait
/// d'argent encore sur la tablette pèse sur le reste d'aujourd'hui, quel que
/// soit son jour : un encaissement de la veille non clôturée manque à
/// l'ouverture, une vente du dimanche compte pour le lundi, le remplaçant
/// d'une correction garde l'instant de son origine. Le serveur range chacun
/// sur sa journée ; la tablette, elle, n'a qu'à savoir que **quelque chose**
/// n'est pas parti.
///
/// « En attente » veut dire : partira encore. Chaque famille se joint donc à
/// son entrée d'outbox `PENDING`, par l'identifiant d'**entrée** que son
/// écrivain lui donne : un élément refusé par le serveur (« à régulariser »)
/// ou une entrée empoisonnée ne partira plus sans un geste, et ne bloque pas
/// la clôture.
class CashPendingProbeSql implements CashPendingProbe {
  final Database _db;

  const CashPendingProbeSql(this._db);

  static final String _pendingOutbox = OutboxStatus.pending.dbValue;
  static final String _synced = SyncState.synced.dbValue;
  static final String _pendingSync = SyncState.pendingSync.dbValue;

  @override
  Future<int> pendingFor(TreasuryCurrency currency) async {
    final code = currency.code;
    var total = 0;
    for (final query in [
      _payments,
      _corrections,
      _shopSales,
      _cashExpenses,
      _cashPayroll,
      _cashPayrollCancellations,
      _cashAdvances,
      _cashAdvanceCancellations,
    ]) {
      final rows = await _db.rawQuery(query, [code]);
      total += (rows.first['c'] as int?) ?? 0;
    }
    return total;
  }

  /// L'entrée `PENDING` dont l'identifiant vaut [idExpr] (une expression SQL).
  static String _entryPending(String idExpr) =>
      'EXISTS (SELECT 1 FROM ${OutboxDao.table} o '
      "WHERE o.id = $idExpr AND o.status = '$_pendingOutbox')";

  /// L'entrée `PENDING` d'un agrégat dont l'identifiant d'agrégat est l'id de
  /// la ligne (versements, corrections, ventes).
  static String _outboxPending(String type, String idExpr) =>
      'EXISTS (SELECT 1 FROM ${OutboxDao.table} o '
      "WHERE o.aggregate_type = '$type' AND o.aggregate_id = $idExpr "
      "AND o.status = '$_pendingOutbox')";

  /// (a) Versements de frais encore à envoyer, dont une ligne de perçu est
  /// dans la devise.
  static String get _payments =>
      '''
      SELECT COUNT(DISTINCT p.id) AS c
      FROM payments p
      JOIN payment_tenders t ON t.payment_id = p.id
      WHERE p.sync_status <> '$_synced'
        AND ${PaymentInForceSql.inForce('p')}
        AND t.currency = ? AND t.amount_in_cents > 0
        AND ${_outboxPending('PAYMENT', 'p.id')}
      ''';

  /// (b) Corrections et annulations encore à envoyer, sur un versement (ou
  /// un remplaçant) perçu dans la devise.
  static String get _corrections =>
      '''
      SELECT COUNT(DISTINCT pc.id) AS c
      FROM payment_corrections pc
      JOIN payment_tenders t
        ON t.payment_id = pc.payment_id OR t.payment_id = pc.replacement_payment_id
      WHERE pc.status = 'PENDING'
        AND t.currency = ? AND t.amount_in_cents > 0
        AND ${_outboxPending('PAYMENT_CORRECTION', 'pc.id')}
      ''';

  /// (c) Ventes boutique encore à envoyer, perçues dans la devise.
  static String get _shopSales =>
      '''
      SELECT COUNT(DISTINCT s.id) AS c
      FROM boutique_sales s
      JOIN boutique_sale_tenders t ON t.sale_id = s.id
      WHERE s.sync_status = '$_pendingSync'
        AND t.currency = ? AND t.amount_in_cents > 0
        AND ${_outboxPending('BOUTIQUE_SALE', 's.id')}
      ''';

  /// (d) Paiements de dépenses en espèces encore à envoyer. Un geste a son
  /// entrée à lui (`EXPENSE_GESTURE:{message}`) : un message resté
  /// `PENDING_SYNC` sur une entrée morte (corps illisible, empoisonnement) ne
  /// bloque pas la caisse pour toujours.
  static String get _cashExpenses =>
      '''
      SELECT COUNT(*) AS c
      FROM expense_messages m
      JOIN expenses e ON e.id = m.expense_id
      WHERE m.act = 'PAYMENT' AND m.sync_status = '$_pendingSync'
        AND e.funding_source = 'CASH'
        AND e.currency = ?
        AND ${_entryPending("'${ExpenseWriteDao.gestureAggregateType}:' || m.id")}
      ''';

  /// (e) Versements de salaire en espèces encore à envoyer. Leur agrégat est
  /// la ligne de paie (`payroll-line:…`), pas le versement : on joint par
  /// l'identifiant d'entrée.
  static String get _cashPayroll =>
      '''
      SELECT COUNT(*) AS c
      FROM payroll_disbursements d
      WHERE d.mode = 'CASH' AND d.currency = ?
        AND ${_entryPending("'${PayrollOutbox.disbursement}:' || d.id")}
      ''';

  /// (f) Annulations de versements de salaire en espèces : l'argent revient
  /// au tiroir.
  static String get _cashPayrollCancellations =>
      '''
      SELECT COUNT(*) AS c
      FROM payroll_disbursements d
      WHERE d.mode = 'CASH' AND d.currency = ?
        AND d.cancellation_id IS NOT NULL
        AND ${_entryPending("'${PayrollOutbox.disbursementCancellation}:' || d.cancellation_id")}
      ''';

  /// (g) Avances sur salaire en espèces : le serveur en fait une dépense,
  /// donc une sortie de caisse.
  static String get _cashAdvances =>
      '''
      SELECT COUNT(*) AS c
      FROM salary_advances a
      WHERE a.mode = 'CASH' AND a.currency = ?
        AND ${_entryPending("'${PayrollOutbox.advance}:' || a.id")}
      ''';

  /// (h) Annulations d'avances en espèces.
  static String get _cashAdvanceCancellations =>
      '''
      SELECT COUNT(*) AS c
      FROM salary_advances a
      WHERE a.mode = 'CASH' AND a.currency = ?
        AND a.cancellation_id IS NOT NULL
        AND ${_entryPending("'${PayrollOutbox.advanceCancellation}:' || a.cancellation_id")}
      ''';
}
