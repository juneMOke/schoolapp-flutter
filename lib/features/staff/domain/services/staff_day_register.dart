import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';

/// Une ligne du registre du jour : l'agent, son pointage (ou aucun) et s'il
/// est vacataire payé à l'heure ce jour-là.
class StaffDayRow extends Equatable {
  final StaffMember member;

  /// Le jour du registre, `YYYY-MM-DD`.
  final String day;
  final StaffAttendanceRecord? record;
  final bool isHourly;

  const StaffDayRow({
    required this.member,
    required this.day,
    required this.record,
    required this.isHourly,
  });

  StaffAttendanceStatus get status =>
      record?.status ?? StaffAttendanceStatus.none;

  /// Où en est le pointage ; « au serveur » quand il n'y en a pas.
  StaffSyncState get sync => record?.syncState ?? StaffSyncState.synced;

  @override
  List<Object?> get props => [member, day, record, isHourly];
}

/// Les critères du registre : un statut (ou tous), une catégorie, un texte.
class StaffDayQuery extends Equatable {
  /// `null` = tous les statuts.
  final StaffAttendanceStatus? status;
  final StaffCategory? category;
  final String text;

  const StaffDayQuery({this.status, this.category, this.text = ''});

  static const StaffDayQuery none = StaffDayQuery();

  StaffDayQuery withStatus(StaffAttendanceStatus? value) =>
      StaffDayQuery(status: value, category: category, text: text);

  StaffDayQuery withCategory(StaffCategory? value) =>
      StaffDayQuery(status: status, category: value, text: text);

  StaffDayQuery withText(String value) =>
      StaffDayQuery(status: status, category: category, text: value);

  bool accepts(StaffDayRow row) =>
      (status == null || row.status == status) &&
      (category == null || row.member.category == category) &&
      StaffMemberSearch.matches(row.member, text);

  @override
  List<Object?> get props => [status, category, text];
}

/// Ce que montre le registre d'un jour. Calcul pur, refait à chaque filtre.
class StaffDayRegister extends Equatable {
  final String day;

  /// Tous les agents, filtres ignorés.
  final List<StaffDayRow> all;

  /// Ceux qui passent les filtres.
  final List<StaffDayRow> rows;

  /// Effectif par statut, sur tout le registre.
  final Map<StaffAttendanceStatus, int> byStatus;

  /// Pointages écrits sur la tablette, pas encore au serveur.
  final int pending;

  /// Retards et absences sans justification.
  final int toJustify;

  /// Le rapport du jour est validé, ou le mois clos : rien ne s'écrit.
  final bool frozen;

  const StaffDayRegister({
    required this.day,
    required this.all,
    required this.rows,
    required this.byStatus,
    required this.pending,
    required this.toJustify,
    required this.frozen,
  });

  factory StaffDayRegister.build(
    StaffAttendanceSnapshot snapshot, {
    required String day,
    required StaffDayQuery query,
  }) {
    final all = [
      for (final member in snapshot.members)
        StaffDayRow(
          member: member,
          day: day,
          record: snapshot.recordOf(member.id, day),
          isHourly:
              StaffContractTimeline.currentAt(
                member.contracts,
                day,
              )?.isHourlyVacataire ??
              false,
        ),
    ];
    return StaffDayRegister(
      day: day,
      all: all,
      rows: [
        for (final row in all)
          if (query.accepts(row)) row,
      ],
      byStatus: {
        for (final status in StaffAttendanceStatus.values)
          status: all.where((row) => row.status == status).length,
      },
      pending: all.where((row) => row.sync != StaffSyncState.synced).length,
      toJustify: all
          .where((row) => row.record?.needsJustification ?? false)
          .length,
      frozen: snapshot.isDayFrozen(day),
    );
  }

  int count(StaffAttendanceStatus status) => byStatus[status] ?? 0;

  int get marked => all.length - count(StaffAttendanceStatus.none);

  /// Les agents encore « à pointer ».
  List<StaffDayRow> get unmarked => [
    for (final row in all)
      if (row.status == StaffAttendanceStatus.none) row,
  ];

  /// La liste filtrée contient-elle un vacataire à l'heure ? La colonne des
  /// heures n'apparaît qu'alors.
  bool get showsHours => rows.any((row) => row.isHourly);

  bool get isEmpty => all.isEmpty;

  bool get isFilteredEmpty => all.isNotEmpty && rows.isEmpty;

  @override
  List<Object?> get props => [
    day,
    all,
    rows,
    byStatus,
    pending,
    toJustify,
    frozen,
  ];
}
