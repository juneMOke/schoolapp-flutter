import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/components/status/web_online_gate.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({required this.online});

  bool online;
  final StreamController<bool> changes = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onStatusChange => changes.stream;
}

/// Le voile de la version web, en ligne seulement. `enabled` est forcé :
/// `kIsWeb` est faux sous `flutter test`.
void main() {
  late _MockSyncStatusCubit cubit;
  late StreamController<SyncStatusState> states;
  late List<bool> guard;

  const synced = SyncStatusState(status: SyncStatus.synced);
  const pending = SyncStatusState(status: SyncStatus.pendingUpload);

  setUp(() {
    cubit = _MockSyncStatusCubit();
    // Broadcast : sa fermeture n'attend pas d'auditeur — le voile désactivé
    // n'écoute jamais le cubit, et `close()` pendrait le tearDown.
    states = StreamController<SyncStatusState>.broadcast();
    whenListen(cubit, states.stream, initialState: synced);
    guard = [];
  });

  tearDown(() => states.close());

  Widget harness(_FakeConnectivity connectivity, {bool enabled = true}) =>
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: WebOnlineGate(
            connectivity: connectivity,
            enabled: enabled,
            onUnloadGuardChanged: guard.add,
            child: const Scaffold(body: Text('écran')),
          ),
        ),
      );

  testWidgets('hors ligne : le voile couvre l application sans la démonter', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_FakeConnectivity(online: false)));
    await tester.pump();

    expect(find.text('Connexion requise'), findsOneWidget);
    expect(find.text('écran', skipOffstage: false), findsOneWidget);
  });

  testWidgets('le réseau revenu, le voile se lève seul', (tester) async {
    final connectivity = _FakeConnectivity(online: false);
    await tester.pumpWidget(harness(connectivity));
    await tester.pump();

    connectivity.changes.add(true);
    await tester.pump();

    expect(find.text('Connexion requise'), findsNothing);
    expect(find.text('écran'), findsOneWidget);
  });

  testWidgets('un envoi en attente retient l onglet, puis le relâche', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_FakeConnectivity(online: true)));
    await tester.pump();
    expect(guard, [false]);

    states.add(pending);
    await tester.pump();
    states.add(synced);
    await tester.pump();

    expect(guard, [false, true, false]);
  });

  testWidgets('du travail retenu garde l onglet même « synchronisé »', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_FakeConnectivity(online: true)));
    await tester.pump();

    states.add(
      const SyncStatusState(status: SyncStatus.synced, hasHeldWork: true),
    );
    await tester.pump();

    expect(guard.last, isTrue);
  });

  testWidgets('hors du web : transparent, rien n est retenu', (tester) async {
    await tester.pumpWidget(
      harness(_FakeConnectivity(online: false), enabled: false),
    );
    await tester.pump();

    expect(find.text('Connexion requise'), findsNothing);
    expect(guard, isEmpty);
  });
}
