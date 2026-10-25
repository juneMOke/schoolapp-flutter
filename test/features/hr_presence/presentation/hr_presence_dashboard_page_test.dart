import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_rate_bars.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_dashboard_notices.dart';

import '../hr_presence_builders.dart';
import 'hr_presence_dashboard_harness.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SubMenuItemSelected(menuId: '', subMenuId: '', title: ''),
    );
  });

  testWidgets('les quatre chiffres, le graphique et la liste du serveur', (
    tester,
  ) async {
    await pumpHrPresenceDashboard(tester);

    expect(find.text('TAUX DE PRÉSENCE'), findsOneWidget);
    expect(find.text('90 %'), findsWidgets);
    expect(find.text('18 présences sur 20 pointages'), findsOneWidget);
    expect(find.text('31 min · ponctualité 89 %'), findsOneWidget);
    expect(find.text('signalées sur le bulletin'), findsOneWidget);
    expect(find.text('Présence jour par jour'), findsOneWidget);
    expect(find.byType(PresenceRateBars), findsOneWidget);
    expect(
      find.text('Pointage du personnel · Ce mois · octobre 2026'),
      findsOneWidget,
    );
    // L'ordre du serveur, jamais retrié.
    final names = ['MWAMBA Clarisse', 'KALALA Didier', 'MAYALA Ruth'];
    final tops = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
    expect(tops, [...tops]..sort());
  });

  testWidgets('chaque barre a sa phrase ; un jour sans pointage le dit', (
    tester,
  ) async {
    await pumpHrPresenceDashboard(tester);

    expect(
      find.bySemanticsLabel(
        RegExp(r'mercredi 21 octobre 2026 · présents 86 % \(8/10\)'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('vendredi 23 octobre 2026 · aucun pointage'),
      findsOneWidget,
    );
  });

  testWidgets('la recherche filtre la liste ; « Tout afficher » la rend', (
    tester,
  ) async {
    await pumpHrPresenceDashboard(tester);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Aucun agent ne correspond'), findsOneWidget);
    expect(find.text('Rien pour « zzz ».'), findsOneWidget);

    await tester.tap(find.text('Tout afficher'));
    await tester.pumpAndSettle();
    expect(find.text('KALALA Didier'), findsOneWidget);
  });

  testWidgets('le PDF reprend la fenêtre et la recherche de la liste', (
    tester,
  ) async {
    final h = await pumpHrPresenceDashboard(tester);
    await tester.enterText(find.byType(TextField).first, 'kalala');
    await tester.pumpAndSettle();

    await tester.tap(find.text('PDF'));
    // La visionneuse anime son chargement : pas de `pumpAndSettle`.
    await tester.pump();
    await tester.pump();

    expect(h.server.printed.single, (
      DashboardWindow(from: DateTime(2026, 10), to: DateTime(2026, 10, 23)),
      'kalala',
    ));
    expect(find.byType(EteeloDocumentViewerView), findsOneWidget);
  });

  testWidgets('les non-pointés : l\'alerte, et « Compléter » mène au '
      'registre', (tester) async {
    final h = await pumpHrPresenceDashboard(
      tester,
      server: FakeHrAttendanceStats(dashboardOf(kpis: kpisOf(unscored: 6))),
    );

    expect(find.text('6 jours-agent non pointés'), findsOneWidget);
    await tester.tap(find.text('Compléter le pointage'));
    final event =
        verify(() => h.navigation.add(captureAny())).captured.single
            as SubMenuItemSelected;
    expect(event.subMenuId, MenuConstants.hrPresenceRegisterId);
  });

  testWidgets('en lecture seule : ni « Pointer », ni « Compléter »', (
    tester,
  ) async {
    await pumpHrPresenceDashboard(
      tester,
      server: FakeHrAttendanceStats(dashboardOf(kpis: kpisOf(unscored: 6))),
      permissions: [Perm.hrAttendanceRead.wire],
    );

    expect(find.byType(HrPresenceUnscoredNotice), findsOneWidget);
    expect(find.text('Compléter le pointage'), findsNothing);
    expect(find.text('Pointer'), findsNothing);
  });

  testWidgets('les pointages encore sur la tablette sont annoncés', (
    tester,
  ) async {
    await pumpHrPresenceDashboard(tester, unsynced: 4);

    expect(find.text('4 pointages encore sur la tablette'), findsOneWidget);
  });

  testWidgets('aucun jour de classe : le vide, et le retour à « Ce mois »', (
    tester,
  ) async {
    final server = FakeHrAttendanceStats(
      dashboardOf(classDays: 0, series: const [], staff: const []),
    );
    final h = await pumpHrPresenceDashboard(tester, server: server);
    await tester.tap(find.text('Cette semaine'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun jour de classe sur cette période'), findsOneWidget);
    server.answer = dashboardOf();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Ce mois').last);
    await tester.pumpAndSettle();
    expect(h.cubit.state.window!.from, DateTime(2026, 10));
    expect(find.text('TAUX DE PRÉSENCE'), findsOneWidget);
  });

  testWidgets('hors ligne : l\'erreur réseau et « Réessayer »', (tester) async {
    final server = FakeHrAttendanceStats(dashboardOf())
      ..failure = const NetworkFailure('hors ligne');
    await pumpHrPresenceDashboard(tester, server: server);

    expect(find.byType(EteeloErrorResult), findsOneWidget);
    server.failure = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('TAUX DE PRÉSENCE'), findsOneWidget);
  });

  testWidgets('un 403 ne propose pas « Réessayer »', (tester) async {
    await pumpHrPresenceDashboard(
      tester,
      server: FakeHrAttendanceStats(dashboardOf())
        ..failure = const UnauthorizedFailure('403'),
    );

    expect(find.byType(EteeloErrorResult), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('au-delà de 31 jours de classe, mois par mois', (tester) async {
    await pumpHrPresenceDashboard(
      tester,
      server: FakeHrAttendanceStats(
        dashboardOf(
          granularity: HrAttendanceGranularity.month,
          series: [barOf('2026-09', rate: 95), barOf('2026-10', rate: 91)],
        ),
      ),
    );

    expect(find.text('Présence mois par mois'), findsOneWidget);
    expect(find.text('sept.'), findsOneWidget);
    expect(find.text('oct.'), findsOneWidget);
  });

  group('l\'adresse', () {
    testWidgets('une période choisie s\'inscrit ; « Ce mois » la rend nue', (
      tester,
    ) async {
      final h = await pumpHrPresenceDashboard(
        tester,
        location: '/rh-presences/tableau',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cette semaine'));
      await tester.pumpAndSettle();
      expect(h.address, '/rh-presences/tableau?periode=week');

      await tester.tap(find.text('Ce mois'));
      await tester.pumpAndSettle();
      expect(h.address, '/rh-presences/tableau');
    });

    testWidgets('un lien rouvre sa période précise, bornes inversées '
        'remises dans l\'ordre', (tester) async {
      final h = await pumpHrPresenceDashboard(
        tester,
        location:
            '/rh-presences/tableau?periode=custom&du=2026-10-09&au=2026-10-05',
      );
      await tester.pumpAndSettle();

      expect(
        h.server.asked.last,
        DashboardWindow(from: DateTime(2026, 10, 5), to: DateTime(2026, 10, 9)),
      );
    });
  });
}
