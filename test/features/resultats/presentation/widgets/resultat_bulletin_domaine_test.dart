import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/branche_resultat.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/bulletin_domaine.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/domaine_resultat.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_bulletin_domaine.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

BulletinDomaine _fixture() => const BulletinDomaine(
  domaines: [
    DomaineResultat(
      rubriqueId: 'd-langues',
      label: 'Langues',
      produitSousTotal: true,
      obtenu: 28,
      max: 40,
      pourcentage: 70,
      branches: [
        BrancheResultat(
          ligneBaremeId: 'l1',
          brancheId: 'b-fr',
          brancheNom: 'Français',
          obtenu: 15,
          max: 20,
          pourcentage: 75,
        ),
        BrancheResultat(
          ligneBaremeId: 'l2',
          brancheId: 'b-en',
          brancheNom: 'Anglais',
          obtenu: 13,
          max: 20,
          pourcentage: 65,
        ),
      ],
    ),
  ],
  totalObtenu: 160,
  totalMax: 220,
  pourcentage: 73,
);

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
    'rend le bandeau domaine, les branches, le sous-total et le total',
    (tester) async {
      await tester.pumpWidget(
        _host(
          ResultatBulletinDomaine(
            bulletin: _fixture(),
            periodeLongLabel: 'Trimestre 1',
          ),
        ),
      );

      expect(find.text('Bulletin par domaine · Trimestre 1'), findsOneWidget);
      expect(find.text('LANGUES'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Anglais'), findsOneWidget);
      expect(find.text('15/20'), findsOneWidget);
      expect(find.text('Sous-total'), findsOneWidget);
      expect(find.text('Totaux obtenus'), findsOneWidget);
      expect(find.text('160/220'), findsOneWidget);
    },
  );
}
