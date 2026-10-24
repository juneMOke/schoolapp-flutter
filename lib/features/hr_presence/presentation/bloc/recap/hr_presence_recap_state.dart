import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';

enum HrPresenceRecapStatus { loading, ready, failure }

const Object _undefined = Object();

class HrPresenceRecapState extends Equatable {
  /// `AAAA-MM`.
  final String month;
  final String currentMonth;
  final String? firstMonth;
  final HrPresenceRecapStatus status;
  final HrAttendanceRecap? recap;
  final Failure? failure;

  /// Le verrou du mois sur la tablette : une clôture posée ici et pas encore
  /// reçue par le serveur, qui ne la voit pas encore.
  final StaffAttendanceLock? localLock;

  /// Pointages du mois encore sur la tablette (D1).
  final int unsynced;
  final String text;

  /// `null` : tous les contrats.
  final StaffContractFilter? contract;

  /// Une clôture est en cours d'écriture : le bouton se désarme.
  final bool closing;

  const HrPresenceRecapState({
    required this.month,
    required this.currentMonth,
    this.firstMonth,
    this.status = HrPresenceRecapStatus.loading,
    this.recap,
    this.failure,
    this.localLock,
    this.unsynced = 0,
    this.text = '',
    this.contract,
    this.closing = false,
  });

  bool get isCurrentMonth => month == currentMonth;

  bool get canStepBack {
    final first = firstMonth;
    return first == null || month.compareTo(first) > 0;
  }

  /// Clos au serveur, ou sur la tablette en attendant l'envoi.
  bool get isClosed => (recap?.closed ?? false) || (localLock?.locked ?? false);

  bool get hasFilters => text.trim().isNotEmpty || contract != null;

  List<HrAttendanceRecapRow> get _searched => [
    for (final row in recap?.staff ?? const <HrAttendanceRecapRow>[])
      if (SearchNormalizationHelper.containsAllWords([
        row.agent.lastName,
        row.agent.middleName,
        row.agent.firstName,
        row.agent.jobTitle,
        row.agent.staffNumber,
      ], text))
        row,
  ];

  /// Les agents de la recherche par filtre de contrat, pour les puces.
  Map<StaffContractFilter, int> get contractCounts {
    final counts = <StaffContractFilter, int>{};
    for (final row in _searched) {
      for (final filter in StaffContractFilter.values) {
        if (filter.matches(row.agent.contractKind)) {
          counts[filter] = (counts[filter] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  int get searchedCount => _searched.length;

  List<HrAttendanceRecapRow> get visibleRows => [
    for (final row in _searched)
      if (contract == null || contract!.matches(row.agent.contractKind)) row,
  ];

  HrPresenceRecapState copyWith({
    String? month,
    HrPresenceRecapStatus? status,
    Object? recap = _undefined,
    Object? failure = _undefined,
    Object? localLock = _undefined,
    int? unsynced,
    String? text,
    Object? contract = _undefined,
    bool? closing,
  }) => HrPresenceRecapState(
    month: month ?? this.month,
    currentMonth: currentMonth,
    firstMonth: firstMonth,
    status: status ?? this.status,
    recap: identical(recap, _undefined)
        ? this.recap
        : recap as HrAttendanceRecap?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    localLock: identical(localLock, _undefined)
        ? this.localLock
        : localLock as StaffAttendanceLock?,
    unsynced: unsynced ?? this.unsynced,
    text: text ?? this.text,
    contract: identical(contract, _undefined)
        ? this.contract
        : contract as StaffContractFilter?,
    closing: closing ?? this.closing,
  );

  @override
  List<Object?> get props => [
    month,
    currentMonth,
    firstMonth,
    status,
    recap,
    failure,
    localLock,
    unsynced,
    text,
    contract,
    closing,
  ];
}
