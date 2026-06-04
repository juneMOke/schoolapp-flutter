import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

void main() {
  group('EnrollmentSearchCommandHandlers', () {
    testWidgets(
      'dispatches a fresh summaries request when status changes without criteria',
      (tester) async {
        final bloc = _MockEnrollmentBloc();
        when(
          () => bloc.stream,
        ).thenAnswer((_) => const Stream<EnrollmentState>.empty());
        when(() => bloc.state).thenReturn(const EnrollmentState.initial());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EnrollmentBloc>.value(
              value: bloc,
              child: Builder(
                builder: (context) {
                  EnrollmentSearchCommandHandlers.dispatchThroughEnrollmentBloc(
                    context,
                    const StandardSearchCommand(status: 'COMPLETED'),
                    const EnrollmentScreenContext(
                      schoolId: 'school-1',
                      academicYearId: 'ay-2025',
                      isLoading: false,
                    ),
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        verify(
          () => bloc.add(
            const EnrollmentSummariesRequested(
              status: 'COMPLETED',
              academicYearId: 'ay-2025',
              page: 0,
            ),
          ),
        ).called(1);
      },
    );
  });
}
