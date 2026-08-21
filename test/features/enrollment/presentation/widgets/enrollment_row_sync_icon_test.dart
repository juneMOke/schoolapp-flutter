import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_state_icon.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_result_card.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Picto d'état de synchro par ligne de listing : coche verte (acquitté),
/// sablier orange (en file), triangle rouge (refusé, non rejoué). Rien pour un
/// brouillon (le badge « Brouillon » le dit déjà) ni pour un candidat du vivier
/// (pas encore de dossier local, donc pas d'axe synchro).
void main() {
  Widget harness(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 800, child: child)),
    ),
  );

  EnrollmentSummary rowWith(SyncState? syncState) => EnrollmentSummary(
    enrollmentId: 'enr-1',
    enrollmentCode: 'ENR-001',
    status: 'IN_PROGRESS',
    syncState: syncState,
    student: const StudentSummary(
      id: 'stu-1',
      firstName: 'Jean',
      lastName: 'Kanku',
      surname: 'Mbuyi',
      dateOfBirth: '2012-05-20',
      gender: Gender.male,
    ),
  );

  Icon? syncIconOf(WidgetTester tester) {
    final finder = find.byType(SyncStateIcon);
    if (finder.evaluate().isEmpty) return null;
    final icons = find.descendant(of: finder, matching: find.byType(Icon));
    if (icons.evaluate().isEmpty) return null;
    return tester.widget<Icon>(icons.first);
  }

  group('vue tableau', () {
    Future<Icon?> pumpRow(WidgetTester tester, SyncState? state) async {
      await tester.pumpWidget(
        harness(
          EnrollmentDataTable(
            enrollments: <EnrollmentSummary>[rowWith(state)],
            onViewRequested: (_) {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      return syncIconOf(tester);
    }

    testWidgets('SYNCED → coche verte', (tester) async {
      final icon = await pumpRow(tester, SyncState.synced);
      expect(icon?.icon, Icons.check_circle);
      expect(icon?.color, AppColors.success);
    });

    testWidgets('PENDING_SYNC → sablier orange', (tester) async {
      final icon = await pumpRow(tester, SyncState.pendingSync);
      expect(icon?.icon, Icons.hourglass_top);
      expect(icon?.color, AppColors.warning);
    });

    testWidgets('SYNC_ERROR → triangle rouge', (tester) async {
      final icon = await pumpRow(tester, SyncState.syncError);
      expect(icon?.icon, Icons.warning_rounded);
      expect(icon?.color, AppColors.error);
    });

    testWidgets('DRAFT → aucun picto (le badge « Brouillon » suffit)', (
      tester,
    ) async {
      final icon = await pumpRow(tester, SyncState.draft);
      expect(icon, isNull);
      expect(find.text('Brouillon'), findsOneWidget);
    });

    testWidgets('candidat du vivier (syncState null) → aucun picto', (
      tester,
    ) async {
      expect(await pumpRow(tester, null), isNull);
    });
  });

  group('vue grille', () {
    testWidgets('SYNC_ERROR → triangle rouge accolé à la pastille', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          EnrollmentResultCard(
            enrollment: rowWith(SyncState.syncError),
            onTap: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(syncIconOf(tester)?.icon, Icons.warning_rounded);
    });

    testWidgets('DRAFT → aucun picto', (tester) async {
      await tester.pumpWidget(
        harness(
          EnrollmentResultCard(
            enrollment: rowWith(SyncState.draft),
            onTap: () {},
          ),
        ),
      );

      expect(syncIconOf(tester), isNull);
    });
  });

  testWidgets(
    'appui long → libellé (seule source de sens d\'un picto sans texte, et '
    'sémantique pour les lecteurs d\'écran)',
    (tester) async {
      await tester.pumpWidget(
        harness(
          EnrollmentDataTable(
            enrollments: <EnrollmentSummary>[rowWith(SyncState.syncError)],
            onViewRequested: (_) {},
          ),
        ),
      );

      await tester.longPress(find.byType(SyncStateIcon));
      await tester.pumpAndSettle();

      expect(
        find.text('Refusée par le serveur — ne repartira pas d\'elle-même'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'rendu étroit (téléphone, 2 colonnes) : picto rendu sans débordement, '
    'même accolé au badge « Brouillon » d\'une ligne dense',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: EnrollmentDataTable(
                  enrollments: <EnrollmentSummary>[
                    rowWith(SyncState.pendingSync),
                  ],
                  onViewRequested: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(syncIconOf(tester)?.icon, Icons.hourglass_top);
    },
  );

  test('isVisible : seuls les 3 états de synchro réels sont rendus', () {
    expect(SyncStateIcon.isVisible(SyncState.synced), isTrue);
    expect(SyncStateIcon.isVisible(SyncState.pendingSync), isTrue);
    expect(SyncStateIcon.isVisible(SyncState.syncError), isTrue);
    expect(SyncStateIcon.isVisible(SyncState.draft), isFalse);
    expect(SyncStateIcon.isVisible(SyncState.provisional), isFalse);
    expect(SyncStateIcon.isVisible(null), isFalse);
  });
}
