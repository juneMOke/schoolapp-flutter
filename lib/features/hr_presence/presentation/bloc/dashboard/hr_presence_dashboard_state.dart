import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';

enum HrPresenceDashboardStatus { loading, ready, failure }

const Object _undefined = Object();

class HrPresenceDashboardState extends Equatable {
  /// « Ce mois » par défaut (spec §1), contrairement à la Boutique.
  static const DashboardPeriod defaultPeriod = DashboardPeriod.month;

  final DashboardPeriod period;

  /// La fenêtre demandée ; `null` tant que l'écran n'a pas démarré.
  final DashboardWindow? window;
  final HrPresenceDashboardStatus status;

  /// La réponse de [window], gardée pendant une relecture silencieuse.
  final HrAttendanceDashboard? dashboard;
  final Failure? failure;

  /// La recherche de « Assiduité par agent » — filtrée sur la tablette, la
  /// route du tableau de bord n'en a pas.
  final String text;

  /// Pointages de la fenêtre encore sur la tablette : le serveur ne les
  /// compte pas encore (D1).
  final int unsynced;

  const HrPresenceDashboardState({
    this.period = defaultPeriod,
    this.window,
    this.status = HrPresenceDashboardStatus.loading,
    this.dashboard,
    this.failure,
    this.text = '',
    this.unsynced = 0,
  });

  /// Les lignes de la liste, dans l'ordre du serveur : jamais retriées.
  List<HrAttendanceStaffRow> get visibleStaff {
    final staff = dashboard?.staff ?? const <HrAttendanceStaffRow>[];
    if (text.trim().isEmpty) return staff;
    return [
      for (final row in staff)
        if (SearchNormalizationHelper.containsAllWords(
          _fields(row.agent),
          text,
        ))
          row,
    ];
  }

  static List<String?> _fields(HrAttendanceAgent agent) => [
    agent.lastName,
    agent.middleName,
    agent.firstName,
    agent.jobTitle,
  ];

  HrPresenceDashboardState copyWith({
    DashboardPeriod? period,
    Object? window = _undefined,
    HrPresenceDashboardStatus? status,
    Object? dashboard = _undefined,
    Object? failure = _undefined,
    String? text,
    int? unsynced,
  }) => HrPresenceDashboardState(
    period: period ?? this.period,
    window: identical(window, _undefined)
        ? this.window
        : window as DashboardWindow?,
    status: status ?? this.status,
    dashboard: identical(dashboard, _undefined)
        ? this.dashboard
        : dashboard as HrAttendanceDashboard?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    text: text ?? this.text,
    unsynced: unsynced ?? this.unsynced,
  );

  @override
  List<Object?> get props => [
    period,
    window,
    status,
    dashboard,
    failure,
    text,
    unsynced,
  ];
}
