import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/states/schedule_results_error_state.dart';
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
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('réseau : titre + action « Réessayer »', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      host(
        ScheduleResultsErrorState(
          type: ScheduleErrorType.network,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Connexion interrompue'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('403 : contact admin, jamais « Réessayer »', (tester) async {
    await tester.pumpWidget(
      host(
        ScheduleResultsErrorState(
          type: ScheduleErrorType.forbidden,
          onRetry: () {},
          onContactAdmin: () {},
        ),
      ),
    );

    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text("Contacter l'administrateur"), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('401 : propose « Se reconnecter »', (tester) async {
    await tester.pumpWidget(
      host(
        ScheduleResultsErrorState(
          type: ScheduleErrorType.invalidCredentials,
          onReconnect: () {},
        ),
      ),
    );

    expect(find.text('Session expirée'), findsOneWidget);
    expect(find.text('Se reconnecter'), findsOneWidget);
  });

  testWidgets('500 : affiche le code incident', (tester) async {
    await tester.pumpWidget(
      host(
        ScheduleResultsErrorState(
          type: ScheduleErrorType.server,
          incidentCode: 'ABC123',
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Erreur serveur'), findsOneWidget);
    expect(find.textContaining('ABC123'), findsOneWidget);
  });
}
