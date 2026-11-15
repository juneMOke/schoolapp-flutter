import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/cash_register_lock.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/treasury/data/local/treasury_closure_dao.dart';
import 'package:school_app_flutter/features/treasury/data/sync/treasury_closure_puller.dart';
import 'package:school_app_flutter/features/treasury/data/local/cash_pending_probe_sql.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_dashboard_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_dashboard_repository_impl.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_dashboard_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_overview_cubit.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_day_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_day_repository_impl.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/treasury/data/online/cash_registers_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/cash_registers_repository_impl.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';

/// La trésorerie — **en ligne** pour la lecture et les gestes de
/// configuration et de clôture, sans outbox. Deux choses seulement vivent sur
/// la tablette : la clôture lit les files d'envoi des autres modules, pour
/// attendre qu'elles soient vides (D2), et les clôtures descendent dans
/// `treasury_closures`, pour que la tablette cesse d'encaisser en espèces une
/// devise close aujourd'hui (R11).
void registerTreasury(GetIt getIt) {
  getIt.registerLazySingleton<CashRegistersRepository>(
    () => CashRegistersRepositoryImpl(
      CashRegistersApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
    ),
  );

  // Les clôtures descendues (`treasury.closures`) : le verrou des
  // encaissements en espèces d'une devise close aujourd'hui (R11), lu par
  // l'encaissement, la correction d'un versement et la boutique.
  getIt
    ..registerLazySingleton<TreasuryClosureDao>(
      () => TreasuryClosureDao(getIt<Database>(), getIt<CurrentUserContext>()),
    )
    ..registerLazySingleton<CashRegisterLock>(
      () => getIt<TreasuryClosureDao>(),
    );
  getIt<PullCoordinator>().registerHandler(
    TreasuryClosurePullHandler(
      TreasuryClosurePuller(
        dio: getIt<Dio>(),
        runner: KeysetPullRunner(getIt<SyncMetaDao>()),
        dao: getIt<TreasuryClosureDao>(),
        currentUser: getIt<CurrentUserContext>(),
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    ),
  );

  getIt
    ..registerLazySingleton<TreasuryDayRepository>(
      () => TreasuryDayRepositoryImpl(
        TreasuryDayApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
        closures: getIt<TreasuryClosureDao>(),
      ),
    )
    // Ce que la tablette n'a pas encore envoyé : la clôture attend (D2).
    ..registerLazySingleton<CashPendingProbe>(
      () => CashPendingProbeSql(getIt<Database>()),
    );

  getIt.registerLazySingleton<TreasuryDashboardRepository>(
    () => TreasuryDashboardRepositoryImpl(
      TreasuryDashboardApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
    ),
  );

  // ── Écrans : cubits en fabrique, jamais singleton ──
  getIt.registerFactory(
    () => TreasuryOverviewCubit(getIt<TreasuryDashboardRepository>()),
  );
  getIt
    ..registerFactory(
      () => CashRegistersCubit(getIt<CashRegistersRepository>()),
    )
    // Le premier chargement vise le jour de l'école ; la réponse donne
    // ensuite le « aujourd'hui » du serveur, qui fait foi.
    ..registerFactory(
      () => CashClosingCubit(
        getIt<TreasuryDayRepository>(),
        getIt<CashPendingProbe>(),
        initialDate: SchoolTime.today(DateTime.now()),
      ),
    );
}
