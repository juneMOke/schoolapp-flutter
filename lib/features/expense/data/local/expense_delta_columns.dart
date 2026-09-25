import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Les colonnes de `expenses` qu'écrit l'état canonique d'une dépense
/// (`ExpenseDelta`), rangées en deux familles — c'est leur séparation qui
/// protège une saisie locale plus récente (cf. `ExpenseSyncDao`) :
///
/// - [content] : ce que l'agent saisit — posé seulement quand la ligne n'a
///   rien de plus récent en attente ;
/// - [server] : ce que le serveur attribue (numéro, agent, version, retrait
///   tel qu'il le voit) — toujours posé.
abstract final class ExpenseDeltaColumns {
  static Map<String, Object?> content(ExpenseDeltaDto d) => {
    'type_id': d.typeId,
    'title': d.title,
    'description': d.description,
    'amount_in_cents': d.amountInCents,
    'currency': d.currency,
    'expense_date': d.expenseDate,
    'supplier': d.supplier,
    'funding_source': d.fundingSource,
    'client_updated_at': d.clientUpdatedAt,
  };

  /// Le **statut et la date de règlement ont changé de famille en v2** : le
  /// poste ne les écrit plus (D8), le serveur seul les arbitre. Les laisser
  /// côté contenu les aurait fait retenir par une saisie locale plus récente —
  /// une décision prise ailleurs serait restée invisible sur ce poste.
  static Map<String, Object?> server(ExpenseDeltaDto d) => {
    'status': d.status,
    'paid_on': d.paidOn,
    'expense_number': ?d.expenseNumber,
    'recorded_by_id': d.recordedById,
    'recorded_by_name': d.recordedByName,
    'version': d.version,
    'server_updated_at': d.serverUpdatedAt,
    'server_deleted_at': d.deletedAt,
    // Les six colonnes de décision suivent le statut, et pour la même raison :
    // une décision est prise AILLEURS. Les laisser côté contenu les ferait
    // retenir par une saisie locale plus récente, et le poste afficherait une
    // demande « en attente » que la direction a déjà tranchée.
    'decided_by_id': d.decidedById,
    'decided_by_name': d.decidedByName,
    'decided_at': d.decidedAt,
    'decision_reason': d.decisionReason,
    'reminder_count': d.reminderCount,
  };

  /// ⚠️ `last_message_at` n'est **PAS** dans [server], et ce n'est pas un
  /// oubli : la fraîcheur du fil **ne recule jamais** (règle verrouillée à
  /// DEP-11). Le serveur ne connaît pas encore le message qu'un geste local
  /// vient d'écrire ; poser sa valeur telle quelle rendrait la demande plus
  /// calme qu'elle n'est. Elle se pose donc sous condition, par
  /// [ExpenseMessageDao.bumpLastMessageAt].

  /// La ligne porte désormais exactement ce que le serveur a retenu.
  static Map<String, Object?> get synced => {
    'sync_status': ExpenseSyncState.synced.dbValue,
    'sync_error': null,
    'sync_error_code': null,
  };

  /// La ligne entière d'une dépense que le poste ne connaissait pas.
  static Map<String, Object?> newRow(
    ExpenseDeltaDto delta, {
    required String schoolId,
    required int nowMs,
  }) =>
      ExpenseLocalModel(
          id: delta.id,
          schoolId: schoolId,
          typeId: delta.typeId,
          title: delta.title,
          amountInCents: delta.amountInCents,
          currency: delta.currency,
          status: delta.status,
          expenseDate: delta.expenseDate,
          clientUpdatedAt: delta.clientUpdatedAt,
          syncStatus: ExpenseSyncState.synced.dbValue,
        ).toMap()
        ..addAll(server(delta))
        ..addAll(content(delta))
        ..['deleted_at'] = delta.deletedAt
        ..['updated_at'] = nowMs;

  /// Deux instants ISO comparés comme des instants : `…:40Z` et
  /// `…:40.000Z` désignent le même.
  static bool sameInstant(String? a, String? b) {
    if (a == null || b == null) return a == b;
    final left = DateTime.tryParse(a);
    final right = DateTime.tryParse(b);
    if (left == null || right == null) return a == b;
    return left.isAtSameMomentAs(right);
  }
}
