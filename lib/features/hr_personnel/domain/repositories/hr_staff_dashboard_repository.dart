import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';

/// Le tableau de bord du personnel — **100 % serveur** : chiffres, liste et
/// PDF sur les mêmes critères. Pas de photo hors ligne : une vieille page se
/// lirait comme la liste du jour. Le Fichier du personnel, lui, reste local.
abstract class HrStaffDashboardRepository {
  Future<Either<Failure, HrStaffStats>> stats();

  /// [page] à partir de 0.
  Future<Either<Failure, HrStaffMembersPage>> members(
    HrRosterQuery query, {
    required int page,
  });

  /// Les agents de [query], **tous** : ni page ni taille.
  Future<Either<Failure, HrStaffListReport>> report(HrRosterQuery query);
}
