import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/core/web/new_tab.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Tous les droits déclarés : ces tests portent sur la structure de la coquille
/// (sidebar ancrée, tiroir, hamburger), pas sur le filtrage — couvert par
/// `module_access_registry_test.dart`. Sans droits, l'arborescence se réduirait
/// à l'Accueil et il n'y aurait plus de menu à replier.
const _tousDroits = <String>[
  'enrollment.read',
  'enrollment.stats.read',
  'finance.charge.read',
  'finance.stats.read',
  'classroom.read',
  'classroom.stats.read',
  'attendance.read',
  'attendance.stats.read',
  'discipline.read',
  'academics.course.read',
  'academics.result.read',
  'schedule.read',
  'editique.read',
];

void main() {
  // La barre supérieure monte la pastille de synchro globale
  // (BlocBuilder<SyncStatusCubit>) fournie à la racine en production ; ici on
  // fournit un cubit mocké figé sur « synced ». L'`AuthBloc` est requis depuis
  // ADR-014 : la coquille construit son arborescence sur ses permissions.
  Widget buildHarness() {
    final syncStatusCubit = _MockSyncStatusCubit();
    whenListen(
      syncStatusCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );

    final authBloc = _MockAuthBloc();
    const authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: _tousDroits,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: authState,
    );

    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SyncStatusCubit>.value(value: syncStatusCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const HomePage(),
      ),
    );
  }

  late List<Uri> opened;

  setUp(() {
    opened = [];
    NewTab.enabled = true;
    NewTab.launch = (uri) async => opened.add(uri);
  });

  tearDown(() {
    NewTab.enabled = false;
    NewTab.launch = (_) async {};
  });

  Future<void> openFinances(WidgetTester tester) async {
    // La vue elle-même : `MediaQuery` décide de l'ouverture de la barre.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finances').first);
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl+clic ouvre l\'écran dans un nouvel onglet, sans quitter '
      'celui-ci', (tester) async {
    await openFinances(tester);
    final before = find.text('Facturations').evaluate().length;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('Facturations').first);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(opened.single.path, '/home/facturations');
    // L'écran courant n'a pas changé : la facturation n'apparaît pas en
    // plus dans le fil d'Ariane.
    expect(find.text('Facturations').evaluate().length, before);
  });

  testWidgets('le clic molette ouvre aussi un nouvel onglet', (tester) async {
    await openFinances(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Facturations').first),
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(opened.single.path, '/home/facturations');
  });
}
