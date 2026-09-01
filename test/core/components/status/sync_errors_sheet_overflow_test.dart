import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/sync_errors_sheet.dart';
import 'package:school_app_flutter/core/components/status/sync_held_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_incomplete_read_band.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Non-régression du débordement de la feuille de synchro sur écran court.
///
/// Le corps de la feuille vit dans un `Expanded` — sa hauteur est ce qui RESTE.
/// Quand la LECTURE est incomplète (« Partiellement à jour »), et là seulement,
/// `SyncIncompleteReadBand` s'installe au-dessus de lui et lui prend ~190 px,
/// bouton « Réessayer » compris. Les trois états non-listes du corps, eux, ont
/// une hauteur plancher que rien ne négocie : 212 px pour le squelette, 380 px
/// pour les cartes vide/erreur. Sous 660 px de haut, le squelette débordait de
/// 62 px et la carte « Aucune écriture en échec » — l'état d'arrivée le plus
/// courant de cette porte d'entrée, puisque l'outbox est le plus souvent vide —
/// de bien davantage.
///
/// La hauteur de 660 px n'est pas décorative : c'est celle qui reproduit le
/// débordement exact rapporté. Ne pas la remonter pour faire passer un test.
class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit(super.initialState);

  @override
  Future<void> syncNow({bool evaluateRevocation = true}) async {}

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

/// Hauteur qui reproduisait le débordement de 62 px (cf. docstring).
const _ecranCourt = Size(960, 660);

