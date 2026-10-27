import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';

enum HrPresenceFicheStatus { loading, ready, failure }

const Object _undefined = Object();

/// Ce que l'adresse d'une fiche donne à son cubit.
typedef HrPresenceFicheArgs = ({
  String agentId,
  bool yearly,
  String? month,
  DateTime? yearStart,
});

/// Ce que la tablette sait de la portée affichée, pour le PDF de la fiche :
/// le mois est-il clos (la pièce sera scellée), et combien de pointages de
/// l'agent n'ont pas encore été envoyés (le serveur ne les comptera pas).
typedef HrPresenceSheetLocal = ({bool monthClosed, int unsent});

class HrPresenceFicheState extends Equatable {
  final String agentId;
  final bool yearly;

  /// `AAAA-MM` de la vue mensuelle — gardé en vue annuelle.
  final String month;
  final String currentMonth;
  final String? firstMonth;
  final HrPresenceFicheStatus status;
  final HrAttendanceAgentMonth? monthData;
  final HrAttendanceAgentYear? yearData;
  final Failure? failure;
  final List<StaffMember> members;

  /// Les jours corrigés depuis la fiche et pas encore relus du serveur :
  /// la ligne de la tablette (`null` : remise « à pointer »). Le calendrier
  /// les montre ; les taux, eux, attendent le serveur.
  final Map<String, StaffAttendanceRecord?> localDays;

  /// `null` : pas encore lu, ou illisible — le bouton PDF reste offert, sans
  /// avertissement.
  final HrPresenceSheetLocal? local;

  const HrPresenceFicheState({
    required this.agentId,
    required this.month,
    required this.currentMonth,
    this.yearly = false,
    this.firstMonth,
    this.status = HrPresenceFicheStatus.loading,
    this.monthData,
    this.yearData,
    this.failure,
    this.members = const [],
    this.localDays = const {},
    this.local,
  });

  bool get isCurrentMonth => month == currentMonth;

  bool get canStepBack {
    final first = firstMonth;
    return first == null || month.compareTo(first) > 0;
  }

  HrPresenceFicheState copyWith({
    String? agentId,
    bool? yearly,
    String? month,
    HrPresenceFicheStatus? status,
    Object? monthData = _undefined,
    Object? yearData = _undefined,
    Object? failure = _undefined,
    List<StaffMember>? members,
    Map<String, StaffAttendanceRecord?>? localDays,
    Object? local = _undefined,
  }) => HrPresenceFicheState(
    agentId: agentId ?? this.agentId,
    yearly: yearly ?? this.yearly,
    month: month ?? this.month,
    currentMonth: currentMonth,
    firstMonth: firstMonth,
    status: status ?? this.status,
    monthData: identical(monthData, _undefined)
        ? this.monthData
        : monthData as HrAttendanceAgentMonth?,
    yearData: identical(yearData, _undefined)
        ? this.yearData
        : yearData as HrAttendanceAgentYear?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    members: members ?? this.members,
    localDays: localDays ?? this.localDays,
    local: identical(local, _undefined)
        ? this.local
        : local as HrPresenceSheetLocal?,
  );

  @override
  List<Object?> get props => [
    agentId,
    yearly,
    month,
    currentMonth,
    firstMonth,
    status,
    monthData,
    yearData,
    failure,
    members,
    localDays,
    local,
  ];
}
