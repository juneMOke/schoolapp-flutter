import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_search_command_handlers.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class _MockEnrollmentLocalListBloc extends Mock
    implements EnrollmentLocalListBloc {}

void main() {
  group('EnrollmentSearchCommandHandlers.dispatchThroughLocalListBloc', () {
    late _MockEnrollmentLocalListBloc bloc;

    setUp(() {
      bloc = _MockEnrollmentLocalListBloc();
      when(
        () => bloc.stream,
      ).thenAnswer((_) => const Stream<EnrollmentLocalListState>.empty());
      when(
        () => bloc.state,
      ).thenReturn(const EnrollmentLocalListState.initial());
    });

    Future<void> dispatch(
      WidgetTester tester,
      EnrollmentSearchCommand command, {
      String? enrollmentType,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<EnrollmentLocalListBloc>.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                EnrollmentSearchCommandHandlers.dispatchThroughLocalListBloc(
                  context,
                  command,
                  EnrollmentScreenContext(
                    schoolId: 'school-1',
                    academicYearId: 'ay-2025',
                    isLoading: false,
                    enrollmentType: enrollmentType,
                  ),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    }

    testWidgets('status sans critère → liste locale par statut', (
      tester,
    ) async {
      await dispatch(tester, const StandardSearchCommand(status: 'COMPLETED'));

      verify(
        () => bloc.add(
          const LocalListByStatusRequested(
            status: 'COMPLETED',
            academicYearId: 'ay-2025',
            page: 0,
          ),
        ),
      ).called(1);
    });

    testWidgets('noms complets → recherche locale par nom', (tester) async {
      await dispatch(
        tester,
        const StandardSearchCommand(
          status: 'IN_PROGRESS',
          firstName: 'Awa',
          lastName: 'Ndiaye',
          surname: 'Fatou',
        ),
      );

      verify(
        () => bloc.add(
          const LocalListByStudentNameRequested(
            status: 'IN_PROGRESS',
            academicYearId: 'ay-2025',
            firstName: 'Awa',
            lastName: 'Ndiaye',
            surname: 'Fatou',
            page: 0,
          ),
        ),
      ).called(1);
    });

    testWidgets('date de naissance seule → recherche locale par DOB', (
      tester,
    ) async {
      await dispatch(
        tester,
        const StandardSearchCommand(
          status: 'IN_PROGRESS',
          dateOfBirth: '2012-05-01',
        ),
      );

      verify(
        () => bloc.add(
          const LocalListByDateOfBirthRequested(
            status: 'IN_PROGRESS',
            academicYearId: 'ay-2025',
            dateOfBirth: '2012-05-01',
            page: 0,
          ),
        ),
      ).called(1);
    });

    testWidgets('noms + date de naissance → recherche locale combinée', (
      tester,
    ) async {
      await dispatch(
        tester,
        const StandardSearchCommand(
          status: 'IN_PROGRESS',
          firstName: 'Awa',
          lastName: 'Ndiaye',
          surname: 'Fatou',
          dateOfBirth: '2012-05-01',
        ),
      );

      verify(
        () => bloc.add(
          const LocalListByStudentNamesAndDateOfBirthRequested(
            status: 'IN_PROGRESS',
            academicYearId: 'ay-2025',
            firstName: 'Awa',
            lastName: 'Ndiaye',
            surname: 'Fatou',
            dateOfBirth: '2012-05-01',
            page: 0,
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'page Pré-inscriptions : le type PRE_ENROLLMENT du screenCtx est porté '
      'sur la recherche par nom (borne le scope, exclut les réinscriptions)',
      (tester) async {
        await dispatch(
          tester,
          const StandardSearchCommand(
            status: 'PRE_REGISTERED',
            firstName: 'Awa',
            lastName: 'Ndiaye',
            surname: 'Fatou',
          ),
          enrollmentType: 'PRE_ENROLLMENT',
        );

        verify(
          () => bloc.add(
            const LocalListByStudentNameRequested(
              status: 'PRE_REGISTERED',
              academicYearId: 'ay-2025',
              enrollmentType: 'PRE_ENROLLMENT',
              firstName: 'Awa',
              lastName: 'Ndiaye',
              surname: 'Fatou',
              page: 0,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('info académique → recherche locale par niveaux', (
      tester,
    ) async {
      await dispatch(
        tester,
        const AcademicInfoSearchCommand(
          firstName: '',
          lastName: '',
          surname: '',
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-2',
        ),
      );

      verify(
        () => bloc.add(
          const LocalListByAcademicInfoRequested(
            firstName: '',
            lastName: '',
            surname: '',
            schoolLevelGroupId: 'grp-1',
            schoolLevelId: 'lvl-2',
            page: 0,
          ),
        ),
      ).called(1);
    });

    /// La discrimination Première inscription / Réinscription se joue sur
    /// `status != null`, pas sur `status.isNotEmpty` : « Tous les statuts »
    /// (chaîne vide) doit rester sur le vivier de la Première inscription, et
    /// surtout pas basculer sur la cohorte N-1 de la Réinscription.
    testWidgets(
      'info académique + statut VIDE (« Tous ») reste sur la Première '
      'inscription',
      (tester) async {
        await dispatch(
          tester,
          const AcademicInfoSearchCommand(
            firstName: '',
            lastName: '',
            surname: '',
            schoolLevelGroupId: 'grp-1',
            schoolLevelId: 'lvl-2',
            status: '',
          ),
        );

        verify(
          () => bloc.add(
            const LocalListByAcademicInfoAndStatusRequested(
              status: '',
              academicYearId: 'ay-2025',
              firstName: '',
              lastName: '',
              surname: '',
              schoolLevelGroupId: 'grp-1',
              schoolLevelId: 'lvl-2',
              page: 0,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'info académique + statut (Première inscription) → recherche locale par '
      'niveau, bornée statut/type',
      (tester) async {
        await dispatch(
          tester,
          const AcademicInfoSearchCommand(
            firstName: '',
            lastName: '',
            surname: '',
            schoolLevelGroupId: 'grp-1',
            schoolLevelId: 'lvl-2',
            status: 'IN_PROGRESS',
          ),
        );

        verify(
          () => bloc.add(
            const LocalListByAcademicInfoAndStatusRequested(
              status: 'IN_PROGRESS',
              academicYearId: 'ay-2025',
              firstName: '',
              lastName: '',
              surname: '',
              schoolLevelGroupId: 'grp-1',
              schoolLevelId: 'lvl-2',
              page: 0,
            ),
          ),
        ).called(1);
      },
    );
  });

  group(
    'EnrollmentSearchCommandHandlers.dispatchPreEnrollmentThroughLocalListBloc',
    () {
      late _MockEnrollmentLocalListBloc bloc;

      setUp(() {
        bloc = _MockEnrollmentLocalListBloc();
        when(
          () => bloc.stream,
        ).thenAnswer((_) => const Stream<EnrollmentLocalListState>.empty());
        when(
          () => bloc.state,
        ).thenReturn(const EnrollmentLocalListState.initial());
      });

      Future<void> dispatch(
        WidgetTester tester,
        EnrollmentSearchCommand command,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<EnrollmentLocalListBloc>.value(
              value: bloc,
              child: Builder(
                builder: (context) {
                  EnrollmentSearchCommandHandlers.dispatchPreEnrollmentThroughLocalListBloc(
                    context,
                    command,
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
      }

      testWidgets(
        'info académique (bi-mode, sans status) → vivier PRE, PAS le vivier '
        'RE (contrairement à dispatchThroughLocalListBloc)',
        (tester) async {
          await dispatch(
            tester,
            const AcademicInfoSearchCommand(
              firstName: 'Awa',
              lastName: 'Ndiaye',
              surname: '',
              schoolLevelGroupId: 'grp-1',
              schoolLevelId: 'lvl-2',
            ),
          );

          verify(
            () => bloc.add(
              const LocalListByPreEnrollmentAcademicInfoRequested(
                firstName: 'Awa',
                lastName: 'Ndiaye',
                surname: '',
                schoolLevelGroupId: 'grp-1',
                schoolLevelId: 'lvl-2',
                page: 0,
              ),
            ),
          ).called(1);
        },
      );
    },
  );
}