void main() {
  /// Ouvre la feuille par la porte « lecture incomplète » : bandeau présent,
  /// et rejouable — la variante la plus haute, donc la plus contraignante.
  Future<void> ouvrirLaFeuille(
    WidgetTester tester, {
    required OutboxErrorsState outbox,
    Size taille = _ecranCourt,
    bool lectureIncomplete = true,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    getIt.registerFactory<OutboxErrorsCubit>(
      () => _FakeOutboxErrorsCubit(outbox),
    );
    getIt.registerSingleton<CurrentUserContext>(
      CurrentUserContext()..set('uid-moi'),
    );
    addTearDown(getIt.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SyncStatusCubit>.value(
          value: _FakeSyncStatusCubit(
            SyncStatusState(
              status: lectureIncomplete
                  ? SyncStatus.partiallySynced
                  : SyncStatus.pendingUpload,
              hasIncompleteRead: lectureIncomplete,
              hasRetriableRead: lectureIncomplete,
            ),
          ),
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
    // Jamais `pumpAndSettle` : le shimmer du squelette tourne en boucle et ne
    // se stabilise pas. On laisse l'ouverture de la modale s'achever, c'est
    // tout ce dont on a besoin.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('écran court + bandeau « lecture incomplète »', () {
    testWidgets('le squelette de chargement ne déborde pas', (tester) async {
      await ouvrirLaFeuille(
        tester,
        outbox: const OutboxErrorsState(status: OutboxErrorsStatus.loading),
      );

      expect(find.byType(SyncIncompleteReadBand), findsOneWidget);
      expect(find.byType(EteeloListSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la carte « aucune écriture » ne déborde pas', (tester) async {
      await ouvrirLaFeuille(
        tester,
        outbox: const OutboxErrorsState(status: OutboxErrorsStatus.loaded),
      );

      expect(find.byType(EteeloEmptyResult), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la carte d\'erreur de lecture locale ne déborde pas', (
      tester,
    ) async {
      await ouvrirLaFeuille(
        tester,
        outbox: const OutboxErrorsState(status: OutboxErrorsStatus.failure),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('le bas de la carte reste ATTEIGNABLE, pas seulement rogné', (
      tester,
    ) async {
      // Un `ClipRect` aurait aussi fait taire l'assertion, en cachant la moitié
      // de la carte. Ce que le correctif promet, c'est qu'on peut y accéder.
      await ouvrirLaFeuille(
        tester,
        outbox: const OutboxErrorsState(status: OutboxErrorsStatus.loaded),
      );

      final avant = tester.getTopLeft(find.byType(EteeloEmptyResult)).dy;
      // Le geste part du VIEWPORT, pas de la carte : celle-ci est plus haute
      // que la zone visible, son centre tombe hors de l'écran.
      final vue = find.byType(SingleChildScrollView);
      expect(vue, findsOneWidget);
      await tester.dragFrom(tester.getCenter(vue), const Offset(0, -150));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byType(EteeloEmptyResult)).dy,
        lessThan(avant),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('porte « à envoyer » : des écritures RETENUES, aucune erreur', () {
    /// Une écriture à moi que le moteur retient — la file de la pastille
    /// « à envoyer », qui n'a rien à lister et tout à dire sous la liste.
    OutboxEntry retenue(String id) => OutboxEntry(
      id: id,
      aggregateType: 'PAYMENT',
      aggregateId: 'pay-$id',
      operation: OutboxOperation.create,
      payload: '{}',
      createdAt: DateTime(2026, 8, 30).millisecondsSinceEpoch,
      lastError: "En attente de l'inscription de l'élève",
    );

    OutboxErrorsState fileRetenue(int combien) => OutboxErrorsState(
      status: OutboxErrorsStatus.loaded,
      held: List.generate(combien, (i) => retenue('held-$i')),
    );

    testWidgets('la section des retenues ne déborde pas', (tester) async {
      // La liste d'erreurs est VIDE : son `Expanded` ne rend rien au budget,
      // et l'entête + les cartes de retenue sont à elles seules tout le
      // contenu. C'est le débordement rapporté (101 px) : sans bandeau de
      // lecture, il faut cinq retenues pour épuiser les 660 px — trois y
      // tiennent encore, et le test serait vert des deux côtés du correctif.
      await ouvrirLaFeuille(
        tester,
        outbox: fileRetenue(5),
        lectureIncomplete: false,
      );

      expect(find.byType(SyncIncompleteReadBand), findsNothing);
      expect(find.byType(SyncHeldTile), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('elle ne déborde pas non plus sous le bandeau de lecture', (
      tester,
    ) async {
      await ouvrirLaFeuille(tester, outbox: fileRetenue(3));

      expect(find.byType(SyncIncompleteReadBand), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la dernière retenue reste ATTEIGNABLE au défilement', (
      tester,
    ) async {
      // Un `ClipRect` ferait taire l'assertion en cachant le bas de la
      // section. Ce que le correctif promet, c'est qu'on peut l'atteindre.
      await ouvrirLaFeuille(
        tester,
        outbox: fileRetenue(6),
        lectureIncomplete: false,
      );

      final vue = find.byType(CustomScrollView);
      expect(vue, findsOneWidget);
      final avant = tester.getTopLeft(find.byType(SyncHeldTile).first).dy;
      await tester.dragFrom(tester.getCenter(vue), const Offset(0, -200));
      await tester.pump();

      expect(
        tester.getTopLeft(find.byType(SyncHeldTile).first).dy,
        lessThan(avant),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('quand la place est là, la zone est toujours occupée en entier', (
    tester,
  ) async {
    // Non-régression du rendu : le corps recevait une contrainte serrée de
    // l'`Expanded` et la carte s'étirait jusqu'en bas. Le rendre défilant ne
    // doit pas le laisser retomber sur sa hauteur intrinsèque de 212 px, ce qui
    // ouvrirait un trou sous le squelette sur les grands écrans.
    await ouvrirLaFeuille(
      tester,
      outbox: const OutboxErrorsState(status: OutboxErrorsStatus.loading),
      taille: const Size(1000, 1600),
    );

    expect(
      tester.getSize(find.byType(EteeloListSkeleton)).height,
      greaterThan(212),
    );
    expect(tester.takeException(), isNull);
  });
}
