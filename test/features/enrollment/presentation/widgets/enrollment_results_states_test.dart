import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_loading_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHost(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('empty state affiche les criteres et actions', (tester) async {
    await tester.pumpWidget(
      buildHost(
        EnrollmentResultsEmptyState(
          criteria: const ['Prenom: Jean', 'Nom: Doe'],
          onReset: () {},
          onCreateEnrollment: () {},
        ),
      ),
    );

    expect(find.byType(Chip), findsNWidgets(2));
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('error state reseau declenche retry', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      buildHost(
        EnrollmentResultsErrorState(
          type: EnrollmentErrorType.network,
          onRetry: () => retried = true,
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('loading skeleton supporte table et grille', (tester) async {
    await tester.pumpWidget(
      buildHost(const EnrollmentResultsLoadingSkeleton(isGrid: false)),
    );
    expect(find.byType(GridView), findsNothing);

    await tester.pumpWidget(
      buildHost(const EnrollmentResultsLoadingSkeleton(isGrid: true)),
    );
    expect(find.byType(GridView), findsOneWidget);
  });
}
