import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/address_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/address_geo_catalog.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockOffline
    extends MockBloc<EnrollmentOfflineEvent, EnrollmentOfflineState>
    implements EnrollmentOfflineBloc {}

/// La porte de l'étape Adresse, de bout en bout : catalogue → enregistrement →
/// rechargement du dossier. C'est le trajet où « Continuer » restait gris.
///
/// ⚠️ Le catalogue géographique est une **I/O réelle** : sous `pump()`, dans la
/// zone FakeAsync, son `Future` ne se dénoue jamais — l'étape reste alors sur
/// quatre sélecteurs vides et le test prouverait le contraire de ce qu'il
/// croit prouver. D'où le pré-chauffage du cache statique via `runAsync`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  StudentDetail student({
    String city = '',
    String district = '',
    String municipality = '',
    String neighborhood = '',
    String address = '',
  }) => StudentDetail(
    id: 'stu-1',
    firstName: 'Daniel',
    lastName: 'Kabongo',
    surname: 'Mwamba',
    dateOfBirth: '2012-05-04',
    gender: Gender.male,
    birthPlace: 'Kinshasa',
    nationality: 'Congolaise',
    city: city,
    district: district,
    municipality: municipality,
    neighborhood: neighborhood,
    address: address,
    schoolLevel: const SchoolLevel(
      id: 'lvl-1',
      name: '6e',
      code: 'L6',
      displayOrder: 1,
      splitIntoClassrooms: false,
    ),
    schoolLevelGroup: const SchoolLevelGroup(
      id: 'grp-1',
      name: 'Secondaire',
      code: 'SEC',
    ),
  );

  testWidgets('dossier neuf : le catalogue rend l\'étape enregistrable, '
      'et l\'enregistrement la rend franchissable', (tester) async {
    final offlineStates = StreamController<EnrollmentOfflineState>.broadcast();
    addTearDown(offlineStates.close);
    final offline = _MockOffline();
    whenListen(
      offline,
      offlineStates.stream,
      initialState: const EnrollmentOfflineInitial(),
    );

    final flow = EnrollmentStepperFlowBloc(
      totalSteps: 7,
      initialStepStates: const {1: StepFormState()},
    );
    addTearDown(flow.close);
    final stepController = EnrollmentStepSubmitController();

    await tester.runAsync(() => AddressGeoCatalog.load());

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<EnrollmentOfflineBloc>.value(value: offline),
            BlocProvider<EnrollmentStepperFlowBloc>.value(value: flow),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: AddressStep(
                studentDetail: student(),
                enrollmentId: 'enr-1',
                showInlineSaveButton: false,
                flowStepIndex: 1,
                stepController: stepController,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Le catalogue a bien renseigné les quatre sélecteurs — sans quoi tout ce
    // qui suit ne prouverait rien.
    expect(find.text('Kinshasa'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Rien n'a été saisi, mais le catalogue a proposé : l'étape est modifiée
    // et valide, donc enregistrable — et pas encore franchissable, ce qui est
    // la règle du wizard (on enregistre avant de continuer).
    var reported = flow.state.stateOf(1);
    expect(reported.valid, isTrue);
    expect(reported.dirty, isTrue);

    stepController.submitForm();
    await tester.pump();
    offlineStates.add(const EnrollmentDraftStepSaved());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Enregistré, complément resté vide : la porte s'ouvre.
    reported = flow.state.stateOf(1);
    expect(reported.dirty, isFalse);
    expect(reported.valid, isTrue);
    expect(
      flow.state.copyWith(currentStep: 1).canContinue,
      isTrue,
      reason: 'un complément vide ne doit rien refermer',
    );

    // Dernier maillon, et le vrai « tout est gris » : la page hôte recharge le
    // dossier après l'enregistrement, et `EnrollmentStepperScope` re-sème
    // l'état de toutes les étapes. Le dossier revient avec les quatre champs
    // géographiques renseignés et le complément vide — le cas de l'usager.
    final dossierRecharge = EnrollmentDetail(
      studentDetail: student(
        city: 'Kinshasa',
        district: 'Lukunga',
        municipality: 'Barumbu',
        neighborhood: 'Bitshaku-Tshaku',
        address: '',
      ),
      parentDetails: const [],
      enrollmentDetail: const EnrollmentSchoolDetail(
        id: 'enr-1',
        status: EnrollmentStatus.inProgress,
        academicYearId: 'ay-2026',
        enrollmentCode: '',
        previousSchoolName: '',
        previousAcademicYear: '',
        previousSchoolLevelGroup: '',
        previousSchoolLevel: '',
        previousRate: null,
        previousRank: null,
        validatedPreviousYear: null,
        schoolLevelGroupId: 'grp-1',
        schoolLevelId: 'lvl-1',
      ),
    );
    flow.add(const EnrollmentStepperCurrentStepChanged(1));
    flow.add(
      EnrollmentStepperStatesSynced(<int, StepFormState>{
        1: AddressStepHandler(
          controller: EnrollmentStepSubmitController(),
        ).initialState(HandlerInitialStateContext(detail: dossierRecharge)),
      }),
    );
    // Sans laisser tourner la boucle d'événements, l'assertion lirait l'état
    // d'AVANT le semis et passerait sans rien prouver.
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      flow.state.stateOf(1).valid,
      isTrue,
      reason: 'tout gris = étape invalide, ce que le semis imposait',
    );
    expect(flow.state.canContinue, isTrue);
    expect(
      flow.state.canSave,
      isFalse,
      reason:
          'rien à enregistrer : c\'est le bouton qui s\'éteint, pas la porte',
    );
  });
}
