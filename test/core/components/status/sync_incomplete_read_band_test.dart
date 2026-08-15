import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_incomplete_read_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBand(
    WidgetTester tester, {
    bool retriable = false,
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SyncIncompleteReadBand(retriable: retriable, onRetry: onRetry),
        ),
      ),
    );
  }

  testWidgets('dit ce qui manque, et que rien de saisi n\'est perdu', (
    tester,
  ) async {
    await pumpBand(tester);

    expect(find.text('Certaines données ne descendent pas'), findsOneWidget);
    expect(
      find.textContaining('La dernière mise à jour n\'a pas tout ramené.'),
      findsOneWidget,
    );
    // La phrase qui distingue cette bande d'un conflit d'écriture : c'est la
    // LECTURE qui est incomplète, la file de push n'a rien perdu.
    expect(
      find.textContaining('Rien de ce que vous avez saisi n\'est perdu.'),
      findsOneWidget,
    );
  });

  testWidgets('aucune action : un « Réessayer » ne lèverait pas la cause', (
    tester,
  ) async {
    await pumpBand(tester);

    // Ce qui manque manque parce que ce compte n'y a pas droit, ou parce que
    // le serveur a refusé — pas parce qu'un geste a été oublié.
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  group('cause non rattrapable (droit manquant)', () {
    testWidgets(
      'retriable: false → aucun bouton, et la phrase générique renvoie à l\'administrateur',
      (tester) async {
        await pumpBand(tester, retriable: false, onRetry: () {});

        // Un droit manquant est sauté à l'identique à CHAQUE cycle : le geste
        // ne lèverait rien. Le callback est pourtant fourni ici — c'est bien
        // `retriable` qui décide, pas la simple présence d'une action.
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.text('Réessayer'), findsNothing);

        // Et la phrase reste celle qui oriente vers la vraie condition de
        // déblocage : les accès du compte.
        expect(
          find.textContaining('La dernière mise à jour n\'a pas tout ramené.'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'votre administrateur peut vérifier les accès de votre compte.',
          ),
          findsOneWidget,
        );
        // La variante rattrapable ne doit surtout pas s'afficher ici.
        expect(
          find.textContaining('s\'est interrompue avant d\'avoir tout ramené.'),
          findsNothing,
        );
      },
    );
  });

  group('cause rattrapable (échec de transport)', () {
    testWidgets(
      'retriable: true + onRetry → bouton « Réessayer », phrase sans mise en cause des droits',
      (tester) async {
        var taps = 0;
        await pumpBand(tester, retriable: true, onRetry: () => taps++);

        // Sans ce bouton, un simple timeout resterait verrouillé jusqu'au
        // redémarrage de l'application : le pull n'a que deux déclencheurs, et
        // une tablette posée sur le Wi-Fi de l'école n'en voit aucun.
        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.text('Réessayer'), findsOneWidget);

        // La phrase bascule sur la variante rattrapable : un transport coupé
        // n'est pas un problème de droits, et renvoyer vers l'administrateur
        // serait exactement le mensonge que ce lot corrige.
        expect(
          find.textContaining('s\'est interrompue avant d\'avoir tout ramené.'),
          findsOneWidget,
        );
        expect(find.textContaining('administrateur'), findsNothing);
        expect(
          find.textContaining('La dernière mise à jour n\'a pas tout ramené.'),
          findsNothing,
        );

        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        // Le geste déclenche bien un nouveau cycle : un bouton qui ne rappelle
        // rien vaudrait moins que pas de bouton du tout.
        expect(taps, 1);
      },
    );

    testWidgets(
      'retriable: true mais onRetry null → aucun bouton (une action morte est pire qu\'aucune)',
      (tester) async {
        // La feuille montée sans cubit (galerie, test, écran de secours) reste
        // muette plutôt que d'offrir un « Réessayer » qui ne fait rien.
        await pumpBand(tester, retriable: true);

        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.text('Réessayer'), findsNothing);

        // Et pas de promesse implicite non plus : sans geste offert, la phrase
        // redevient celle qui explique la situation sans en attendre un.
        expect(
          find.textContaining('La dernière mise à jour n\'a pas tout ramené.'),
          findsOneWidget,
        );
      },
    );
  });
}
