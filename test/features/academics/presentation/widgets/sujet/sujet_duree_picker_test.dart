import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_duree_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Hôte qui renvoie la valeur émise, comme le formulaire de création.
class _Host extends StatefulWidget {
  final int? initial;

  const _Host(this.initial);

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int? value = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SujetDureePicker(
        value: value,
        onChanged: (v) => setState(() => value = v),
      ),
      Text('valeur=$value'),
      TextButton(
        onPressed: () => setState(() => value = 120),
        child: const Text('imposer'),
      ),
    ],
  );
}

void main() {
  Future<void> pump(WidgetTester tester, int? initial) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: _Host(initial)),
    ),
  );

  testWidgets('« Autre » s’ouvre sur la durée courante et y reste', (
    tester,
  ) async {
    await pump(tester, 30);

    await tester.tap(find.text('Autre'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('valeur=30'), findsOneWidget);

    // En route vers 600, « 60 » est un préréglage : le champ reste ouvert.
    await tester.enterText(find.byType(TextField), '60');
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '600');
    await tester.pump();
    expect(find.text('valeur=600'), findsOneWidget);
  });

  testWidgets('au-delà de 600 minutes, la durée est plafonnée', (tester) async {
    await pump(tester, 30);
    await tester.tap(find.text('Autre'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '999');
    await tester.pump();
    expect(find.text('valeur=600'), findsOneWidget);
  });

  testWidgets('une valeur imposée de l’extérieur referme « Autre »', (
    tester,
  ) async {
    await pump(tester, 75);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('imposer'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
  });
}
