import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/hr_personnel/data/hr_staff_dashboard_api.dart';
import 'package:school_app_flutter/features/hr_personnel/data/hr_staff_list_report_mapper.dart';
import 'package:school_app_flutter/features/hr_personnel/data/models/hr_staff_dashboard_wire.dart';
import 'package:school_app_flutter/features/hr_personnel/data/models/hr_staff_members_page_model.dart';
import 'package:school_app_flutter/features/hr_personnel/data/models/hr_staff_stats_model.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/repositories/hr_staff_dashboard_repository.dart';

/// Le tableau de bord du personnel : le serveur, et lui seul. Hors ligne,
/// l'erreur réseau s'affiche — aucune photo ne la masque.
class HrStaffDashboardRepositoryImpl implements HrStaffDashboardRepository {
  final HrStaffDashboardApi _api;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _requiredAuth;

  const HrStaffDashboardRepositoryImpl({
    required HrStaffDashboardApi api,
    required ConnectivityService connectivity,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _connectivity = connectivity,
       _requiredAuth = requiredAuth;

  @override
  Future<Either<Failure, HrStaffStats>> stats() => _read(
    () async => HrStaffStatsModel.fromJson(
      await _api.getStats(_requiredAuth) as Map<String, dynamic>,
    ),
  );

  @override
  Future<Either<Failure, HrStaffMembersPage>> members(
    HrRosterQuery query, {
    required int page,
  }) => _read(
    () async => HrStaffMembersPageModel.fromJson(
      await _api.getMembers(
            _requiredAuth,
            HrStaffDashboardWire.search(query.text),
            HrStaffDashboardWire.category(query.category),
            HrStaffDashboardWire.sort(query.sort),
            page,
            AppConstants.hrStaffMembersPageSize,
          )
          as Map<String, dynamic>,
    ),
  );

  @override
  Future<Either<Failure, HrStaffListReport>> report(HrRosterQuery query) async {
    try {
      final response = await _api.getMembersReport(
        _requiredAuth,
        HrStaffDashboardWire.search(query.text),
        HrStaffDashboardWire.category(query.category),
        HrStaffDashboardWire.sort(query.sort),
        // Le délai de guichet expirerait pendant le rendu, et l'appel suivant
        // tomberait sur le 429 d'un rendu qu'on croirait abandonné.
        Options(receiveTimeout: AppConstants.hrStaffListReportTimeout),
      );
      return HrStaffListReportMapper.map(response);
    } on DioException catch (e) {
      // Le message du serveur porte l'information utile — le compte réel
      // d'agents sur le 400 du plafond — et l'intercepteur l'écrase.
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Rien à réconcilier : la pièce n'est pas archivée, elle se redemande.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

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
