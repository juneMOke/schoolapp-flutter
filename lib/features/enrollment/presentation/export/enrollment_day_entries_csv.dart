import 'package:school_app_flutter/core/export/csv_writer.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';

/// Le CSV de la liste nominative du jour.
///
/// Il porte **plus de colonnes que le tableau** — le sexe, le cycle et le
/// statut s'ajoutent aux cinq colonnes affichées. Un export n'est pas une
/// copie d'écran : ce qui est lu d'un coup d'œil à l'écran doit se retrouver
/// dans un tableur où l'on trie et filtre.
///
/// Comme le rendu PDF, c'est une **fonction pure** : elle prend des lignes et
/// rend une chaîne. Rien du transport (presse-papier, fichier, partage) ne la
/// concerne.
abstract final class EnrollmentDayEntriesCsv {
  /// Compose le document.
  ///
  /// [entries] arrive dans l'ordre du serveur — chronologique — et n'est ni
  /// retrié ni refiltré ici : le fichier dit exactement ce que la carte
  /// disait.
  static String build({
    required List<DayEnrollmentEntry> entries,
    required CsvDayEntriesLabels labels,
  }) {
    return CsvWriter.document([
      [
        labels.columnHour,
        labels.columnLastName,
        labels.columnFirstName,
        labels.columnGender,
        labels.columnLevel,
        labels.columnCycle,
        labels.columnType,
        labels.columnRecordedBy,
      ],
      for (final entry in entries)
        [
          // Même règle qu'à l'écran : une heure qui ne tombe pas le jour
          // déclaré ne dit rien de la journée exportée, donc elle n'est pas
          // exportée. Un tableur ne relativise pas une valeur, il la trie.
          entry.hourIsMeaningful ? _hour(entry.createdAt) : '',
          [
            entry.lastName,
            entry.surname,
          ].where((p) => p.trim().isNotEmpty).join(' '),
          entry.firstName,
          entry.gender == Gender.female ? labels.female : labels.male,
          entry.schoolLevel,
          entry.cycle,
          entry.formerStudent ? labels.typeReturning : labels.typeFirst,
          // Vide plutôt qu'un tiret : le tiret est une convention d'affichage,
          // et il se trierait comme une valeur dans un tableur.
          entry.recordedBy ?? '',
        ],
    ]);
  }

  /// `inscriptions-2026-09-05.csv`
  static String fileName(DateTime day) => CsvWriter.fileName([
    'inscriptions',
    EnrollmentStatsWindow.formatApiDate(day),
  ]);

  /// `09:30` — heure sur deux chiffres, indépendante de la locale.
  ///
  /// Un tableur trie une chaîne `HH:mm` correctement ; un format localisé
  /// (« 9 h 30 ») ne se trie pas et ne se reparse pas.
  static String _hour(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';
}

/// Les en-têtes du fichier, traduits par l'appelant.
class CsvDayEntriesLabels {
  final String columnHour;
  final String columnLastName;
  final String columnFirstName;
  final String columnGender;
  final String columnLevel;
  final String columnCycle;
  final String columnType;
  final String columnRecordedBy;
  final String female;
  final String male;
  final String typeFirst;
  final String typeReturning;

  const CsvDayEntriesLabels({
    required this.columnHour,
    required this.columnLastName,
    required this.columnFirstName,
    required this.columnGender,
    required this.columnLevel,
    required this.columnCycle,
    required this.columnType,
    required this.columnRecordedBy,
    required this.female,
    required this.male,
    required this.typeFirst,
    required this.typeReturning,
  });
}
