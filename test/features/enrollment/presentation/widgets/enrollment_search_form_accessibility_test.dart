import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockEnrollmentBloc extends MockBloc<EnrollmentEvent, EnrollmentState>
    implements EnrollmentBloc {}

void main() {
  late MockEnrollmentBloc enrollmentBloc;

  setUp(() {
    enrollmentBloc = MockEnrollmentBloc();
  });

  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('SearchForm action buttons keep minimum 48dp tap target', (
    tester,
  ) async {
    final initialState = const EnrollmentState.initial();
    when(() => enrollmentBloc.state).thenReturn(initialState);
    whenListen(
      enrollmentBloc,
      Stream<EnrollmentState>.value(initialState),
      initialState: initialState,
    );

    await tester.pumpWidget(
      BlocProvider<EnrollmentBloc>.value(
        value: enrollmentBloc,
        child: buildHarness(
          const SearchForm(
            academicYearId: '2025',
            status: 'IN_PROGRESS',
            showStatusFilter: false,
          ),
        ),
      ),
    );

    final searchFinder = find.widgetWithText(ElevatedButton, 'Rechercher');
    final clearFinder = find.widgetWithText(OutlinedButton, 'Effacer');

    expect(tester.getSize(searchFinder).height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
    expect(tester.getSize(clearFinder).height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));

    final searchButton = tester.widget<ElevatedButton>(searchFinder);
    final clearButton = tester.widget<OutlinedButton>(clearFinder);

    expect(
      searchButton.style?.tapTargetSize,
      isNot(MaterialTapTargetSize.shrinkWrap),
    );
    expect(
      clearButton.style?.tapTargetSize,
      isNot(MaterialTapTargetSize.shrinkWrap),
    );
  });

  testWidgets(
    'ReRegistrationSearchForm search action keeps minimum 48dp tap target',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          ReRegistrationSearchForm(
            options: const [],
            isLoading: false,
            onSearch: (_) {},
          ),
        ),
      );

      final searchFinder = find.widgetWithText(ElevatedButton, 'Rechercher');
      final searchButton = tester.widget<ElevatedButton>(searchFinder);

      expect(
        tester.getSize(searchFinder).height,
        greaterThanOrEqualTo(AppDimensions.minTouchTarget),
      );
      expect(
        searchButton.style?.tapTargetSize,
        isNot(MaterialTapTargetSize.shrinkWrap),
      );
    },
  );
}
