import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_report_cubit.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_entries_report_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockReportCubit extends MockCubit<EnrollmentEntriesReportState>
    implements EnrollmentEntriesReportCubit {}

Future<_MockReportCubit> _pump(
  WidgetTester tester, {
  EnrollmentEntriesReportState initial = const EnrollmentEntriesReportState(),
  Stream<EnrollmentEntriesReportState> states = const Stream.empty(),
  EnrollmentStatsWindow window = const EnrollmentStatsWindow.week(),
}) async {
  final cubit = _MockReportCubit();
  whenListen(cubit, states, initialState: initial);
  when(() => cubit.isClosed).thenReturn(false);
  when(
    () => cubit.download(window: any(named: 'window')),
  ).thenAnswer((_) async {});
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: Center(
          child: BlocProvider<EnrollmentEntriesReportCubit>.value(
            value: cubit,
            child: EnrollmentEntriesReportButton(window: window),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    registerFallbackValue(const EnrollmentStatsWindow.year());
    l10n = lookupAppLocalizations(const Locale('fr'));
  });

  group('le bouton dit dans quel état il est', () {
    testWidgets('armé : l\'appui demande la fenêtre de la LISTE', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        window: const EnrollmentStatsWindow.month(),
      );

      expect(find.text('PDF'), findsOneWidget);
      await tester.tap(find.text('PDF'));

      verify(
        () => cubit.download(window: const EnrollmentStatsWindow.month()),
      ).called(1);
    });

    testWidgets('en préparation : il le dit, et ne répond plus', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        initial: const EnrollmentEntriesReportState(
          status: EnrollmentEntriesReportStatus.preparing,
        ),
      );

      expect(find.text('Préparation…'), findsOneWidget);
      await tester.tap(find.text('Préparation…'));

      verifyNever(() => cubit.download(window: any(named: 'window')));
    });

    testWidgets('pendant l\'attente d\'un 429 : « Patientez… »', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        initial: const EnrollmentEntriesReportState(
          status: EnrollmentEntriesReportStatus.cooldown,
          retryAfter: Duration(seconds: 60),
        ),
      );

      expect(find.text('Patientez…'), findsOneWidget);
      await tester.tap(find.text('Patientez…'));

      verifyNever(() => cubit.download(window: any(named: 'window')));
    });
  });

  group('la remise', () {
    testWidgets('un échec se dit par un toast, puis l\'état se vide', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        states: Stream.value(
          const EnrollmentEntriesReportState(
            failure: UnauthorizedFailure('403'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(l10n.enrollmentDashboardEntriesReportForbidden),
        findsOneWidget,
      );
      verify(() => cubit.acknowledge()).called(1);
    });
  });

  group('ce qu\'on dit quand il n\'y a pas de document', () {
    String say(Failure failure, {Duration? retryAfter}) =>
        EnrollmentEntriesReportButton.message(
          failure,
          EnrollmentEntriesReportState(retryAfter: retryAfter),
          l10n,
        );

    test('429 : attendre, et combien', () {
      expect(
        say(
          const TooManyRequestsFailure(),
          retryAfter: const Duration(seconds: 45),
        ),
        contains('45 secondes'),
      );
    });

    test('403 : le droit qui manque', () {
      expect(
        say(const UnauthorizedFailure('403')),
        l10n.enrollmentDashboardEntriesReportForbidden,
      );
    });

    test('plafond reconnu à son code : nos mots, ses chiffres', () {
      const failure = ApiValidationFailure(
        code: ApiErrorCode.businessRule,
        serverMessage: 'Cette fenêtre contient 7213 inscriptions.',
        detailCode: 'REPORT_LINE_CAP',
        details: <String, dynamic>{'lines': 7213, 'cap': 5000},
      );

      expect(
        say(failure),
        l10n.enrollmentDashboardEntriesReportTooLarge(7213, 5000),
      );
    });

    test('plafond arrivé SANS son code : la phrase du serveur', () {
      // Ce que rend `EditiqueFailureMapper` sur une route binaire : il
      // rebâtit une `ValidationFailure` nue, le `detailCode` s'est perdu. La
      // phrase porte le compte réel — c'est elle qu'on montre.
      const sentence =
          'Cette fenêtre contient 7213 inscriptions ; le rapport PDF est '
          'plafonné à 5000. Resserrez la période.';

      expect(say(const ValidationFailure(sentence)), sentence);
    });

    test(
      'le message par défaut de ValidationFailure n\'est pas une phrase',
      () {
        // Une constante anglaise, pas un mot du serveur.
        expect(
          say(const ValidationFailure()),
          l10n.enrollmentDashboardEntriesReportFailed,
        );
      },
    );

    test('une coupure : le message générique, dans notre langue', () {
      expect(
        say(const NetworkFailure('Network error occurred')),
        l10n.enrollmentDashboardEntriesReportFailed,
      );
    });
  });
}
