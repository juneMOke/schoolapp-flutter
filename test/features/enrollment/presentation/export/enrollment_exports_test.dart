import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/export/csv_writer.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_day_entries_csv.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_day_entries_pdf.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_levels_pdf.dart';

const _labels = CsvDayEntriesLabels(
  columnHour: 'Heure',
  columnLastName: 'Nom',
  columnFirstName: 'Prénom',
  columnGender: 'Sexe',
  columnLevel: 'Niveau',
  columnCycle: 'Cycle',
  columnType: 'Type',
  columnRecordedBy: 'Enregistré par',
  female: 'Filles',
  male: 'Garçons',
  typeFirst: 'Première inscription',
  typeReturning: 'Réinscription',
);

DayEnrollmentEntry _entry({
  Gender gender = Gender.female,
  bool formerStudent = false,
  DateTime? enrollmentDate,
  DateTime? createdAt,
  String? recordedBy = 'M. Ilunga',
  String lastName = 'KABILA',
  String surname = 'Nsimba',
}) => DayEnrollmentEntry(
  enrollmentId: 'e1',
  studentId: 's1',
  firstName: 'Amina',
  lastName: lastName,
  surname: surname,
  gender: gender,
  schoolLevelId: 'lvl',
  schoolLevel: '6e année',
  cycle: 'PRIMARY',
  formerStudent: formerStudent,
  enrollmentDate: enrollmentDate ?? DateTime(2026, 9, 5),
  createdAt: createdAt ?? DateTime(2026, 9, 5, 9, 30),
  recordedBy: recordedBy,
);

LevelStat _level(String label, int value, {String cycle = 'PRIMARY'}) =>
    LevelStat(
      id: 'id-$label',
      code: label,
      label: label,
      cycle: cycle,
      value: value,
    );

