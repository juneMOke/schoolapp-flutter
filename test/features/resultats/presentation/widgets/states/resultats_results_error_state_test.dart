import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/states/resultats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (ctx) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  testWidgets('403 (forbidden) → « Contacter » et jamais « Réessayer »', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ResultatsResultsErrorState(
          type: ResultatsErrorType.forbidden,
          onRetry: () {},
          onContactAdmin: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Contacter l\'administrateur'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('réseau → action « Réessayer »', (tester) async {
    await tester.pumpWidget(
      _host(
        ResultatsResultsErrorState(
          type: ResultatsErrorType.network,
          onRetry: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('401 (invalidCredentials) → « Se reconnecter »', (tester) async {
    await tester.pumpWidget(
      _host(
        ResultatsResultsErrorState(
          type: ResultatsErrorType.invalidCredentials,
          onReconnect: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Se reconnecter'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
