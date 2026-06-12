import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('reseau : icone unplug + action Reessayer', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      host(
        AttendanceResultsErrorState(
          type: AttendanceErrorType.network,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.power_off_rounded), findsOneWidget);
    expect(find.text('Pas de connexion'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('401 : icone lock + action Se reconnecter', (tester) async {
    var reconnected = false;
    await tester.pumpWidget(
      host(
        AttendanceResultsErrorState(
          type: AttendanceErrorType.unauthorized,
          onReconnect: () => reconnected = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('Session expirée'), findsOneWidget);
    expect(find.text('Se reconnecter'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);

    await tester.tap(find.text('Se reconnecter'));
    await tester.pump();
    expect(reconnected, isTrue);
  });

  testWidgets('403 : shield-alert + Contacter admin, jamais Reessayer', (
    tester,
  ) async {
    var contacted = false;
    await tester.pumpWidget(
      host(
        AttendanceResultsErrorState(
          type: AttendanceErrorType.forbidden,
          onRetry: () {},
          onContactAdmin: () => contacted = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);
    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text('Contacter l\'administrateur'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);

    await tester.tap(find.text('Contacter l\'administrateur'));
    await tester.pump();
    expect(contacted, isTrue);
  });

  testWidgets('500 : server-crash + code incident + Reessayer', (tester) async {
    await tester.pumpWidget(
      host(
        AttendanceResultsErrorState(
          type: AttendanceErrorType.server,
          incidentCode: 'AB12CD',
          onRetry: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
    expect(find.text('Erreur du serveur'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('AB12CD'), findsOneWidget);
  });
}
