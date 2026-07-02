import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_summary_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  EvalDetailArgs args(EvalState state) => EvalDetailArgs(
    brancheNom: 'Mathématiques',
    classroomName: '6e A',
    rattachementLabel: 'Période 1 · Sous-période 2',
    eval: EvalVm(
      id: 'e1',
      type: TypeEvaluation.interro,
      nom: 'Interrogation 3 — Proportionnalité',
      chapitres: const ['Proportionnalité'],
      date: DateTime(2026, 6, 12),
      maxPoints: 10,
      poids: 1,
      state: state,
      pourcentageSaisie: 64,
      saisies: 18,
      total: 28,
    ),
  );

  testWidgets('rend eyebrow, titre, chips et chapitres', (tester) async {
    await tester.pumpWidget(
      host(EvalSummaryCard(args: args(EvalState.partial))),
    );
    await tester.pumpAndSettle();

    expect(find.text('INTERROGATION'), findsOneWidget); // eyebrow uppercase
    expect(find.text('Interrogation 3 — Proportionnalité'), findsOneWidget);
    expect(find.text('Maximum : 10 pts'), findsOneWidget);
    expect(find.text('Poids : 1'), findsOneWidget);
    expect(find.text('6e A'), findsOneWidget);
    expect(find.text('Période 1 · Sous-période 2'), findsOneWidget);
    expect(find.text('Proportionnalité'), findsOneWidget); // ligne chapitres
  });

  testWidgets('badge d\'avancement : partial → « Saisie en cours · 18/28 »', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(EvalSummaryCard(args: args(EvalState.partial))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saisie en cours · 18/28'), findsOneWidget);
  });

  testWidgets('badge d\'avancement : complete → « Clôturée »', (tester) async {
    await tester.pumpWidget(
      host(EvalSummaryCard(args: args(EvalState.complete))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Clôturée'), findsOneWidget);
  });
}
