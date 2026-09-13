import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Une ligne de `expenses`, telle qu'elle dort en local.
///
/// Les jours (`expense_date`, `paid_on`) sont rangés `YYYY-MM-DD`, les
/// instants (`client_updated_at`, `deleted_at`, `withdrawal_pending_at`) en
/// ISO-8601 UTC : les premiers se comparent comme des chaînes, les seconds se
/// relisent sans perte de précision.
class ExpenseLocalModel {
  final String id;
  final String schoolId;
  final String? expenseNumber;
  final String typeId;
  final String title;
  final String? description;
  final int amountInCents;
  final String currency;
  final String status;
  final String? paidOn;
  final String expenseDate;
  final String? supplier;
  final String fundingSource;
  final String? recordedById;
  final String? recordedByName;
  final String clientUpdatedAt;
  final String? deletedAt;

  /// Le retrait tel que le serveur l'a dit en dernier — l'état auquel revient
  /// un geste refusé.
  final String? serverDeletedAt;
  final String? withdrawalPendingAt;
  final int? version;
  final String? serverUpdatedAt;
  final String syncStatus;
  final String? syncError;
  final String? syncErrorCode;
  final int updatedAt;

  const ExpenseLocalModel({
    required this.id,
    required this.schoolId,
    this.expenseNumber,
    required this.typeId,
    required this.title,
    this.description,
    required this.amountInCents,
    required this.currency,
    required this.status,
    this.paidOn,
    required this.expenseDate,
    this.supplier,
    this.fundingSource = 'CASH',
    this.recordedById,
    this.recordedByName,
    required this.clientUpdatedAt,
    this.deletedAt,
    this.serverDeletedAt,
    this.withdrawalPendingAt,
    this.version,
    this.serverUpdatedAt,
    required this.syncStatus,
    this.syncError,
    this.syncErrorCode,
    this.updatedAt = 0,
  });

  factory ExpenseLocalModel.fromMap(Map<String, Object?> map) =>
      ExpenseLocalModel(
        id: map['id'] as String,
        schoolId: (map['school_id'] as String?) ?? '',
        expenseNumber: map['expense_number'] as String?,
        typeId: (map['type_id'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
        amountInCents: (map['amount_in_cents'] as num?)?.toInt() ?? 0,
        currency: (map['currency'] as String?) ?? '',
        status: (map['status'] as String?) ?? '',
        paidOn: map['paid_on'] as String?,
        expenseDate: (map['expense_date'] as String?) ?? '',
        supplier: map['supplier'] as String?,
        fundingSource: (map['funding_source'] as String?) ?? 'CASH',
        recordedById: map['recorded_by_id'] as String?,
        recordedByName: map['recorded_by_name'] as String?,
        clientUpdatedAt: (map['client_updated_at'] as String?) ?? '',
        deletedAt: map['deleted_at'] as String?,
        serverDeletedAt: map['server_deleted_at'] as String?,
        withdrawalPendingAt: map['withdrawal_pending_at'] as String?,
        version: (map['version'] as num?)?.toInt(),
        serverUpdatedAt: map['server_updated_at'] as String?,
        syncStatus: (map['sync_status'] as String?) ?? '',
        syncError: map['sync_error'] as String?,
        syncErrorCode: map['sync_error_code'] as String?,
        updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      );

  /// Ligne locale d'une saisie : tout ce que le serveur attribue reste tel
  /// que [previous] le portait (numéro, agent, version), l'état de synchro
  /// passe « en attente ».
  factory ExpenseLocalModel.forLocalWrite(
    Expense expense, {
    required String schoolId,
    required int nowMs,
    ExpenseLocalModel? previous,
  }) => ExpenseLocalModel(
    id: expense.id,
    schoolId: schoolId,
    expenseNumber: previous?.expenseNumber,
    typeId: expense.typeId,
    title: expense.title,
    description: expense.description,
    amountInCents: expense.amountInCents,
    currency: expense.currency,
    status: expense.status.wireValue,
    paidOn: expense.paidOn == null ? null : ExpenseDay.format(expense.paidOn!),
    expenseDate: ExpenseDay.format(expense.expenseDate),
    supplier: expense.supplier,
    fundingSource: expense.fundingSource.wireValue,
    recordedById: previous?.recordedById ?? expense.recordedById,
    recordedByName: previous?.recordedByName ?? expense.recordedByName,
    clientUpdatedAt: expense.clientUpdatedAt.toUtc().toIso8601String(),
    deletedAt: previous?.deletedAt,
    serverDeletedAt: previous?.serverDeletedAt,
    withdrawalPendingAt: previous?.withdrawalPendingAt,
    version: previous?.version,
    serverUpdatedAt: previous?.serverUpdatedAt,
    syncStatus: ExpenseSyncState.pending.dbValue,
    updatedAt: nowMs,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'school_id': schoolId,
    'expense_number': expenseNumber,
    'type_id': typeId,
    'title': title,
    'description': description,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'status': status,
    'paid_on': paidOn,
    'expense_date': expenseDate,
    'supplier': supplier,
    'funding_source': fundingSource,
    'recorded_by_id': recordedById,
    'recorded_by_name': recordedByName,
    'client_updated_at': clientUpdatedAt,
    'deleted_at': deletedAt,
    'server_deleted_at': serverDeletedAt,
    'withdrawal_pending_at': withdrawalPendingAt,
    'version': version,
    'server_updated_at': serverUpdatedAt,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'sync_error_code': syncErrorCode,
    'updated_at': updatedAt,
  };

  /// Ce qu'une saisie réécrit sur une ligne **existante** : le contenu et
  /// l'état de synchro, rien d'autre. Numéro, version, retrait et agent
  /// restent ceux que la base porte au moment de l'écriture — un accusé
  /// appliqué entre la lecture et l'écriture n'est jamais défait.
  Map<String, Object?> toLocalWriteMap() => <String, Object?>{
    'type_id': typeId,
    'title': title,
    'description': description,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'status': status,
    'paid_on': paidOn,
    'expense_date': expenseDate,
    'supplier': supplier,
    'funding_source': fundingSource,
    'client_updated_at': clientUpdatedAt,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'sync_error_code': syncErrorCode,
    'updated_at': updatedAt,
  };

  /// `null` sur une ligne dont la date ne se lit plus : mieux vaut l'écarter
  /// du registre que la ranger au 1ᵉʳ janvier 1970.
  Expense? toEntity() {
    final day = ExpenseDay.tryParse(expenseDate);
    if (day == null) return null;
    return Expense(
      id: id,
      number: expenseNumber,
      typeId: typeId,
      title: title,
      description: description,
      amountInCents: amountInCents,
      currency: currency,
      status: ExpenseStatus.fromWire(status),
      paidOn: ExpenseDay.tryParse(paidOn),
      expenseDate: day,
      supplier: supplier,
      fundingSource: ExpenseFundingSource.fromWire(fundingSource),
      recordedById: recordedById,
      recordedByName: recordedByName,
      clientUpdatedAt:
          DateTime.tryParse(clientUpdatedAt)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      deletedAt: deletedAt == null ? null : DateTime.tryParse(deletedAt!),
      syncState: ExpenseSyncState.fromDb(syncStatus),
      syncErrorCode: syncErrorCode,
    );
  }
}
