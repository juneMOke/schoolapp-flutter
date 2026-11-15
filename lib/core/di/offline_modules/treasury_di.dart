import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/treasury/data/online/cash_registers_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/cash_registers_repository_impl.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';

/// La trésorerie — **en ligne** pour la lecture et les gestes de
/// configuration : ni table locale, ni outbox. (La clôture, lot suivant,
/// ajoutera le flux des clôtures tiré par la synchronisation.)
void registerTreasury(GetIt getIt) {
  getIt.registerLazySingleton<CashRegistersRepository>(
    () => CashRegistersRepositoryImpl(
      CashRegistersApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
    ),
  );

  // ── Écrans : cubits en fabrique, jamais singleton ──
  getIt.registerFactory(
    () => CashRegistersCubit(getIt<CashRegistersRepository>()),
  );
}
