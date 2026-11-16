import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';

class _Sync extends MockCubit<SyncStatusState> implements SyncStatusCubit {}

/// Relire un écran de la trésorerie : la page tirée au doigt, F5 au clavier.
void main() {
  late int screen;
  late int shell;

  Future<void> pump(WidgetTester tester, {bool pull = true}) async {
    screen = 0;
    shell = 0;
    await tester.pumpWidget(
      MaterialApp(
        // Le geste de la coquille, au-dessus de la page.
        home: RefreshIndicator(
          onRefresh: () async => shell++,
          child: TreasuryRefreshScope(
            pull: pull,
            onRefresh: () async => screen++,
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: 400, child: Text('page')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tirer la page la relit, une seule fois', (tester) async {
    await pump(tester);
    await tester.fling(find.text('page'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(screen, 1);
    expect(shell, 0, reason: 'la coquille ne relance pas en double');
  });

  testWidgets('sans pull : le geste reste celui de la coquille', (
    tester,
  ) async {
    await pump(tester, pull: false);
    await tester.fling(find.text('page'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(screen, 0);
    expect(shell, 1);
  });

  testWidgets('F5 relit la page', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    expect(screen, 1);
  });

  group('relire quand la file d envoi se vide (Clôture)', () {
    late _Sync sync;
    late StreamController<SyncStatusState> states;

    setUp(() {
      sync = _Sync();
      states = StreamController<SyncStatusState>.broadcast();
      whenListen(
        sync,
        states.stream,
        initialState: const SyncStatusState(status: SyncStatus.pendingUpload),
      );
      // Le cycle se termine : la pastille passe à jour.
      when(() => sync.syncNow()).thenAnswer((_) async {
        states.add(const SyncStatusState(status: SyncStatus.syncing));
        states.add(const SyncStatusState(status: SyncStatus.synced));
      });
    });

    tearDown(() => states.close());

    Future<void> pumpClosing(WidgetTester tester) async {
      screen = 0;
      await tester.pumpWidget(
        BlocProvider<SyncStatusCubit>.value(
          value: sync,
          child: MaterialApp(
            home: TreasuryRefreshScope(
              refreshOnSynced: true,
              onRefresh: () async => screen++,
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: 400, child: Text('page')),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('la synchro terminée relit l écran', (tester) async {
      await pumpClosing(tester);
      states.add(const SyncStatusState(status: SyncStatus.synced));
      await tester.pumpAndSettle();
      expect(screen, 1);
    });

    testWidgets('tirer la page : la synchro, puis UNE lecture', (tester) async {
      await pumpClosing(tester);
      await tester.fling(find.text('page'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      verify(() => sync.syncNow()).called(1);
      expect(screen, 1, reason: 'la fin de la synchro ne relit pas en double');
    });
  });
}
