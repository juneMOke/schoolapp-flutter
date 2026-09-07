import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/export/csv_writer.dart';

/// Le format CSV maison, épinglé.
///
/// Il n'avait aucun test quand il vivait dans `FinanceCsvExportHelper` : la
/// Facturation était son unique appelant, et le format se vérifiait à l'œil en
/// ouvrant le fichier dans Excel. Il en a maintenant deux (Facturation,
/// Inscriptions), donc une régression silencieuse coûterait deux écrans — d'où
/// ces assertions, écrites en même temps que l'extraction.
void main() {
  group('CsvWriter — le format', () {
    test('le document s\'ouvre par le BOM UTF-8', () {
      final csv = CsvWriter.document([
        ['a'],
      ]);
      expect(csv.codeUnitAt(0), 0xFEFF);
      expect(csv, startsWith(CsvWriter.bom));
    });

    test('les colonnes se séparent au point-virgule, pas à la virgule', () {
      // La virgule est le séparateur décimal en locale française : Excel
      // casserait les colonnes sur le premier montant rencontré.
      expect(CsvWriter.row(['a', 'b']), '"a";"b"\r\n');
    });

    test('les lignes se terminent en CRLF', () {
      expect(CsvWriter.row(['a']), endsWith('\r\n'));
    });

    test('toutes les cellules sont guillemetées, même les plus banales', () {
      expect(CsvWriter.escapeCell('Minerval'), '"Minerval"');
      expect(CsvWriter.escapeCell(''), '""');
    });

    test('un guillemet interne est doublé, pas échappé', () {
      expect(CsvWriter.escapeCell('Frais "spécial"'), '"Frais ""spécial"""');
    });

    test('une cellule portant le séparateur reste UNE cellule', () {
      // C'est la raison d'être du guillemetage systématique.
      final csv = CsvWriter.row(['Nom; prénom', 'x']);
      expect(csv, '"Nom; prénom";"x"\r\n');
    });

    test('les espaces de bordure sont retirés', () {
      expect(CsvWriter.escapeCell('  Minerval  '), '"Minerval"');
    });

    test('le document enchaîne les lignes dans l\'ordre reçu', () {
      final csv = CsvWriter.document([
        ['Frais', 'Montant'],
        ['Minerval', '15.00'],
      ]);
      expect(
        csv,
        '${CsvWriter.bom}"Frais";"Montant"\r\n"Minerval";"15.00"\r\n',
      );
    });

    test('un document sans ligne reste un BOM seul', () {
      expect(CsvWriter.document(const []), CsvWriter.bom);
    });
  });

  group('CsvWriter — les noms de fichier', () {
    test('les accents sont repliés et les espaces deviennent des tirets', () {
      expect(
        CsvWriter.fileName(['inscriptions', 'Frais de scolarité']),
        'inscriptions-frais-de-scolarite.csv',
      );
    });

    test('une partie vide ne laisse pas de double tiret', () {
      // Un libellé absent raccourcit le nom ; il ne le rend pas bancal.
      expect(
        CsvWriter.fileName(['paiements', '', 'kabila']),
        'paiements-kabila.csv',
      );
    });

    test('la ponctuation ne fuit pas dans le nom de fichier', () {
      expect(CsvWriter.fileName(['reçu n°12/2026']), 'recu-n-12-2026.csv');
    });

    test('l\'extension se choisit', () {
      expect(CsvWriter.fileName(['x'], extension: 'txt'), 'x.txt');
    });

    test('slugify ne laisse pas de tiret en bordure', () {
      expect(CsvWriter.slugify('  — Minerval —  '), 'minerval');
    });

    test('les diacritiques français sont tous couverts', () {
      expect(
        CsvWriter.removeDiacritics('àáâãäåçèéêëìíîïñòóôõöùúûüýÿ'),
        'aaaaaaceeeeiiiinooooouuuuyy',
      );
    });
  });
}
