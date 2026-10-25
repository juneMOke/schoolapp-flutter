import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

enum HrPresenceProfilesStatus { loading, ready, failure }

const Object _undefined = Object();

class HrPresenceProfilesState extends Equatable {
  /// Le mois de la portée mensuelle `AAAA-MM` — gardé quand on passe à
  /// l'année, pour y revenir.
  final String month;

  /// Le mois en cours `AAAA-MM` : la navigation s'y arrête.
  final String currentMonth;
  final String? firstMonth;
  final bool yearly;
  final HrPresenceProfilesStatus status;
  final HrAttendanceProfiles? data;
  final Failure? failure;
  final String text;
  final StaffCategory? category;

  /// La puce de profil active ; un second appui la retire.
  final PresenceProfile? profile;

  const HrPresenceProfilesState({
    required this.month,
    required this.currentMonth,
    this.firstMonth,
    this.yearly = false,
    this.status = HrPresenceProfilesStatus.loading,
    this.data,
    this.failure,
    this.text = '',
    this.category,
    this.profile,
  });

  HrProfileScope get scope =>
      yearly ? const HrProfileScope.year() : HrProfileScope.month(month);

  bool get isCurrentMonth => month == currentMonth;

  bool get canStepBack {
    final first = firstMonth;
    return first == null || month.compareTo(first) > 0;
  }

  bool get hasFilters =>
      text.trim().isNotEmpty || category != null || profile != null;

  /// La recherche et la catégorie, sans la puce : ce que les puces comptent.
  List<HrAttendanceProfileRow> get _selection => [
    for (final row in data?.staff ?? const <HrAttendanceProfileRow>[])
      if ((category == null || row.agent.category == category) &&
          SearchNormalizationHelper.containsAllWords([
            row.agent.lastName,
            row.agent.middleName,
            row.agent.firstName,
            row.agent.jobTitle,
            row.agent.staffNumber,
          ], text))
        row,
  ];

  /// Un compte par profil présent dans la sélection, dans l'ordre des
  /// profils.
  Map<PresenceProfile, int> get profileCounts {
    final counts = <PresenceProfile, int>{};
    for (final row in _selection) {
      counts[row.profile] = (counts[row.profile] ?? 0) + 1;
    }
    // La puce active reste, même à zéro : sinon plus rien ne la retire.
    return {
      for (final profile in PresenceProfile.values)
        if (counts[profile] != null || profile == this.profile)
          profile: counts[profile] ?? 0,
    };
  }

  /// Les lignes affichées, dans l'ordre alphabétique du serveur.
  List<HrAttendanceProfileRow> get visibleRows => [
    for (final row in _selection)
      if (profile == null || row.profile == profile) row,
  ];

  HrPresenceProfilesState copyWith({
    String? month,
    bool? yearly,
    HrPresenceProfilesStatus? status,
    Object? data = _undefined,
    Object? failure = _undefined,
    String? text,
    Object? category = _undefined,
    Object? profile = _undefined,
  }) => HrPresenceProfilesState(
    month: month ?? this.month,
    currentMonth: currentMonth,
    firstMonth: firstMonth,
    yearly: yearly ?? this.yearly,
    status: status ?? this.status,
    data: identical(data, _undefined)
        ? this.data
        : data as HrAttendanceProfiles?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    text: text ?? this.text,
    category: identical(category, _undefined)
        ? this.category
        : category as StaffCategory?,
    profile: identical(profile, _undefined)
        ? this.profile
        : profile as PresenceProfile?,
  );

  @override
  List<Object?> get props => [
    month,
    currentMonth,
    firstMonth,
    yearly,
    status,
    data,
    failure,
    text,
    category,
    profile,
  ];
}
