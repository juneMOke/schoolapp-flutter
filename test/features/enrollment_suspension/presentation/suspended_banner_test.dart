import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspended_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, StudentSuspension s) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SuspendedBanner(suspension: s, onReactivate: () {}),
          ),
        ),
      );

  StudentSuspension period({RecordSyncState sync = RecordSyncState.synced}) =>
      StudentSuspension(
        id: 'p',
        enrollmentId: 'e',
        studentId: 's',
        academicYearId: 'y',
        suspendedAt: DateTime(2026, 10, 2),
        reason: SuspensionReason.medical,
        precision: 'Hospitalisation',
        syncState: sync,
        syncError: sync == RecordSyncState.failed ? 'refus' : null,
      );

  testWidgets('date, motif et précision', (tester) async {
    await pump(tester, period());
    expect(
      find.textContaining(
        'Élève désactivé depuis le 2 octobre 2026 · Raison médicale — '
        'Hospitalisation.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('une réactivation refusée le dit', (tester) async {
    await pump(tester, period(sync: RecordSyncState.failed));
    expect(
      find.textContaining('La réactivation a été refusée'),
      findsOneWidget,
    );
  });

  testWidgets('tient sur un téléphone, bouton sous le texte', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, period());
    expect(tester.takeException(), isNull);
    expect(find.text('Réactiver'), findsOneWidget);
  });
}