void main() {
  group('CSV de la liste du jour', () {
    test('porte PLUS de colonnes que le tableau', () {
      // Un export n'est pas une copie d'écran : le sexe, le cycle et le statut
      // s'ajoutent, parce qu'on trie et filtre dans un tableur.
      final csv = EnrollmentDayEntriesCsv.build(
        entries: [_entry()],
        labels: _labels,
      );

      expect(csv, contains('"Sexe"'));
      expect(csv, contains('"Cycle"'));
      expect(csv, contains('"Type"'));
    });

    test('respecte le format maison', () {
      final csv = EnrollmentDayEntriesCsv.build(
        entries: [_entry()],
        labels: _labels,
      );

      expect(csv, startsWith(CsvWriter.bom));
      expect(csv, contains('\r\n'));
      expect(csv, contains('"KABILA Nsimba";"Amina"'));
    });

    test('le sexe est écrit, pas codé', () {
      final csv = EnrollmentDayEntriesCsv.build(
        entries: [_entry(gender: Gender.female)],
        labels: _labels,
      );

      expect(csv, contains('"Filles"'));
      expect(csv, isNot(contains('"FEMALE"')));
    });

    test('l\'heure part en HH:mm, triable dans un tableur', () {
      final csv = EnrollmentDayEntriesCsv.build(
        entries: [_entry(createdAt: DateTime(2026, 9, 5, 9, 5))],
        labels: _labels,
      );

      expect(csv, contains('"09:05"'));
    });

    test('un dossier antidaté n\'exporte AUCUNE heure', () {
      // Même règle qu'à l'écran : une heure qui ne tombe pas le jour déclaré
      // ne dit rien de la journée exportée. Un tableur, lui, ne relativise
      // pas une valeur — il la trie.
      final csv = EnrollmentDayEntriesCsv.build(
        entries: [
          _entry(
            enrollmentDate: DateTime(2026, 9, 5),
            createdAt: DateTime(2026, 9, 6, 21, 15),
          ),
        ],
        labels: _labels,
      );

      expect(csv, isNot(contains('21:15')));
      expect(csv, contains('""'));
    });

    test('un agent inconnu laisse la cellule VIDE, pas un tiret', () {
      // Le tiret est une convention d'affichage ; dans un tableur il se
      // trierait comme une valeur.
      final csv = EnrollmentDayEntriesCsv.build(
        entries: [_entry(recordedBy: null)],
        labels: _labels,
      );

      expect(csv, isNot(contains('"—"')));
    });

    test('le nom de fichier porte le jour exporté', () {
      expect(
        EnrollmentDayEntriesCsv.fileName(DateTime(2026, 9, 5)),
        'inscriptions-2026-09-05.csv',
      );
    });

    test('une liste vide reste un document valide, avec son en-tête', () {
      final csv = EnrollmentDayEntriesCsv.build(
        entries: const [],
        labels: _labels,
      );

      expect(csv, contains('"Nom"'));
      expect(csv.split('\r\n').where((l) => l.isNotEmpty), hasLength(1));
    });
  });

  group('PDF du classement par niveau', () {
    const pdfLabels = PdfLevelsLabels(
      overtitle: 'ETEELO CONNECT · Inscriptions',
      title: 'Répartition par niveau',
      columnLevel: 'Niveau',
      columnCycle: 'Cycle',
      columnCount: 'Inscrits',
      subtitle: _subtitle,
      footer: _footer,
    );

    test('produit un document PDF non vide', () async {
      final bytes = await EnrollmentLevelsPdf.render(
        levels: [_level('6e', 84), _level('5e', 61)],
        schoolYear: '2026-2027',
        generatedOn: '5 septembre 2026',
        labels: pdfLabels,
      );

      expect(bytes, isNotEmpty);
      // En-tête de fichier PDF — le document est réellement composé, pas un
      // tableau d'octets quelconque.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('une liste vide ne fait pas échouer la composition', () async {
      // L'écran retire les boutons dans ce cas, mais le rendu ne doit pas
      // dépendre de cette politesse pour ne pas lever.
      final bytes = await EnrollmentLevelsPdf.render(
        levels: const [],
        schoolYear: '2026-2027',
        generatedOn: '5 septembre 2026',
        labels: pdfLabels,
      );

      expect(bytes, isNotEmpty);
    });

    test('trente niveaux composent sans lever — plusieurs pages', () async {
      // C'est la raison d'être de `MultiPage` ici : une école à trente
      // niveaux déborde d'une feuille.
      final bytes = await EnrollmentLevelsPdf.render(
        levels: [for (var i = 0; i < 30; i++) _level('N$i', 100 - i)],
        schoolYear: '2026-2027',
        generatedOn: '5 septembre 2026',
        labels: pdfLabels,
      );

      expect(bytes, isNotEmpty);
    });
  });
  group('PDF de la liste nominative du jour', () {
    PdfDayEntriesLabels dayLabels() => PdfDayEntriesLabels(
      overtitle: 'ETEELO CONNECT · Inscriptions',
      title: 'Liste nominative du jour',
      columnHour: 'Heure',
      columnStudent: 'Élève',
      columnGender: 'Sexe',
      columnLevel: 'Niveau',
      columnType: 'Type',
      columnRecordedBy: 'Enregistré par',
      female: 'Filles',
      male: 'Garçons',
      typeFirst: 'Première inscription',
      typeReturning: 'Réinscription',
      unknownAgent: '—',
      noHour: '—',
      subtitle: (year, day) => 'Année scolaire $year · $day',
      footer: (count, year, on) => '$count · $year · $on',
    );

    Future<List<int>> render(List<DayEnrollmentEntry> entries) =>
        EnrollmentDayEntriesPdf.render(
          entries: entries,
          schoolYear: '2026-2027',
          day: '5 septembre 2026',
          generatedOn: '5 septembre 2026',
          labels: dayLabels(),
        );

    test('produit un document PDF non vide', () async {
      final bytes = await render([_entry(), _entry(formerStudent: true)]);

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('une liste vide ne fait pas échouer la composition', () async {
      // L'écran retire les boutons dans ce cas, mais le rendu ne doit pas
      // dépendre de cette politesse pour ne pas lever.
      expect(await render(const []), isNotEmpty);
    });

    test('une heure hors du jour déclaré ne lève pas', () async {
      // Dossier antidaté : `createdAt` ne tombe pas le jour exporté. La case
      // reçoit un tiret plutôt qu'une heure fausse — sur un document imprimé,
      // une heure fausse ne se rattrape plus.
      final entry = _entry(
        enrollmentDate: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 2, 18, 4),
      );
      expect(entry.hourIsMeaningful, isFalse);
      expect(await render([entry]), isNotEmpty);
    });

    test('un agent non résolu ne lève pas', () async {
      expect(await render([_entry(recordedBy: null)]), isNotEmpty);
    });

    test('quarante lignes composent sur plusieurs pages', () async {
      // Une grosse journée de rentrée déborde d'une feuille : c'est la raison
      // d'être de `MultiPage`.
      expect(await render([for (var i = 0; i < 40; i++) _entry()]), isNotEmpty);
    });
  });
}

String _subtitle(String schoolYear, String generatedOn) =>
    'Année scolaire $schoolYear · au $generatedOn';

String _footer(int rowCount, String schoolYear, String generatedOn) =>
    '$rowCount niveaux · année scolaire $schoolYear · généré le $generatedOn';
