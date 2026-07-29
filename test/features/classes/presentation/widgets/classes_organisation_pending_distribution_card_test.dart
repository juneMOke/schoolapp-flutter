import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_pending_distribution_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required ClassroomStatus overviewStatus,
    bool isDistributing = false,
    int studentsToDistribute = 24,
    int maleCount = 13,
    int femaleCount = 11,
    VoidCallback? onDistributionRequested,
    SyncStatus syncStatus = SyncStatus.synced,
  }) async {
    final syncStatusCubit = _MockSyncStatusCubit();
    whenListen(
      syncStatusCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: SyncStatusState(status: syncStatus),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SyncStatusCubit>.value(
          value: syncStatusCubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClassesOrganisationPendingDistributionCard(
                isDistributing: isDistributing,
                overviewStatus: overviewStatus,
                levelName: '5e',
                studentsToDistribute: studentsToDistribute,
                maleCount: maleCount,
                femaleCount: femaleCount,
                onDistributionRequested: onDistributionRequested ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('affiche titre, effectif et pastilles G/F quand chargé', (
    tester,
  ) async {
    await pumpCard(tester, overviewStatus: ClassroomStatus.success);

    expect(find.text('Niveau pas encore réparti'), findsOneWidget);
    expect(find.text('G · 13'), findsOneWidget);
    expect(find.text('F · 11'), findsOneWidget);
    // Le message rappelle l'effectif et le niveau.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? '').contains('24') &&
            (widget.data ?? '').contains('5e'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('le bouton primaire porte le libellé par genre et est actif', (
    tester,
  ) async {
    var tapped = 0;
    await pumpCard(
      tester,
      overviewStatus: ClassroomStatus.success,
      onDistributionRequested: () => tapped++,
    );

    final button = find.widgetWithText(
      FilledButton,
      'Lancer la répartition par genre',
    );
    expect(button, findsOneWidget);

    await tester.tap(button);
    expect(tapped, 1);
  });

  testWidgets(
    'pendant le chargement de l\'overview : spinner + bouton inactif',
    (tester) async {
      await pumpCard(tester, overviewStatus: ClassroomStatus.loading);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('pendant la répartition : bouton inactif', (tester) async {
    await pumpCard(
      tester,
      overviewStatus: ClassroomStatus.success,
      isDistributing: true,
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('hors-ligne : bouton inactif + message adapté affiché', (
    tester,
  ) async {
    var tapped = 0;
    await pumpCard(
      tester,
      overviewStatus: ClassroomStatus.success,
      onDistributionRequested: () => tapped++,
      syncStatus: SyncStatus.offline,
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(
      find.text(
        'Vous semblez hors-ligne. Une connexion est nécessaire pour '
        'lancer la répartition.',
      ),
      findsOneWidget,
    );

    // Un tap sur un bouton désactivé n'a aucun effet.
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(tapped, 0);
  });

  testWidgets(
    'échec du calcul offline : bouton inactif + message adapté, jamais un '
    'effectif affiché comme fiable',
    (tester) async {
      var tapped = 0;
      await pumpCard(
        tester,
        overviewStatus: ClassroomStatus.failure,
        studentsToDistribute: 0,
        maleCount: 0,
        femaleCount: 0,
        onDistributionRequested: () => tapped++,
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(
        find.text(
          "Impossible de calculer l'effectif à répartir pour le moment. "
          'Réessayez plus tard.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(tapped, 0);
    },
  );

  testWidgets(
    'en ligne (synced/syncing/pendingUpload/syncConflict/authRequired) : '
    'pas de message hors-ligne, bouton actif',
    (tester) async {
      for (final status in [
        SyncStatus.synced,
        SyncStatus.syncing,
        SyncStatus.pendingUpload,
        SyncStatus.syncConflict,
        SyncStatus.authRequired,
      ]) {
        await pumpCard(
          tester,
          overviewStatus: ClassroomStatus.success,
          syncStatus: status,
        );

        expect(
          find.byIcon(Icons.cloud_off),
          findsNothing,
          reason: 'status=$status',
        );
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull, reason: 'status=$status');
      }
    },
  );
}
