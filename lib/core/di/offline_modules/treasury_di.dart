import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/treasury/data/local/cash_pending_probe_sql.dart';
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
/// configuration et de clôture : ni table locale, ni outbox. La clôture lit
/// seulement les files d'envoi des autres modules, pour attendre qu'elles
/// soient vides (D2).
void registerTreasury(GetIt getIt) {
  getIt.registerLazySingleton<CashRegistersRepository>(
    () => CashRegistersRepositoryImpl(
      CashRegistersApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
    ),
  );

  getIt
    ..registerLazySingleton<TreasuryDayRepository>(
      () => TreasuryDayRepositoryImpl(
        TreasuryDayApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
      ),
    )
    // Ce que la tablette n'a pas encore envoyé : la clôture attend (D2).
    ..registerLazySingleton<CashPendingProbe>(
      () => CashPendingProbeSql(getIt<Database>()),
    );

  // ── Écrans : cubits en fabrique, jamais singleton ──
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
