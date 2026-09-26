import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

/// La seule définition SQL d'un versement **en vigueur** — et de ce qu'une
/// correction en attente retire aux soldes (lot T1 ; branchée par T2).
///
/// Les lectures de solde en recopiaient chacune un morceau
/// (`p.cancelled_at IS NULL`) : cinq agrégats du grand-livre, le solde du
/// ticket, l'annuaire des payeurs. Une correction locale ajoute une seconde
/// condition ; la recopier sept fois garantissait qu'un endroit l'oublie.
///
/// ## Deux prédicats, deux usages
///
/// - [inForce] : le versement compte comme argent reçu. Sert à tout ce qui lit
///   les versements eux-mêmes (listes, `paid_pending`, historique du ticket).
/// - [pendingServerCancellation] : un versement **synchronisé** qu'une
///   correction en attente annule. Le serveur l'a déjà compté dans
///   `student_charges.amount_paid` ; tant que son annulation ne redescend pas,
///   la tablette doit le **retrancher** elle-même.
///
/// ⚠️ Ce second terme s'éteint seul dès que `payments.cancelled_at` arrive (par
/// l'ACK ou le pull) : les créances que le serveur renvoie ont alors déjà été
/// recalculées. Le garder au-delà retrancherait deux fois le même argent.
///
/// Les valeurs d'état sont écrites en littéraux, jamais liées : chaque
/// requête garde ainsi ses `whereArgs` inchangés.
abstract final class PaymentInForceSql {
  /// États d'une correction qui retirent l'origine des soldes.
  static final String _removingStatuses = PaymentCorrectionStatus.values
      .where((s) => s.removesOrigin)
      .map((s) => "'${s.dbValue}'")
      .join(', ');

  static final String _pending = "'${PaymentCorrectionStatus.pending.dbValue}'";

  static final String _synced = "'${SyncState.synced.dbValue}'";

  /// Le versement d'alias [alias] compte comme argent reçu.
  static String inForce(String alias) =>
      '($alias.cancelled_at IS NULL AND NOT EXISTS ('
      'SELECT 1 FROM payment_corrections pc_if '
      'WHERE pc_if.payment_id = $alias.id '
      'AND pc_if.status IN ($_removingStatuses)))';

  /// Le versement d'alias [alias] est synchronisé, et une correction en
  /// attente l'annule sans que le serveur l'ait encore dit.
  static String pendingServerCancellation(String alias) =>
      '($alias.cancelled_at IS NULL AND $alias.sync_status = $_synced '
      'AND EXISTS ('
      'SELECT 1 FROM payment_corrections pc_psc '
      'WHERE pc_psc.payment_id = $alias.id '
      'AND pc_psc.status = $_pending))';
}
