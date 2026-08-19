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
}
