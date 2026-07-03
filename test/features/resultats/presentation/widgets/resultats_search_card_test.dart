import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_search_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (ctx) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
      child: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 720, child: child)),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'bascule Par élève : révèle les champs nom + change le libellé d\'action',
    (tester) async {
      await tester.pumpWidget(
        _host(
          ResultatsSearchCard(
            cycleOptions: const [],
            periodeSelected: false,
            isSubmitting: false,
            onModeChanged: (_) {},
            onCycleChanged: (_) {},
            onClassroomChanged: (_) {},
            onSubmit: (_) {},
          ),
        ),
      );

      // Mode classe par défaut : action « Afficher les résultats », pas de champs.
      expect(find.text('Afficher les résultats'), findsOneWidget);
      expect(find.text('Postnom'), findsNothing);

      await tester.tap(find.text('Par élève'));
      await tester.pumpAndSettle();

      expect(find.text('Retrouver l\'élève'), findsOneWidget);
      expect(find.text('Postnom'), findsOneWidget);
      expect(find.text('Prénom(s)'), findsOneWidget);
    },
  );
}
