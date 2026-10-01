import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_ledger.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_stats.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une ligne du récapitulatif : l'agent, son contrat du mois, sa synthèse et
/// où en est la synchronisation de ses pointages.
class StaffRecapRow extends Equatable {
  final StaffMember member;
  final StaffContractKind? kind;
  final StaffMonthStats stats;
  final RecordSyncState sync;

  const StaffRecapRow({
    required this.member,
    required this.kind,
    required this.stats,
    required this.sync,
  });

  @override
  List<Object?> get props => [member, kind, stats, sync];
}

/// Les critères du récapitulatif : un contrat (ou tous) et un texte.
class StaffRecapQuery extends Equatable {
  final StaffContractFilter? contract;
  final String text;

  const StaffRecapQuery({this.contract, this.text = ''});

  static const StaffRecapQuery none = StaffRecapQuery();

  /// Un second tap sur le filtre actif le retire.
  StaffRecapQuery toggleContract(StaffContractFilter? value) =>
      StaffRecapQuery(contract: value == contract ? null : value, text: text);

  StaffRecapQuery withText(String value) =>
      StaffRecapQuery(contract: contract, text: value);

  bool accepts(StaffRecapRow row) =>
      (contract == null || contract!.matches(row.kind)) &&
      StaffMemberSearch.matches(row.member, text);

  @override
  List<Object?> get props => [contract, text];
}

/// Le récapitulatif d'un mois : lignes, compteurs et totaux transmis à la
/// clôture.
class StaffMonthRecap extends Equatable {
  final StaffMonthLedger ledger;
  final List<StaffRecapRow> all;
  final List<StaffRecapRow> rows;
  final Map<StaffContractFilter, int> byContract;

  const StaffMonthRecap._({
    required this.ledger,
    required this.all,
    required this.rows,
    required this.byContract,
  });

  factory StaffMonthRecap.build(
    StaffAttendanceSnapshot snapshot, {
    required String month,
    required String today,
    required StaffRecapQuery query,
  }) {
    final ledger = StaffMonthLedger.of(snapshot, month: month, today: today);
    final all = [
      for (final member in snapshot.members)
        StaffRecapRow(
          member: member,
          kind: ledger.periodOf(member)?.kind,
          stats: ledger.statsOf(member),
          sync: _worstSync(snapshot, member.id, month),
        ),
    ];
    return StaffMonthRecap._(
      ledger: ledger,
      all: all,
      rows: [
        for (final row in all)
          if (query.accepts(row)) row,
      ],
      byContract: {
        for (final filter in StaffContractFilter.values)
          filter: all.where((row) => filter.matches(row.kind)).length,
      },
    );
  }

  bool get isEmpty => all.isEmpty;

  bool get isFilteredEmpty => all.isNotEmpty && rows.isEmpty;

  /// Présences sur jours ouvrés, hors vacataires à l'heure ; `null` sans
  /// jour ouvré.
  double? get presenceRate {
    final counted = all.where((row) => !row.stats.isHourly);
    final days = counted.fold<int>(0, (sum, row) => sum + row.stats.workDays);
    if (days == 0) return null;
    return counted.fold<int>(0, (sum, row) => sum + row.stats.present) / days;
  }

  int get workedMinutes => _sum((stats) => stats.workedMinutes);
  int get lateMinutes => _sum((stats) => stats.lateMinutes);
  int get absentUnjustified => _sum((stats) => stats.absentUnjustified);
  int get notMarked => _sum((stats) => stats.notMarked);

  /// Montant des vacations, par devise (jamais converti).
  Map<String, int> get amountByCurrency {
    final totals = <String, int>{};
    for (final row in all) {
      final amount = row.stats.amount;
      if (amount == null) continue;
      totals[amount.currency] =
          (totals[amount.currency] ?? 0) + amount.amountInCents;
    }
    return totals;
  }

  /// Pointages du mois pas encore au serveur.
  int get pending =>
      all.where((row) => row.sync != RecordSyncState.synced).length;

  int _sum(int Function(StaffMonthStats stats) pick) =>
      all.fold<int>(0, (sum, row) => sum + pick(row.stats));

  static RecordSyncState _worstSync(
    StaffAttendanceSnapshot snapshot,
    String memberId,
    String month,
  ) {
    var worst = RecordSyncState.synced;
    for (final entry in (snapshot.records[memberId] ?? const {}).entries) {
      if (!entry.key.startsWith(month)) continue;
      worst = StaffFileRow.worse(worst, entry.value.syncState);
    }
    return worst;
  }

  @override
  List<Object?> get props => [ledger.month, all, rows, byContract];
}
