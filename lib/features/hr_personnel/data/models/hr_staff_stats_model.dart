import 'package:school_app_flutter/features/hr_personnel/data/models/hr_staff_dashboard_wire.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';

/// Miroir de `StaffStatsDto` (`GET /hr/staff-stats`).
///
/// Strict sur ce qui fait les chiffres : un compteur manquant fait échouer la
/// lecture plutôt que d'afficher un zéro qui n'a pas été compté.
abstract final class HrStaffStatsModel {
  static HrStaffStats fromJson(Map<String, dynamic> json) {
    final seniority = json['seniority'] as Map<String, dynamic>;
    final dean = json['dean'] as Map<String, dynamic>?;
    return HrStaffStats(
      asOf: json['asOf'] as String,
      headcount: (json['headcount'] as num).toInt(),
      sexes: _split(json['sexes'] as Map<String, dynamic>),
      averageSeniority: (seniority['average'] as num?)?.toDouble(),
      seniorityBase: (seniority['base'] as num).toInt(),
      dean: dean == null
          ? null
          : HrDean(
              staffMemberId: dean['staffMemberId'] as String,
              lastName: dean['lastName'] as String,
              middleName: dean['middleName'] as String?,
              firstName: dean['firstName'] as String?,
              entryDate: dean['entryDate'] as String,
              years: (dean['years'] as num).toInt(),
            ),
      categories: [
        for (final raw in json['categories'] as List<dynamic>)
          HrCategoryCount(
            key: HrStaffDashboardWire.categoryOf(
              (raw as Map<String, dynamic>)['category'],
            ),
            split: _split(raw),
          ),
      ],
    );
  }

  static HrSexSplit _split(Map<String, dynamic> json) => HrSexSplit(
    women: (json['women'] as num).toInt(),
    men: (json['men'] as num).toInt(),
    unknown: (json['unknown'] as num).toInt(),
  );
}
