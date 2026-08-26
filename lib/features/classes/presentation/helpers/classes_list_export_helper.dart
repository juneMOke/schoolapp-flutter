import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListExportHelper {
  const ClassesListExportHelper._();

  /// [includeLevel] suit la colonne « Niveau » du tableau : l'export rend ce
  /// que l'écran rend. En mode classe le niveau est le critère, identique sur
  /// toutes les lignes.
  static String buildEnrollmentCsv({
    required AppLocalizations l10n,
    required List<EnrollmentSummary> summaries,
    bool includeLevel = false,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        _row([
          l10n.lastName,
          l10n.surname,
          l10n.firstName,
          if (includeLevel) l10n.classesListLevelColumnLabel,
        ]),
      );

    for (final summary in summaries) {
      buffer.writeln(
        _row([
          summary.student.lastName,
          summary.student.surname,
          summary.student.firstName,
          if (includeLevel) summary.schoolLevelName ?? '',
        ]),
      );
    }

    return buffer.toString();
  }

  static String buildClassroomMembersCsv({
    required AppLocalizations l10n,
    required List<ClassroomMember> members,
  }) {
    final buffer = StringBuffer()
      ..writeln(_row([l10n.lastName, l10n.surname, l10n.firstName]));

    for (final member in members) {
      buffer.writeln(
        _row([
          member.studentLastName,
          member.studentMiddleName ?? '',
          member.studentFirstName,
        ]),
      );
    }

    return buffer.toString();
  }

  static String _row(List<String> values) => values.map(_escapeCell).join(';');

  static String _escapeCell(String value) {
    final normalized = value.replaceAll('"', '""').trim();
    return '"$normalized"';
  }
}
