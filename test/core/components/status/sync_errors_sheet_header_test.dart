import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/sync_errors_sheet.dart';
import 'package:school_app_flutter/core/components/status/sync_incomplete_read_band.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La feuille lit `SyncStatusCubit` sur le contexte de l'appelant : un faux
/// suffit, aucun accès base/plugin n'est nécessaire pour l'en-tête.
class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit(super.initialState);

  /// Le tic du battement, joué depuis le test : c'est ce qui n'existait pas
  /// quand la feuille photographiait son état.
  void tick(SyncStatusState next) => emit(next);

  int syncNowCalls = 0;

  @override
  Future<void> syncNow({bool evaluateRevocation = true}) async {
    syncNowCalls++;
  }

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Outbox pilotée par le test. Par défaut : `loaded` et VIDE — c'est le cas
/// courant de la troisième porte d'entrée (lecture incomplète), celui où
/// l'ancien en-tête mentait deux fois.
class _FakeOutboxErrorsCubit extends Cubit<OutboxErrorsState>
    implements OutboxErrorsCubit {
  _FakeOutboxErrorsCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  Future<void> retry(String id) async {}

  @override
  Future<void> retryAll() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Les 4 littéraux FR de app_fr.arb, recopiés tels quels : c'est ce que
// l'utilisateur lit, et c'est ce que le correctif fait basculer.
const _titreEcrituresEnEchec = 'Écritures en échec';
const _sousTitreEcrituresEnEchec =
    'Ces enregistrements ont été refusés par le serveur. '
    'Ils ne repartiront pas d\'eux-mêmes.';
const _titreEtatSynchro = 'État de la synchronisation';
const _sousTitreEtatSynchro =
    'Ce que cette tablette n\'a pas reçu, et les écritures que le serveur a '
    'refusées — celles-ci ne repartiront pas d\'elles-mêmes.';

void main() {
  late _FakeSyncStatusCubit syncStatusCubit;

  setUp(() {
    getIt.registerFactory<OutboxErrorsCubit>(
      () => _FakeOutboxErrorsCubit(
        const OutboxErrorsState(status: OutboxErrorsStatus.loaded),
      ),
    );
    getIt.registerSingleton<CurrentUserContext>(
      CurrentUserContext()..set('uid-moi'),
    );
  });

  tearDown(() => getIt.reset());

  /// Ouvre réellement la feuille via `showSyncErrorsSheet`, seul chemin
  /// possible : `_SyncErrorsSheet` est privée.
  Future<void> ouvrirLaFeuille(
    WidgetTester tester, {
    required bool hasIncompleteRead,
    bool hasRetriableRead = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    syncStatusCubit = _FakeSyncStatusCubit(
      SyncStatusState(
        status: SyncStatus.synced,
        hasIncompleteRead: hasIncompleteRead,
        hasRetriableRead: hasRetriableRead,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SyncStatusCubit>.value(
          value: syncStatusCubit,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSyncErrorsSheet(context),
                child: const Text('ouvrir-la-feuille'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir-la-feuille'));
    await tester.pumpAndSettle();
  }

  group('porte d\'entrée « écritures refusées »', () {
    testWidgets(
      'hasIncompleteRead: false → en-tête « Écritures en échec » et sa phrase',
      (tester) async {
        await ouvrirLaFeuille(tester, hasIncompleteRead: false);

        expect(find.text(_titreEcrituresEnEchec), findsOneWidget);
        expect(find.text(_sousTitreEcrituresEnEchec), findsOneWidget);

        // L'en-tête de la troisième porte ne doit pas fuiter ici : entré par le
        // conflit d'écriture, l'utilisateur lit bien un écran d'écritures.
        expect(find.text(_titreEtatSynchro), findsNothing);
        expect(find.text(_sousTitreEtatSynchro), findsNothing);
      },
    );

    testWidgets('hasIncompleteRead: false → aucun bandeau de lecture', (
      tester,
    ) async {
      await ouvrirLaFeuille(tester, hasIncompleteRead: false);

      expect(find.byType(SyncIncompleteReadBand), findsNothing);
      expect(find.text('Certaines données ne descendent pas'), findsNothing);
    });
  });

  group('porte d\'entrée « lecture incomplète »', () {
    testWidgets(
      'hasIncompleteRead: true → titre « État de la synchronisation » et son sous-titre',
      (tester) async {
        await ouvrirLaFeuille(tester, hasIncompleteRead: true);

        expect(find.text(_titreEtatSynchro), findsOneWidget);
        expect(find.text(_sousTitreEtatSynchro), findsOneWidget);
      },
    );

    testWidgets(
      'hasIncompleteRead: true → plus aucune phrase n\'annonce des écritures refusées',
      (tester) async {
        await ouvrirLaFeuille(tester, hasIncompleteRead: true);

        // LE cœur du correctif. Entré par la lecture incomplète, l'outbox est
        // le plus souvent vide : annoncer « Écritures en échec » et « refusés
        // par le serveur » serait faux deux fois — le corps affiche d'ailleurs
        // le contraire, juste en dessous.
        expect(find.text(_titreEcrituresEnEchec), findsNothing);
        expect(find.text(_sousTitreEcrituresEnEchec), findsNothing);
        expect(find.textContaining('refusés par le serveur'), findsNothing);

        // La contradiction que l'ancien en-tête créait, mise à nu : le corps
        // dit « rien en échec » pendant que le titre accusait le serveur.
        expect(find.text('Aucune écriture en échec'), findsOneWidget);
      },
    );

    testWidgets('hasIncompleteRead: true → le bandeau de lecture est présent', (
      tester,
    ) async {
      await ouvrirLaFeuille(tester, hasIncompleteRead: true);

      expect(find.byType(SyncIncompleteReadBand), findsOneWidget);
      expect(find.text('Certaines données ne descendent pas'), findsOneWidget);
    });

    testWidgets(
      'hasRetriableRead: true → « Réessayer » ferme la feuille et relance un cycle',
      (tester) async {
        await ouvrirLaFeuille(
          tester,
          hasIncompleteRead: true,
          hasRetriableRead: true,
        );

        expect(find.text('Réessayer'), findsOneWidget);
        await tester.tap(find.text('Réessayer'));
        await tester.pumpAndSettle();

        expect(syncStatusCubit.syncNowCalls, 1);
        expect(find.text(_titreEtatSynchro), findsNothing);
      },
    );
  });

  // B-5 — la feuille relevait `hasIncompleteRead` / `hasRetriableRead` à
  // l'ouverture, sur la prémisse écrite qu'ils « ne peuvent de toute façon pas
  // changer utilement le temps d'une modale ouverte ». Le battement de la file
  // l'a périmée : un tic de 45 s tombe pendant qu'on lit.
  group('la feuille suit le cycle, elle ne le photographie plus', () {
    testWidgets('un tic qui LÈVE la dégradation retire le bandeau et son '
        'geste', (tester) async {
      // Sans abonnement, « Réessayer » restait offert sur une dégradation déjà
      // résorbée : le tap brûlait un cycle de dix-neuf ressources pour rien.
      await ouvrirLaFeuille(
        tester,
        hasIncompleteRead: true,
        hasRetriableRead: true,
      );
      expect(find.byType(SyncIncompleteReadBand), findsOneWidget);

      syncStatusCubit.tick(const SyncStatusState(status: SyncStatus.synced));
      await tester.pumpAndSettle();

      expect(find.byType(SyncIncompleteReadBand), findsNothing);
      expect(find.text(_titreEtatSynchro), findsNothing);
      expect(find.text(_titreEcrituresEnEchec), findsOneWidget);
    });

    testWidgets('un tic qui INTRODUIT la dégradation ouvre le bandeau', (
      tester,
    ) async {
      // L'autre sens, tout aussi muet : la feuille n'offrait plus ni bandeau ni
      // geste alors que la lecture venait de tomber en panne.
      await ouvrirLaFeuille(tester, hasIncompleteRead: false);
      expect(find.byType(SyncIncompleteReadBand), findsNothing);

      syncStatusCubit.tick(
        const SyncStatusState(
          status: SyncStatus.partiallySynced,
          hasIncompleteRead: true,
          hasRetriableRead: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SyncIncompleteReadBand), findsOneWidget);
      expect(find.text(_titreEtatSynchro), findsOneWidget);
    });

    testWidgets('un tic qui ne change QUE l\'horodatage ne repeint rien', (
      tester,
    ) async {
      // `buildWhen` borne la reconstruction aux deux champs lus : une feuille
      // qui se repeint sous les doigts de l'utilisateur à chaque tic serait le
      // remède pire que le mal.
      await ouvrirLaFeuille(tester, hasIncompleteRead: true);
      final avant = tester.widget<SyncIncompleteReadBand>(
        find.byType(SyncIncompleteReadBand),
      );

      syncStatusCubit.tick(
        const SyncStatusState(
          status: SyncStatus.synced,
          hasIncompleteRead: true,
          lastSyncAtMs: 123456,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<SyncIncompleteReadBand>(
          find.byType(SyncIncompleteReadBand),
        ),
        same(avant),
      );
    });
  });
}
