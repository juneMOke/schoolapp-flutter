import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/remise_devoir.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/remise_devoir_fields.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_cadre_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  Future<List<RemiseDevoir>> pump(
    WidgetTester tester,
    RemiseDevoir remise,
  ) async {
    final changes = <RemiseDevoir>[];
    await tester.pumpWidget(
      host(RemiseDevoirFields(remise: remise, onChanged: changes.add)),
    );
    return changes;
  }

  testWidgets('en classe : pas de case de retard', (tester) async {
    final changes = await pump(tester, RemiseDevoir.parDefaut);

    expect(find.text('Accepter les dépôts en retard'), findsNothing);
    await tester.tap(find.text('En ligne'));
    expect(changes.single.mode, ModeRemise.enLigne);
  });

  testWidgets('en ligne : la case de retard apparaît et se coche', (
    tester,
  ) async {
    final changes = await pump(
      tester,
      const RemiseDevoir(mode: ModeRemise.enLigne),
    );

    await tester.tap(find.text('Accepter les dépôts en retard'));
    expect(changes.single.depotTardifPermis, isTrue);
  });

  testWidgets('une heure posée se retire', (tester) async {
    final changes = await pump(
      tester,
      const RemiseDevoir(heureLimite: '17:30'),
    );

    await tester.tap(find.byTooltip("Retirer l'heure limite"));
    expect(changes.single.heureLimite, isNull);
  });

  testWidgets('hors devoir, le cadre ne montre pas la remise', (tester) async {
    final consignes = TextEditingController();
    addTearDown(consignes.dispose);
    await tester.pumpWidget(
      host(
        SujetCadreFields(
          dureeMinutes: null,
          onDureeChanged: (_) {},
          programme: const [],
          onProgrammeChanged: (_) {},
          consignes: consignes,
        ),
      ),
    );

    expect(find.byType(RemiseDevoirFields), findsNothing);
  });
}
