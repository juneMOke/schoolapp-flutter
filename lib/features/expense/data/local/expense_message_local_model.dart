import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';

/// Une ligne de `expense_messages`, telle qu'elle dort en local.
///
/// [createdAt] est rangé en ISO-8601 UTC : c'est l'horloge qui ordonne la
/// séquence des gestes (F31), et elle se compare comme une chaîne. Une
/// écriture d'une autre forme se classerait donc de travers — toute
/// fabrication passe par [ExpenseMessageLocalModel.at].
class ExpenseMessageLocalModel {
  final String id;
  final String schoolId;
  final String expenseId;
  final String body;
  final String? act;
  final String? authorId;
  final String? authorName;
  final String createdAt;
  final String syncStatus;

  const ExpenseMessageLocalModel({
    required this.id,
    required this.schoolId,
    required this.expenseId,
    required this.body,
    this.act,
    this.authorId,
    this.authorName,
    required this.createdAt,
    this.syncStatus = 'PENDING_SYNC',
  });

  /// Un message neuf, horodaté sous la seule forme que la table accepte.
  factory ExpenseMessageLocalModel.at(
    DateTime moment, {
    required String id,
    required String schoolId,
    required String expenseId,
    required String body,
    ExpenseAct? act,
    String? authorId,
    String? authorName,
    ExpenseSyncState syncState = ExpenseSyncState.pending,
  }) => ExpenseMessageLocalModel(
    id: id,
    schoolId: schoolId,
    expenseId: expenseId,
    body: body,
    act: act?.wireValue,
    authorId: authorId,
    authorName: authorName,
    createdAt: moment.toUtc().toIso8601String(),
    syncStatus: syncState.dbValue,
  );

  /// Un message tel que le serveur le rend : il est **accusé par
  /// construction** — c'est lui qui fait foi.
  factory ExpenseMessageLocalModel.fromDelta(
    ExpenseMessageDeltaDto dto, {
    required String schoolId,
    required String expenseId,
  }) => ExpenseMessageLocalModel(
    id: dto.id,
    schoolId: schoolId,
    expenseId: expenseId,
    body: dto.body,
    act: dto.act,
    authorId: dto.authorId,
    authorName: dto.authorName,
    createdAt: dto.createdAt,
    syncStatus: ExpenseSyncState.synced.dbValue,
  );

  factory ExpenseMessageLocalModel.fromMap(Map<String, Object?> map) =>
      ExpenseMessageLocalModel(
        id: map['id'] as String,
        schoolId: (map['school_id'] as String?) ?? '',
        expenseId: (map['expense_id'] as String?) ?? '',
        body: (map['body'] as String?) ?? '',
        act: map['act'] as String?,
        authorId: map['author_id'] as String?,
        authorName: map['author_name'] as String?,
        createdAt: (map['created_at'] as String?) ?? '',
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'school_id': schoolId,
    'expense_id': expenseId,
    'body': body,
    'act': act,
    'author_id': authorId,
    'author_name': authorName,
    'created_at': createdAt,
    'sync_status': syncStatus,
  };

  /// `null` quand l'horloge est illisible : un message que l'on ne saurait pas
  /// placer dans le fil n'a pas de place dans le fil. Le rendre sans date
  /// l'aurait fait tomber au hasard entre deux gestes.
  ExpenseMessage? toEntity() {
    final moment = DateTime.tryParse(createdAt);
    if (moment == null) return null;
    return ExpenseMessage(
      id: id,
      expenseId: expenseId,
      body: body,
      act: ExpenseAct.fromWire(act),
      authorId: authorId,
      authorName: authorName,
      createdAt: moment,
      syncState: ExpenseSyncState.fromDb(syncStatus),
    );
  }
}
