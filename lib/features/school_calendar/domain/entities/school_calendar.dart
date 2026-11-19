import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';

/// Le calendrier d'une école pour une année scolaire (K5 : attaché au libellé
/// d'année, `academicYearId` nul tant que l'année n'existe pas).
///
/// [startDate] / [endDate] viennent du cadre national ; sans cadre, le serveur
/// sert la rentrée par défaut (premier lundi de septembre).
class SchoolCalendar extends Equatable {
  final String id;
  final String yearLabel;
  final String? academicYearId;
  final CalendarStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final FrameworkState framework;
  final int? frameworkVersion;
  final DateTime? publishedAt;
  final String? publishedByLabel;
  final DateTime? updatedAt;
  final int revision;

  const SchoolCalendar({
    required this.id,
    required this.yearLabel,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.framework,
    required this.revision,
    this.academicYearId,
    this.frameworkVersion,
    this.publishedAt,
    this.publishedByLabel,
    this.updatedAt,
  });

  bool get isPublished => status == CalendarStatus.published;

  bool get hasFramework => framework == FrameworkState.integrated;

  /// Le libellé de l'année suivante : « 2026-2027 » → « 2027-2028 ».
  /// `null` si le libellé n'a pas la forme attendue.
  String? get nextYearLabel => shiftYearLabel(yearLabel, 1);

  static String? shiftYearLabel(String label, int years) {
    final match = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(label);
    if (match == null) return null;
    final first = int.parse(match.group(1)!) + years;
    final second = int.parse(match.group(2)!) + years;
    return '$first-$second';
  }

  @override
  List<Object?> get props => [
    id,
    yearLabel,
    academicYearId,
    status,
    startDate,
    endDate,
    framework,
    frameworkVersion,
    publishedAt,
    publishedByLabel,
    updatedAt,
    revision,
  ];
}
