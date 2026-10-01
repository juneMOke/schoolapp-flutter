import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';

/// Les critères du registre : un statut (ou tous) et un texte.
class ClassDayQuery extends Equatable {
  /// `null` = tous les statuts.
  final PresenceStatus? status;
  final String text;

  const ClassDayQuery({this.status, this.text = ''});

  static const ClassDayQuery none = ClassDayQuery();

  ClassDayQuery withStatus(PresenceStatus? value) =>
      ClassDayQuery(status: value, text: text);

  ClassDayQuery withText(String value) =>
      ClassDayQuery(status: status, text: value);

  /// Nom, post-nom, prénom, sans égard aux accents.
  bool accepts(ClassPresenceLine line) =>
      (status == null || line.status == status) &&
      SearchNormalizationHelper.containsAllWords([
        line.student.lastName,
        line.student.middleName,
        line.student.firstName,
      ], text);

  @override
  List<Object?> get props => [status, text];
}

/// Ce que montre le registre d'une classe pour un jour. Calcul pur, refait à
/// chaque filtre.
class ClassDayRegister extends Equatable {
  final ClassPresenceDay day;

  /// Ceux qui passent les filtres.
  final List<ClassPresenceLine> rows;

  /// Effectif par statut, sur toute la classe.
  final Map<PresenceStatus, int> byStatus;

  const ClassDayRegister._({
    required this.day,
    required this.rows,
    required this.byStatus,
  });

  factory ClassDayRegister.build(ClassPresenceDay day, ClassDayQuery query) =>
      ClassDayRegister._(
        day: day,
        rows: [
          for (final line in day.lines)
            if (query.accepts(line)) line,
        ],
        byStatus: {
          for (final status in PresenceStatus.values)
            status: day.lines.where((line) => line.status == status).length,
        },
      );

  List<ClassPresenceLine> get all => day.lines;

  int count(PresenceStatus status) => byStatus[status] ?? 0;

  int get marked => all.length - count(PresenceStatus.none);

  /// Les élèves encore « à pointer ».
  List<ClassPresenceLine> get unmarked => [
    for (final line in all)
      if (line.status == PresenceStatus.none) line,
  ];

  /// Marques écrites sur la tablette, pas encore au serveur.
  int get pending =>
      all.where((line) => line.sync != RecordSyncState.synced).length;

  /// Retards et absences sans justification.
  int get toJustify => all.where((line) => line.mark.needsJustification).length;

  /// L'appel est validé, ou le mois clos : rien ne se pointe.
  bool get frozen => day.validated || day.monthClosed;

  bool get isEmpty => all.isEmpty;

  bool get isFilteredEmpty => all.isNotEmpty && rows.isEmpty;

  /// Une ligne porte un motif que cette tablette ne sait pas renvoyer.
  bool get blocksResend => all.any((line) => line.blocksResend);

  @override
  List<Object?> get props => [day, rows, byStatus];
}
