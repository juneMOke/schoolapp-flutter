import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/summary_step_handler.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockDraftBloc extends Mock implements EnrollmentDraftBloc {}

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockFlowBloc extends Mock implements EnrollmentStepperFlowBloc {}

class _MockL10n extends Mock implements AppLocalizations {}

class _FakePolicy extends EnrollmentDetailPolicy {
  const _FakePolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  bool isStepEditable(EnrollmentWizardStep step) => true;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  }) {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(const FinalizeDraftRequested('fallback'));
    registerFallbackValue(const LoadLocalEnrollments());
  });

  late _MockDraftBloc draftBloc;
  late _MockOfflineBloc offlineBloc;

  setUp(() {
    draftBloc = _MockDraftBloc();
    offlineBloc = _MockOfflineBloc();
    when(() => draftBloc.state).thenReturn(const EnrollmentDraftInitial());
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());
    when(
      () => draftBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentDraftState>.empty());
    when(
      () => offlineBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
  });

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<EnrollmentDraftBloc>.value(value: draftBloc),
          BlocProvider<EnrollmentOfflineBloc>.value(value: offlineBloc),
        ],
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  HandlerSubmitContext buildSubmitContext(
    BuildContext context,
    EnrollmentDetailIntent intent,
  ) {
    return HandlerSubmitContext(
      context: context,
      enrollmentBloc: _MockEnrollmentBloc(),
      flowBloc: _MockFlowBloc(),
      enrollmentState: const EnrollmentState.initial(),
      detail: _buildDetail(),
      intent: intent,
      detailPolicy: const _FakePolicy(),
      l10n: _MockL10n(),
    );
  }

  testWidgets('NEW → finalise le brouillon local (pas de confirm offline)', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final handler = SummaryStepHandler();

    final result = await handler.submit(
      buildSubmitContext(
        context,
        const EnrollmentDetailIntent.newFirstRegistration().withEnrollmentId(
          'enr-1',
        ),
      ),
    );

    expect(result.status, StepSubmitStatus.dispatched);
    final captured = verify(() => draftBloc.add(captureAny())).captured;
    expect(captured.single, isA<FinalizeDraftRequested>());
    expect((captured.single as FinalizeDraftRequested).enrollmentId, 'enr-1');
    verifyNever(() => offlineBloc.add(any()));
  });

  testWidgets('RE → confirmation offline inchangée (pas de finalize draft)', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final handler = SummaryStepHandler();

    final result = await handler.submit(
      buildSubmitContext(
        context,
        const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'enr-2',
          studentId: 'stu-2',
        ),
      ),
    );

    expect(result.status, StepSubmitStatus.dispatched);
    final captured = verify(() => offlineBloc.add(captureAny())).captured;
    expect(captured.single, isA<ConfirmLocalEnrollment>());
    verifyNever(() => draftBloc.add(any()));
  });
}

EnrollmentDetail _buildDetail() {
  return EnrollmentDetail(
    studentDetail: const StudentDetail(
      id: 'stu-1',
      firstName: 'John',
      lastName: 'Doe',
      surname: 'Junior',
      dateOfBirth: '2010-01-01',
      gender: Gender.male,
      birthPlace: 'Abidjan',
      nationality: 'ivoirienne',
      city: 'Abidjan',
      district: 'Cocody',
      municipality: 'Riviera',
      neighborhood: 'Riviera 2',
      address: 'lot 10',
      schoolLevel: SchoolLevel(
        id: 'level-1',
        name: '6eme',
        code: '6E',
        displayOrder: 1,
        splitIntoClassrooms: false,
      ),
      schoolLevelGroup: SchoolLevelGroup(
        id: 'group-1',
        name: 'College',
        code: 'COL',
      ),
    ),
    parentDetails: const <ParentSummary>[
      ParentSummary(
        id: 'parent-1',
        firstName: 'Jane',
        lastName: 'Doe',
        identificationNumber: 'ID-1',
        phoneNumber: '+22501020304',
        email: 'jane.doe@example.com',
        relationshipType: RelationshipType.mother,
      ),
    ],
    enrollmentDetail: const EnrollmentSchoolDetail(
      id: 'enr-1',
      status: EnrollmentStatus.inProgress,
      academicYearId: 'ay-1',
      enrollmentCode: 'ENR-1',
      previousSchoolName: 'School',
      previousAcademicYear: '2024-2025',
      previousSchoolLevelGroup: 'College',
      previousSchoolLevel: '5eme',
      previousRate: 12.0,
      previousRank: 5,
      validatedPreviousYear: true,
      schoolLevelGroupId: 'group-1',
      schoolLevelId: 'level-1',
    ),
  );
}
