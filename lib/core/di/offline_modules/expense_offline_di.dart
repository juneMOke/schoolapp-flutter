import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/money/exchange_rate_reader.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_pull_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_pull_handler.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_withdrawal_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_pull_repository.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/load_expense_register_use_case.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/sync_expense_pulls_use_case.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Registrar du module **Dépenses** — le registre des frais de
/// fonctionnement. Appelé depuis `registerOfflineModules`.
///
/// **Aucune frontière franchie.** Le pull du socle (`enrollment`) remplit
/// `ref_expense_types` par un seam qui résout [ExpenseTypeDao] paresseusement ;
/// le module ne dépend d'aucun autre module métier — la lecture du taux passe
/// par le socle (`ExchangeRateReader`), la rentrée par le contexte académique.
void registerExpenseOffline(GetIt getIt) {
  getIt.registerLazySingleton<ExpenseTypeDao>(
    () => ExpenseTypeDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ExpenseReadDao>(
    () => ExpenseReadDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ExpenseWriteDao>(
    () => ExpenseWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ExpenseSyncDao>(
    () => ExpenseSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ExpenseSyncApi>(
    () => ExpenseSyncApi(getIt<Dio>()),
  );

  // ── Registre local ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      reader: getIt<ExpenseReadDao>(),
      writer: getIt<ExpenseWriteDao>(),
      types: getIt<ExpenseTypeDao>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      rates: getIt<ExchangeRateReader>(),
      // Résolue À CHAQUE lecture, jamais capturée : une rentrée figée au
      // montage survivrait au changement d'année.
      schoolYearStart: () async =>
          (await getIt<AcademicYearContextRepository>().loadCurrentContext())
              .fold((_) => null, (context) => context.academicYear.startDate),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadExpenseRegisterUseCase>(
    () => LoadExpenseRegisterUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<SaveExpenseUseCase>(
    () => SaveExpenseUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<SetExpenseStatusUseCase>(
    () => SetExpenseStatusUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<WithdrawExpenseUseCase>(
    () => WithdrawExpenseUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<RestoreExpenseUseCase>(
    () => RestoreExpenseUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<SyncExpensePullsUseCase>(
    () => SyncExpensePullsUseCase(getIt<PullCoordinator>()),
  );

  // ── Descente ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ExpensePullRepository>(
    () => ExpensePullRepositoryImpl(
      api: getIt<ExpenseSyncApi>(),
      dao: getIt<ExpenseSyncDao>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      currentUser: getIt<CurrentUserContext>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    ExpensePullHandler(getIt<ExpensePullRepository>()),
  );

  // ── Remontée → SyncEngine ───────────────────────────────────────────────
  getIt<SyncEngine>().registerHandler(
    ExpenseOutboxHandler(
      api: getIt<ExpenseSyncApi>(),
      dao: getIt<ExpenseSyncDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  getIt<SyncEngine>().registerHandler(
    ExpenseWithdrawalOutboxHandler(
      api: getIt<ExpenseSyncApi>(),
      reader: getIt<ExpenseReadDao>(),
      writer: getIt<ExpenseWriteDao>(),
      dao: getIt<ExpenseSyncDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
}
