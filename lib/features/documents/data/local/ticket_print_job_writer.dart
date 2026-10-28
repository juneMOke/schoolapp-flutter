import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

/// Les écritures dans `ticket_print_jobs`, faites DANS la transaction du geste
/// qui crée le besoin d'un papier (continuité des tickets RC, lot D).
///
/// Dans la transaction, et pas après : un versement écrit dont la ligne de
/// file manquerait serait un numéro sans papier, c'est-à-dire exactement le
/// trou que le promoteur traque dans sa pile.
abstract final class TicketPrintJobWriter {
  static const String table = 'ticket_print_jobs';
  static const String receipt = 'receipt';
  static const String cancellation = 'cancellation';

  static const _uuid = Uuid();

  /// Le ticket de caisse d'un versement saisi sur ce poste.
  ///
  /// `ignore` : un rejeu de l'écriture ne crée pas un second ticket.
  static Future<void> enqueueReceipt(
    DatabaseExecutor txn, {
    required String paymentId,
    required int nowMs,
  }) => txn.insert(table, {
    'id': _uuid.v4(),
    'payment_id': paymentId,
    'kind': receipt,
    'created_at': nowMs,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  /// Le ticket d'annulation d'un versement, au nom de [correctionId].
  ///
  /// Remplace une ligne précédente : une correction refusée par le serveur
  /// n'annule rien, et la suivante porte la nouvelle annulation. Son papier
  /// n'est jamais sorti — une annulation refusée ne s'imprime pas.
  static Future<void> enqueueCancellation(
    DatabaseExecutor txn, {
    required String paymentId,
    required String correctionId,
    required int nowMs,
  }) => txn.insert(table, {
    'id': _uuid.v4(),
    'payment_id': paymentId,
    'kind': cancellation,
    'correction_id': correctionId,
    'created_at': nowMs,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}
