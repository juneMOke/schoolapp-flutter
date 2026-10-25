import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_advance_guard.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_expense_advance_guard.dart';
import 'package:school_app_flutter/core/di/offline_modules/payroll_sync_di.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/payroll/data/local/attendance_summary_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_calendar_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_advance_request_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_arrears_priority_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_payout_policy_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_share_trace_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/staff_pay_profile_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_local.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_snapshot_reader.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payslip_repository_impl.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payslip_api.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_pull_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/find_expense_use_case.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_advance_request_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_arrears_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_settings_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_commands.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_expense_advance_bridge.dart';
import 'package:school_app_flutter/features/expense/presentation/bridge/expense_staff_advance_bridge.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// La Paie du personnel (RH, sous-module C). Appelé par
/// `registerStaffOffline`, qui a déjà posé le fichier du personnel et le
/// Pointage dont elle lit les agents et les contrats.
void registerPayroll(GetIt getIt) {
  _registerStorage(getIt);
  registerPayrollSync(getIt);
  _registerDomain(getIt);
  _registerPresentation(getIt);
}

/// Le cubit de l'écran (factory : un par page), ses gestes et ses signaux.
void _registerPresentation(GetIt getIt) {
  getIt.registerFactory<PayrollCommands>(
    () => PayrollCommands(
      variables: getIt<SavePayrollVariablesUseCase>(),
      payoutPolicy: getIt<SavePayrollPayoutPolicyUseCase>(),
      payArrears: getIt<PayPayrollArrearsUseCase>(),
      priority: getIt<SetPayrollArrearsPriorityUseCase>(),
      request: RequestSalaryAdvanceUseCase(getIt<SaveExpenseUseCase>()),
      decide: DecideSalaryAdvanceUseCase(
        getIt<FindExpenseUseCase>(),
        getIt<ApplyExpenseGestureUseCase>(),
      ),
      gesture: getIt<RecordPayrollGestureUseCase>(),
      disburse: getIt<DisbursePayrollUseCase>(),
      cancelDisbursement: getIt<CancelPayrollDisbursementUseCase>(),
      grant: getIt<GrantSalaryAdvanceUseCase>(),
      cancelAdvance: getIt<CancelSalaryAdvanceUseCase>(),
      profile: getIt<SaveStaffPayProfileUseCase>(),
      settings: getIt<SavePayrollSettingsUseCase>(),
      share: getIt<RecordPayslipShareUseCase>(),
      payslip: getIt<FetchPayslipUseCase>(),
    ),
  );
  // Dépenses ▸ Nouvelle demande → formulaire d'avance de la Paie.
  getIt.registerFactory<ExpenseStaffAdvanceBridge>(
    () => PayrollExpenseAdvanceBridge(
      load: getIt<LoadPayrollUseCase>(),
      commands: () => getIt<PayrollCommands>(),
    ),
  );
  getIt.registerFactory<PayrollCubit>(
    () => PayrollCubit(
      load: getIt<LoadPayrollUseCase>(),
      signals: StaffSyncSignals(
        pulls: SyncStaffPullsUseCase(
          getIt<PullCoordinator>(),
          resources: kPayrollScreenResources,
        ),
        bus: getIt<PullCompletionBus>(),
        engine: getIt<SyncEngine>(),
      ),
      commands: getIt<PayrollCommands>(),
    ),
  );
}

