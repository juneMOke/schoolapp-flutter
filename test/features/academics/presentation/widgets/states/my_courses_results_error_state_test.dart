import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/my_courses_results_error_state.dart';
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

  testWidgets('réseau : affiche le titre et propose « Réessayer »', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      host(
        MyCoursesResultsErrorState(
          type: CourseErrorType.network,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Pas de connexion'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('403 : contact admin, jamais « Réessayer »', (tester) async {
    await tester.pumpWidget(
      host(
        MyCoursesResultsErrorState(
          type: CourseErrorType.forbidden,
          onRetry: () {},
          onContactAdmin: () {},
        ),
      ),
    );

    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text("Contacter l'administrateur"), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
