import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_parts.dart';

import '../../../test_helpers/reference_formats.dart';

/// L'identité du bulletin sur la feuille d'un téléphone : un nom composé
/// tient sur deux lignes au lieu d'être coupé sans recours ; au-delà, il se
/// lit en info-bulle.
void main() {
  // La police de test dessine chaque glyphe en carré d'1 em : ce nom y prend
  // deux lignes de la colonne (142 dp), comme un nom composé avec la vraie
  // police.
  const name = 'KALALA Didier';

  Future<void> pump(WidgetTester tester, String value) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          // La feuille du bulletin sur un téléphone de 360 dp.
          child: SizedBox(
            width: 296,
            child: PayrollPayslipIdentity(
              rows: [
                (label: 'Agent', value: value, note: null),
                (label: 'Matricule', value: 'AG-0042', note: null),
                (label: 'Fonction', value: 'Enseignant', note: null),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  for (final scale in [1.0, 1.3]) {
    testWidgets('un nom composé se lit en entier — texte ×$scale', (
      tester,
    ) async {
      applyReferenceFormat(
        tester,
        ReferenceFormat('téléphone', const Size(360, 740), textScale: scale),
      );
      await pump(tester, name);

      final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
      // Rien de coupé : le nom tient dans ses lignes, sans info-bulle.
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(find.byTooltip(name), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('trop long pour deux lignes : l info-bulle le donne', (
    tester,
  ) async {
    const longer = 'KABASELE-TSHIMANGA Marie-Béatrice';
    await pump(tester, longer);
    expect(find.byTooltip(longer), findsOneWidget);
  });
}