/// Le dépôt et les cas d'usage. Les BLoC de la paie sont posés en factory par
/// `registerPayrollPresentation`.
void _registerDomain(GetIt getIt) {
  getIt.registerLazySingleton<PayrollLocal>(
    () => PayrollLocal(
      settings: getIt<PayrollSettingsDao>(),
      profiles: getIt<StaffPayProfileDao>(),
      payrolls: getIt<PayrollDao>(),
      variables: getIt<PayrollVariablesDao>(),
      payoutPolicies: getIt<PayrollPayoutPolicyDao>(),
      arrearsPriorities: getIt<PayrollArrearsPriorityDao>(),
      advanceRequests: PayrollAdvanceRequestDao(getIt<Database>()),
      gestures: getIt<PayrollGestureDao>(),
      summaries: getIt<AttendanceSummaryDao>(),
      advances: getIt<SalaryAdvanceDao>(),
      disbursements: getIt<PayrollDisbursementDao>(),
      shares: getIt<PayrollShareTraceDao>(),
      calendar: getIt<PayrollCalendarDao>(),
    ),
  );
  getIt.registerLazySingleton<PayrollRepository>(
    () => PayrollRepositoryImpl(
      reader: PayrollSnapshotReader(
        staff: getIt<StaffRepository>(),
        contracts: getIt<StaffContractDao>(),
        local: getIt<PayrollLocal>(),
        school: getIt.isRegistered<SchoolRepository>()
            ? getIt<SchoolRepository>()
            : null,
      ),
      local: getIt<PayrollLocal>(),
      writer: StaffLocalWriter(
        currentUser: getIt<CurrentUserContext>(),
        syncEngine: getIt<SyncEngine>(),
      ),
      ids: getIt<IdGenerator>(),
    ),
  );
  getIt.registerLazySingleton<PayslipApi>(() => PayslipApi(getIt<Dio>()));
  getIt.registerLazySingleton<PayslipRepository>(
    () => PayslipRepositoryImpl(
      api: getIt<PayslipApi>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  PayrollRepository repository() => getIt<PayrollRepository>();
  getIt
    ..registerFactory(() => LoadPayrollUseCase(repository()))
    ..registerFactory(() => FetchPayslipUseCase(getIt<PayslipRepository>()))
    ..registerFactory(() => RecordPayslipShareUseCase(repository()))
    ..registerFactory(() => SavePayrollVariablesUseCase(repository()))
    ..registerFactory(() => SavePayrollPayoutPolicyUseCase(repository()))
    ..registerFactory(() => PayPayrollArrearsUseCase(repository()))
    ..registerFactory(() => SetPayrollArrearsPriorityUseCase(repository()))
    ..registerFactory(() => RecordPayrollGestureUseCase(repository()))
    ..registerFactory(() => GrantSalaryAdvanceUseCase(repository()))
    ..registerFactory(() => CancelSalaryAdvanceUseCase(repository()))
    ..registerFactory(() => DisbursePayrollUseCase(repository()))
    ..registerFactory(() => CancelPayrollDisbursementUseCase(repository()))
    ..registerFactory(() => SaveStaffPayProfileUseCase(repository()))
    ..registerFactory(() => SavePayrollSettingsUseCase(repository()));
}

void _registerStorage(GetIt getIt) {
  // Le port des Dépenses (B6) : réouverture et première retenue d'une avance.
  getIt.registerLazySingleton<ExpenseAdvanceGuard>(
    () => PayrollExpenseAdvanceGuard(
      payrolls: getIt<PayrollDao>(),
      advances: getIt<SalaryAdvanceDao>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<PayrollSettingsDao>(
    () => PayrollSettingsDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffPayProfileDao>(
    () => StaffPayProfileDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollDao>(() => PayrollDao(getIt<Database>()));
  getIt.registerLazySingleton<PayrollVariablesDao>(
    () => PayrollVariablesDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollArrearsPriorityDao>(
    () => PayrollArrearsPriorityDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollPayoutPolicyDao>(
    () => PayrollPayoutPolicyDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollGestureDao>(
    () => PayrollGestureDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceSummaryDao>(
    () => AttendanceSummaryDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<SalaryAdvanceDao>(
    () => SalaryAdvanceDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollDisbursementDao>(
    () => PayrollDisbursementDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollShareTraceDao>(
    () => PayrollShareTraceDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollCalendarDao>(
    () => PayrollCalendarDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<PayrollSyncApi>(
    () => PayrollSyncApi(getIt<Dio>()),
  );
}
