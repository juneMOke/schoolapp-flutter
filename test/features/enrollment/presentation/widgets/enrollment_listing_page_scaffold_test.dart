import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_scaffold.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Régression du bug de corruption : un brouillon RE_ENROLLMENT repris depuis
/// le listing doit porter son vrai `enrollmentType` dans l'intent de
/// navigation (sinon écrasé en NEW_ENROLLMENT à la sauvegarde suivante). Ce
/// test pompe le vrai point d'écriture (`onViewRequested` du scaffold) via un
/// tap réel sur la ligne, avec un vrai `GoRouter`.
class _MockEnrollmentLocalListBloc extends Mock
    implements EnrollmentLocalListBloc {}

void main() {
  late _MockEnrollmentLocalListBloc bloc;

  const draftSummary = EnrollmentSummary(
    enrollmentId: 'draft-1',
    enrollmentCode: 'ENR-DRAFT',
    status: 'DRAFT',
    student: StudentSummary(
      id: 'stu-1',
      firstName: 'Jean',
      lastName: 'Kanku',
      surname: 'Mbuyi',
      dateOfBirth: '2012-05-20',
      gender: Gender.male,
    ),
    enrollmentType: 'RE_ENROLLMENT',
    syncState: SyncState.draft,
  );

  const nonDraftSummary = EnrollmentSummary(
    enrollmentId: 'enr-2',
    enrollmentCode: 'ENR-002',
    status: 'VALIDATED',
    student: StudentSummary(
      id: 'stu-2',
      firstName: 'Alice',
      lastName: 'Tshimanga',
      surname: 'Nzuzi',
      dateOfBirth: '2011-03-14',
      gender: Gender.female,
    ),
    enrollmentType: 'RE_ENROLLMENT',
  );

  EnrollmentLocalListState successState(EnrollmentSummary summary) {
    return const EnrollmentLocalListState.initial().copyWith(
      summariesStatus: EnrollmentLoadStatus.success,
      summaries: [summary],
      summariesTotalElements: 1,
      summariesTotalPages: 1,
    );
  }

  void stubBloc(EnrollmentLocalListState state) {
    bloc = _MockEnrollmentLocalListBloc();
    when(() => bloc.state).thenReturn(state);
    when(
      () => bloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentLocalListState>.empty());
  }

  late Map<String, String> pushedQueryParameters;
  late Object? pushedExtra;

  Future<void> pumpScaffold(
    WidgetTester tester, {
    required EnrollmentDetailIntentFactory detailIntentFactory,
  }) async {
    pushedQueryParameters = const <String, String>{};
    pushedExtra = null;

    final router = GoRouter(
      initialLocation: '/list',
      routes: [
        GoRoute(
          path: '/list',
          builder: (context, state) =>
              BlocProvider<EnrollmentLocalListBloc>.value(
                value: bloc,
                child: EnrollmentListingPageScaffold(
                  bootstrapBuilder: (context, onReady) => onReady(
                    context,
                    const EnrollmentScreenContext(
                      schoolId: 'school-1',
                      academicYearId: 'ay-2025',
                      isLoading: false,
                    ),
                  ),
                  searchSectionBuilder: (context, ctx, dispatch) =>
                      const SizedBox.shrink(),
                  onSearchCommand: (context, command, screenCtx) {},
                  detailIntentFactory: detailIntentFactory,
                ),
              ),
        ),
        GoRoute(
          path: '${EnrollmentConstants.enrollmentDetailRoute}/:enrollmentId',
          builder: (context, state) {
            pushedQueryParameters = state.uri.queryParameters;
            pushedExtra = state.extra;
            return const Scaffold(body: Text('DETAIL'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'brouillon local RE_ENROLLMENT repris depuis le listing → intent porte '
    'enrollmentType=RE_ENROLLMENT (pas NEW_ENROLLMENT, pas absent)',
    (tester) async {
      stubBloc(successState(draftSummary));

      await pumpScaffold(
        tester,
        detailIntentFactory: (_) => fail(
          'detailIntentFactory ne doit pas être appelé pour un brouillon local',
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL'), findsOneWidget);
      expect(
        pushedQueryParameters[EnrollmentDetailIntent
            .enrollmentTypeQueryParameter],
        'RE_ENROLLMENT',
      );
      expect(
        pushedQueryParameters[EnrollmentDetailIntent
            .enrollmentTypeQueryParameter],
        isNot('NEW_ENROLLMENT'),
      );
      expect(
        pushedQueryParameters[EnrollmentDetailIntent.originQueryParameter],
        EnrollmentDetailOrigin.localDraftResume.name,
      );
      final extra = pushedExtra as EnrollmentDetailIntent;
      expect(extra.enrollmentType, 'RE_ENROLLMENT');
    },
  );

  testWidgets('dossier NON-brouillon → passe par detailIntentFactory, pas par '
      'localDraftResume', (tester) async {
    stubBloc(successState(nonDraftSummary));

    const controlOrigin = EnrollmentDetailOrigin.preRegistration;
    await pumpScaffold(
      tester,
      detailIntentFactory: (summary) => EnrollmentDetailIntent(
        origin: controlOrigin,
        enrollmentId: summary.enrollmentId,
        status: 'FROM_CONTROL_FACTORY',
      ),
    );

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(find.text('DETAIL'), findsOneWidget);
    expect(
      pushedQueryParameters[EnrollmentDetailIntent.originQueryParameter],
      controlOrigin.name,
    );
    expect(
      pushedQueryParameters[EnrollmentDetailIntent.originQueryParameter],
      isNot(EnrollmentDetailOrigin.localDraftResume.name),
    );
    expect(
      pushedQueryParameters[EnrollmentDetailIntent.statusQueryParameter],
      'FROM_CONTROL_FACTORY',
    );
  });
}
