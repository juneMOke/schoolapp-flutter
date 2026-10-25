import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/hr_presence/data/hr_attendance_report_mapper.dart';
import 'package:school_app_flutter/features/hr_presence/data/hr_attendance_stats_api.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_agent_model.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_dashboard_model.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_json.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_profiles_model.dart';
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_recap_model.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';
import 'package:school_app_flutter/features/hr_presence/domain/repositories/hr_attendance_stats_repository.dart';

/// Les statistiques de présence : le serveur, et lui seul. Hors ligne,
/// l'erreur réseau s'affiche — aucune photo locale ne la masque, sinon le
/// papier divergerait de l'écran.
class HrAttendanceStatsRepositoryImpl implements HrAttendanceStatsRepository {
  final HrAttendanceStatsApi _api;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _requiredAuth;

  const HrAttendanceStatsRepositoryImpl({
    required HrAttendanceStatsApi api,
    required ConnectivityService connectivity,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _connectivity = connectivity,
       _requiredAuth = requiredAuth;

  @override
  Future<Either<Failure, HrAttendanceDashboard>> dashboard(
    DashboardWindow window,
  ) => _read(
    () async => HrAttendanceDashboardModel.fromJson(
      HrAttendanceJson.map(
        await _api.getDashboard(
          _requiredAuth,
          _day(window.from),
          _day(window.to),
        ),
      ),
    ),
  );

  @override
  Future<Either<Failure, HrAttendanceAgentMonth>> agentMonth(
    String staffMemberId, {
    required String month,
  }) => _read(
    () async => HrAttendanceAgentModel.monthFromJson(
      HrAttendanceJson.map(
        await _api.getAgentMonth(_requiredAuth, staffMemberId, month),
      ),
    ),
  );

  @override
  Future<Either<Failure, HrAttendanceAgentYear>> agentYear(
    String staffMemberId,
  ) => _read(
    () async => HrAttendanceAgentModel.yearFromJson(
      HrAttendanceJson.map(
        await _api.getAgentYear(_requiredAuth, staffMemberId),
      ),
    ),
  );

  @override
  Future<Either<Failure, HrAttendanceProfiles>> profiles(
    HrProfileScope scope,
  ) => _read(
    () async => HrAttendanceProfilesModel.fromJson(
      HrAttendanceJson.map(
        await _api.getProfiles(
          _requiredAuth,
          scope.month,
          scope.isYear ? AppConstants.hrAttendanceProfilesYearScope : null,
        ),
      ),
    ),
  );

  @override
  Future<Either<Failure, HrAttendanceRecap>> recap(String month) => _read(
    () async => HrAttendanceRecapModel.fromJson(
      HrAttendanceJson.map(await _api.getRecap(_requiredAuth, month)),
    ),
  );

  @override
  Future<Either<Failure, HrAttendanceReport>> report(
    DashboardWindow window, {
    String search = '',
  }) async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Aucune connexion.'));
    }
    final trimmed = search.trim();
    try {
      final response = await _api.getReport(
        _requiredAuth,
        _day(window.from),
        _day(window.to),
        // Une recherche blanche ne part pas : le PDF couvre tout le monde.
        trimmed.isEmpty ? null : trimmed,
        // Le délai de guichet expirerait pendant le rendu, et l'appel suivant
        // tomberait sur le 429 d'un rendu qu'on croirait abandonné.
        Options(receiveTimeout: AppConstants.hrAttendanceReportTimeout),
      );
      return HrAttendanceReportMapper.map(response);
    } on DioException catch (e) {
      // Le message du serveur porte l'information utile (429, 400) et
      // l'intercepteur l'écrase.
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Rien à réconcilier : la pièce n'est pas archivée, elle se redemande.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  /// `AAAA-MM-JJ` d'une borne : un jour civil, sans heure ni fuseau.
  static String _day(DateTime day) => SchoolDayCalendar.dayOf(day);

  Future<Either<Failure, T>> _read<T>(Future<T> Function() call) async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Aucune connexion.'));
    }
    try {
      return Right(await call());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return e.response == null
          ? const Left(NetworkFailure('Network error occurred'))
          : const Left(ServerFailure('Unexpected response'));
    } catch (_) {
      // Une réponse illisible est une erreur, pas un tableau de bord vide.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
