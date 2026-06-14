import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/absence_reason_stats_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/attendance_evolution_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/attendance_kpis_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/class_attendance_stat_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/stats_context_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/top_absent_class_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/weekday_absence_stat_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';

class AttendanceOverviewResponseModel {
  final StatsContextModel context;
  final AttendanceKpisModel kpis;
  final AttendanceEvolutionModel evolution;
  final List<ClassAttendanceStatModel> byClass;
  final List<TopAbsentClassModel> topAbsentClasses;
  final List<AbsenceReasonStatsModel> byAbsenceReason;
  final List<WeekdayAbsenceStatModel> byWeekday;

  const AttendanceOverviewResponseModel({
    required this.context,
    required this.kpis,
    required this.evolution,
    this.byClass = const [],
    this.topAbsentClasses = const [],
    this.byAbsenceReason = const [],
    this.byWeekday = const [],
  });

  factory AttendanceOverviewResponseModel.fromJson(Map<String, dynamic> json) {
    return AttendanceOverviewResponseModel(
      context: StatsContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      kpis: AttendanceKpisModel.fromJson(json['kpis'] as Map<String, dynamic>),
      evolution: AttendanceEvolutionModel.fromJson(
        json['evolution'] as Map<String, dynamic>,
      ),
      byClass: (json['byClass'] as List<dynamic>? ?? const [])
          .map(
            (e) => ClassAttendanceStatModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
      topAbsentClasses: (json['topAbsentClasses'] as List<dynamic>? ?? const [])
          .map((e) => TopAbsentClassModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      byAbsenceReason: (json['byAbsenceReason'] as List<dynamic>? ?? const [])
          .map(
            (e) => AbsenceReasonStatsModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
      byWeekday: (json['byWeekday'] as List<dynamic>? ?? const [])
          .map(
            (e) => WeekdayAbsenceStatModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'kpis': kpis.toJson(),
    'evolution': evolution.toJson(),
    'byClass': byClass.map((e) => e.toJson()).toList(growable: false),
    'topAbsentClasses': topAbsentClasses
        .map((e) => e.toJson())
        .toList(growable: false),
    'byAbsenceReason': byAbsenceReason
        .map((e) => e.toJson())
        .toList(growable: false),
    'byWeekday': byWeekday.map((e) => e.toJson()).toList(growable: false),
  };

  AttendanceOverview toEntity() => AttendanceOverview(
    context: context.toEntity(),
    kpis: kpis.toEntity(),
    evolution: evolution.toEntity(),
    byClass: byClass.map((e) => e.toEntity()).toList(growable: false),
    topAbsentClasses: topAbsentClasses
        .map((e) => e.toEntity())
        .toList(growable: false),
    byAbsenceReason: byAbsenceReason
        .map((e) => e.toEntity())
        .toList(growable: false),
    byWeekday: byWeekday.map((e) => e.toEntity()).toList(growable: false),
  );
}
