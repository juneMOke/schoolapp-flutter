import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_levels_pdf.dart';

LevelStat _level(String label, int value, {String cycle = 'PRIMARY'}) =>
    LevelStat(
      id: 'id-$label',
      code: label,
      label: label,
      cycle: cycle,
      value: value,
    );

/// La seule sortie encore composée sur l'appareil : le classement par niveau.
///
/// La liste nominative, elle, s'imprime depuis le serveur — ses tests vivent
/// avec le registre (`enrollment_entries_report_*_test.dart`).
void main() {
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
}

String _subtitle(String schoolYear, String generatedOn) =>
    'Année scolaire $schoolYear · au $generatedOn';

String _footer(int rowCount, String schoolYear, String generatedOn) =>
    '$rowCount niveaux · année scolaire $schoolYear · généré le $generatedOn';
