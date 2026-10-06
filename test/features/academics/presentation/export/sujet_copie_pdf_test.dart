import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_fonts.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_pdf.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const content = SujetCopieContent(
    brancheNom: 'Chimie',
    classroomName: '7e A',
    titre: 'Interrogation 2 — Réactions',
    dateLabel: '18 juin 2026',
    maxPoints: 10,
    sujet: EvaluationSujet(
      cadre: EvaluationCadre(
        dureeMinutes: 30,
        programme: ['Masse molaire'],
        consignes: 'Calculatrice autorisée',
      ),
      questions: [
        SujetQuestion(
          id: 'q1',
          enonce: 'Calculez la masse molaire de H₂SO₄ (x² ≥ 0).',
          points: 3,
          reponseAttendue: '98 g/mol',
        ),
      ],
    ),
  );

  for (final options in const [
    CopieOptions(),
    CopieOptions(reponses: true, programme: false, points: false),
  ]) {
    test('rend un PDF, formules comprises ($options)', () async {
      final bytes = await SujetCopiePdf.build(
        content: content,
        options: options,
        l10n: lookupAppLocalizations(const Locale('fr')),
        fonts: await SujetCopieFonts.load(),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  }
}
