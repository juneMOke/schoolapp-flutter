import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/exchange_rate_reader.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/mappers/expense_mappers.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';

/// Le registre du poste : lecture locale, écriture locale **et** mise en file.
///
/// Toute écriture exige un agent connecté : le serveur compare `authorId` au
/// compte du jeton, et une entrée sans auteur serait refusée — terminal, donc
/// perdue. Mieux vaut refuser la saisie tout de suite.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseReadDao _reader;
  final ExpenseWriteDao _writer;
  final ExpenseTypeDao _types;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final ExchangeRateReader _rates;

  /// Pousse après chaque écriture, sans attendre le battement ; `null` dans
  /// un harnais sans moteur.
  final SyncEngine? _syncEngine;

  /// Jour de rentrée de l'année courante (référentiel), ou `null`.
  final Future<DateTime?> Function() _schoolYearStart;
  final DateTime Function() _now;

  const ExpenseRepositoryImpl({
    required ExpenseReadDao reader,
    required ExpenseWriteDao writer,
    required ExpenseTypeDao types,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    required ExchangeRateReader rates,
    required Future<DateTime?> Function() schoolYearStart,
    SyncEngine? syncEngine,
    DateTime Function() now = DateTime.now,
  }) : _reader = reader,
       _writer = writer,
       _types = types,
       _currentUser = currentUser,
       _ids = ids,
       _rates = rates,
       _syncEngine = syncEngine,
       _schoolYearStart = schoolYearStart,
       _now = now;

  @override
  Future<Either<Failure, ExpenseRegisterSnapshot>> loadRegister() async {
    final schoolId = _currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return const Left(StorageFailure('Aucune école'));
    try {
      final types = await _types.typesForSchool(schoolId);
      final rows = await _reader.expensesForSchool(schoolId);
      // Le taux ne fait jamais échouer la lecture : sans lui, l'écran montre
      // la paire brute (A5). Vérité stricte, pas de repli sur le plus ancien —
      // c'est un écran de direction, pas un guichet.
      final rate = ExchangeRates.at(
        await _rates.forCurrentSchool(),
        base: CurrencyCode.usd,
        quote: CurrencyCode.cdf,
        moment: _now(),
      );
      return Right(
        ExpenseRegisterSnapshot(
          types: [for (final t in types) t.toEntity()],
          expenses: [for (final r in rows) ?r.toEntity()],
          usdToCdf: rate,
          anchor: SchoolYearAnchor.fromStartDate(await _yearStart()),
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Registre local illisible : $e'));
    }
  }

  @override
  Future<Either<Failure, Expense>> save(ExpenseDraft draft) async {
    final schoolId = _currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return const Left(StorageFailure('Aucune école'));
    final authorId = _currentUser.uid;
    if (authorId == null) return const Left(_noAgent);
    try {
      final now = _now();
      final id = draft.id ?? _ids.newId();
      final previous = await _reader.find(id);
      final expense = Expense(
        id: id,
        typeId: draft.typeId,
        title: draft.title.trim(),
        description: _blankToNull(draft.description),
        amountInCents: draft.amountInCents,
        currency: CurrencyCode.normalize(draft.currency),
        status: draft.status,
        paidOn: _paidOnFor(draft, previous, now),
        expenseDate: ExpenseDay.of(draft.expenseDate),
        supplier: _blankToNull(draft.supplier),
        fundingSource: draft.fundingSource,
        recordedById: authorId,
        recordedByName: draft.recordedByName,
        clientUpdatedAt: now.toUtc(),
      );
      final row = ExpenseLocalModel.forLocalWrite(
        expense,
        schoolId: schoolId,
        nowMs: now.millisecondsSinceEpoch,
        previous: previous,
      );
      await _writer.saveExpense(
        row: row,
        request: ExpenseSyncRequestDto(
          expense: row.toInput(),
          authorId: authorId,
        ),
        nowMs: now.millisecondsSinceEpoch,
      );
      _flush();
      return Right(row.toEntity()!);
    } catch (e) {
      return Left(StorageFailure('Dépense non enregistrée : $e'));
    }
  }

  @override
  Future<Either<Failure, Expense>> setStatus(
    Expense expense,
    ExpenseStatus status,
  ) => save(expense.toDraft().withStatus(status));

  @override
  Future<Either<Failure, Unit>> withdraw(Expense expense) =>
      _setWithdrawn(expense.id, deleted: true);

  @override
  Future<Either<Failure, Unit>> restore(Expense expense) =>
      _setWithdrawn(expense.id, deleted: false);

  Future<Either<Failure, Unit>> _setWithdrawn(
    String expenseId, {
    required bool deleted,
  }) async {
    final schoolId = _currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return const Left(StorageFailure('Aucune école'));
    final authorId = _currentUser.uid;
    if (authorId == null) return const Left(_noAgent);
    try {
      final row = await _reader.find(expenseId);
      if (row == null) return const Left(NotFoundFailure('Dépense inconnue'));
      final now = _now();
      final changedAt = now.toUtc().toIso8601String();
      final nowMs = now.millisecondsSinceEpoch;
      // Jamais acceptée par le serveur : il n'y a rien à retirer chez lui, et
      // un retrait mis en file y attendrait un numéro qui ne viendra pas. Le
      // DAO revérifie l'état dans sa transaction : accusée entre-temps, la
      // dépense repasse par la file.
      final neverAccepted =
          row.expenseNumber == null &&
          row.syncStatus == ExpenseSyncState.rejected.dbValue;
      if (neverAccepted &&
          await _writer.setLocalOnlyWithdrawal(
            expenseId: expenseId,
            deletedAt: deleted ? changedAt : null,
            nowMs: nowMs,
          )) {
        return const Right(unit);
      }
      await _writer.setWithdrawal(
        payload: ExpenseWithdrawalPayload(
          expenseId: expenseId,
          deleted: deleted,
          changedAt: changedAt,
          authorId: authorId,
        ),
        schoolId: schoolId,
        nowMs: nowMs,
      );
      _flush();
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Retrait non enregistré : $e'));
    }
  }

  /// Date de règlement (A2) : la date de la dépense si elle est **créée**
  /// payée, aujourd'hui quand elle le devient, inchangée quand elle le reste.
  static DateTime? _paidOnFor(
    ExpenseDraft draft,
    ExpenseLocalModel? previous,
    DateTime now,
  ) {
    if (draft.status != ExpenseStatus.paid) return null;
    final kept = ExpenseDay.tryParse(previous?.paidOn);
    if (previous != null &&
        previous.status == ExpenseStatus.paid.wireValue &&
        kept != null) {
      return kept;
    }
    return previous == null
        ? ExpenseDay.of(draft.expenseDate)
        : ExpenseDay.of(now);
  }

  static const _noAgent = ValidationFailure(
    'Aucun utilisateur courant : dépense non enregistrée.',
  );

  /// Le moteur ne lève jamais, et se tait hors ligne.
  void _flush() {
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
  }

  Future<DateTime?> _yearStart() async {
    try {
      return await _schoolYearStart();
    } catch (_) {
      return null;
    }
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
