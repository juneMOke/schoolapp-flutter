import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/attendance_summary_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_calendar_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_share_trace_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/staff_pay_profile_dao.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_disbursement_regularizer.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_pull_repository_impl.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fact_outbox_handlers.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_lww_outbox_handlers.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_pull_repository.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_pull_handlers.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// La Paie du personnel (RH, sous-module C). Appelé par
/// `registerStaffOffline`, qui a déjà posé le fichier du personnel et le
/// Pointage dont elle lit les agents et les contrats.
void registerPayroll(GetIt getIt) {
  _registerStorage(getIt);
  _registerPulls(getIt);
  _registerPushes(getIt);
}

void _registerStorage(GetIt getIt) {
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

/// Cinq flux, tous sous `hr.pay.read` : le plan ne les annonce qu'à qui peut
/// lire un montant.
void _registerPulls(GetIt getIt) {
  getIt.registerLazySingleton<PayrollPullRepository>(
    () => PayrollPullRepositoryImpl(
      api: getIt<PayrollSyncApi>(),
      runner: KeysetPullRunner(getIt<SyncMetaDao>()),
      payrolls: getIt<PayrollDao>(),
      profiles: getIt<StaffPayProfileDao>(),
      summaries: getIt<AttendanceSummaryDao>(),
      advances: getIt<SalaryAdvanceDao>(),
      disbursements: getIt<PayrollDisbursementDao>(),
      currentUser: getIt<CurrentUserContext>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
      regularizer: PayrollDisbursementRegularizer(
        payrolls: getIt<PayrollDao>(),
        disbursements: getIt<PayrollDisbursementDao>(),
      ),
    ),
  );
  final coordinator = getIt<PullCoordinator>();
  final pulls = getIt<PayrollPullRepository>();
  const read = [Perm.hrPayRead];
  coordinator
    ..registerHandler(
      StaffPullHandler.of(kPayrollsResource, read, pulls.syncPayrolls),
    )
    ..registerHandler(
      StaffPullHandler.of(kStaffPayProfilesResource, read, pulls.syncProfiles),
    )
    ..registerHandler(
      StaffPullHandler.of(
        kStaffAttendanceSummariesResource,
        read,
        pulls.syncAttendanceSummaries,
      ),
    )
    ..registerHandler(
      StaffPullHandler.of(kSalaryAdvancesResource, read, pulls.syncAdvances),
    )
    ..registerHandler(
      StaffPullHandler.of(
        kPayrollDisbursementsResource,
        read,
        pulls.syncDisbursements,
      ),
    );
}

/// Huit remontées. L'ordre par mois, par ligne et par avance est tenu par les
/// handlers eux-mêmes (`OutboxDao.hasOlderPending`).
void _registerPushes(GetIt getIt) {
  final engine = getIt<SyncEngine>();
  final api = getIt<PayrollSyncApi>();
  final outbox = OutboxDao(getIt<Database>());
  final currentUser = getIt<CurrentUserContext>();
  final extras = getIt<Map<String, dynamic>>();
  engine
    ..registerHandler(
      PayrollSettingsOutboxHandler(
        api: api,
        dao: getIt<PayrollSettingsDao>(),
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      StaffPayProfileOutboxHandler(
        api: api,
        dao: getIt<StaffPayProfileDao>(),
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      PayrollVariablesOutboxHandler(
        api: api,
        dao: getIt<PayrollVariablesDao>(),
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      PayrollGestureOutboxHandler(
        api: api,
        gestures: getIt<PayrollGestureDao>(),
        payrolls: getIt<PayrollDao>(),
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      SalaryAdvanceOutboxHandler(
        api: api,
        dao: getIt<SalaryAdvanceDao>(),
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      PayrollCancellationOutboxHandler.advance(
        store: getIt<SalaryAdvanceDao>().cancellations,
        sender: api.cancelAdvance,
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      PayrollDisbursementOutboxHandler(
        api: api,
        dao: getIt<PayrollDisbursementDao>(),
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    )
    ..registerHandler(
      PayrollCancellationOutboxHandler.disbursement(
        store: getIt<PayrollDisbursementDao>().cancellations,
        sender: api.cancelDisbursement,
        outbox: outbox,
        currentUser: currentUser,
        extras: extras,
      ),
    );
}
