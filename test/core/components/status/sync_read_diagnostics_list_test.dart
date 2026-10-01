import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_read_diagnostics_list.dart';
import 'package:school_app_flutter/core/offline/pull_diagnostic.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets('une ligne par flux, avec sa cause et son message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SyncReadDiagnosticsList(
            diagnostics: [
              PullDiagnostic(
                'finance_payments',
                PullDiagnosticKind.failed,
                detail: 'timeout 12 s',
              ),
              PullDiagnostic('hr.payrolls', PullDiagnosticKind.notPulled),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Flux en défaut'), findsOneWidget);
    expect(
      find.text('finance_payments — Échec : timeout 12 s'),
      findsOneWidget,
    );
    expect(
      find.text(
        'hr.payrolls — Annoncé par le serveur, non tiré par cette version',
      ),
      findsOneWidget,
    );
  });
}
