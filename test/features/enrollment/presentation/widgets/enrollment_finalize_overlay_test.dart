import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_finalize_overlay.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockOfflineBloc
    extends MockBloc<EnrollmentOfflineEvent, EnrollmentOfflineState>
    implements EnrollmentOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

class _OutcomeHolder {
  EnrollmentFinalizeOutcome? value;
}

void main() {
  late _MockOfflineBloc offlineBloc;
  late _MockSyncStatusCubit syncCubit;
  late StreamController<EnrollmentOfflineState> states;

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    states = StreamController<EnrollmentOfflineState>.broadcast();
    whenListen(
      offlineBloc,
      states.stream,
      initialState: const EnrollmentOfflineInitial(),
    );

    syncCubit = _MockSyncStatusCubit();
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    when(() => syncCubit.notifyLocalWrite()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await states.close();
  });

  // `open` déclenche l'ouverture puis rend la main tout de suite (le futur de
  // `showEnrollmentFinalizeOverlay` ne se résout qu'à la fermeture) : l'issue
  // finale est lue via ce holder mutable, inspecté APRÈS interaction.
  Future<_OutcomeHolder> open(WidgetTester tester) async {
    final holder = _OutcomeHolder();
    await tester.pumpWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: syncCubit,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  holder.value = await showEnrollmentFinalizeOverlay(
                    context: context,
                    offlineBloc: offlineBloc,
                    enrollmentId: 'enr-1',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    return holder;
  }

  testWidgets('démarre en processing et dispatche la finalisation', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Validation de l\'inscription…'), findsOneWidget);
    expect(find.byType(EteeloResultMedallion), findsOneWidget);
    verify(
      () => offlineBloc.add(const FinalizeDraftRequested('enr-1')),
    ).called(1);
  });

  testWidgets('au succès : médaillon + message + pastille de synchro', (
    tester,
  ) async {
    final holder = await open(tester);

    states.add(const EnrollmentDraftFinalizedPendingSync('enr-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // halo/anim succès

    expect(find.text('Inscription validée'), findsOneWidget);
    expect(
      find.text('Inscription enregistrée — en attente de synchronisation'),
      findsOneWidget,
    );
    verify(() => syncCubit.notifyLocalWrite()).called(1);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(holder.value, EnrollmentFinalizeOutcome.succeeded);
  });

  testWidgets(
    'à l\'échec : EteeloErrorResult + Réessayer relance la finalisation',
    (tester) async {
      await open(tester);

      states.add(const EnrollmentDraftFinalizeError('boom'));
      await tester.pump();

      expect(find.byType(EteeloErrorResult), findsOneWidget);
      expect(find.text('Échec de la validation'), findsOneWidget);
      expect(find.text('Échec de l\'enregistrement local'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      // Dispatch initial + relance = 2 fois.
      verify(
        () => offlineBloc.add(const FinalizeDraftRequested('enr-1')),
      ).called(2);
    },
  );

  testWidgets('à l\'échec : Fermer referme la popin (outcome=failed)', (
    tester,
  ) async {
    final holder = await open(tester);

    states.add(const EnrollmentDraftFinalizeError('boom'));
    await tester.pump();

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(holder.value, EnrollmentFinalizeOutcome.failed);
  });

  testWidgets('pendant le traitement : la popin ne peut pas être fermée', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Fermer'), findsNothing);
    expect(find.text('Continuer'), findsNothing);
  });
}
