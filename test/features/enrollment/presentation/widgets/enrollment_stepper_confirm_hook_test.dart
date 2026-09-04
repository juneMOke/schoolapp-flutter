import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockOffline
    extends MockBloc<EnrollmentOfflineEvent, EnrollmentOfflineState>
    implements EnrollmentOfflineBloc {}

/// Étape de test dont on pilote le dernier mot.
///
/// [onConfirm] `null` = aucun override : le défaut du contrat doit laisser
/// passer, et c'est justement ce que le premier cas vérifie.
class _FakeHandler extends EnrollmentStepHandler {
  final EnrollmentWizardStep _step;
  final Future<bool> Function()? onConfirm;

  _FakeHandler(this._step, {this.onConfirm});

  @override
  EnrollmentWizardStep get step => _step;

  @override
  int get order => _step.index;

  @override
  String title(AppLocalizations l10n) => 'étape ${_step.index}';

  @override
  String subtitle(AppLocalizations l10n) => '';

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) => 'save';

  @override
  StepValidationResult validate(HandlerValidationContext context) =>
      const StepValidationResult.valid();

  @override
  Future<StepSubmitResult> submit(HandlerSubmitContext context) async =>
      const StepSubmitResult.noop();

  @override
  Future<bool> confirmBeforeContinue(HandlerConfirmContext context) =>
      onConfirm?.call() ?? super.confirmBeforeContinue(context);

  @override
  Widget buildContent(HandlerBuildContext context) =>
      Text('contenu ${_step.index}');
}

void main() {
  late _MockOffline offline;
  late EnrollmentStepperFlowBloc flow;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  setUp(() {
    offline = _MockOffline();
    whenListen(
      offline,
      const Stream<EnrollmentOfflineState>.empty(),
      initialState: const EnrollmentOfflineInitial(),
    );
    flow = EnrollmentStepperFlowBloc(
      totalSteps: EnrollmentWizardStep.values.length,
      // Étape franchissable : valide, propre, pas en cours d'écriture.
      initialStepStates: const {
        0: StepFormState(valid: true, dirty: false, saving: false),
      },
    );
    addTearDown(flow.close);
  });

  Future<void> pumpStepper(
    WidgetTester tester, {
    Future<bool> Function()? onConfirm,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final handlers = <EnrollmentStepHandler>[
      _FakeHandler(EnrollmentWizardStep.personalInfo, onConfirm: onConfirm),
      for (final step in EnrollmentWizardStep.values.skip(1))
        _FakeHandler(step),
    ];

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
            body: EnrollmentStepper(
              enrollmentDetail: EnrollmentDetail.empty(),
              detailIntent: const EnrollmentDetailIntent.newFirstRegistration(),
              detailPolicy: const NewFirstRegistrationDetailPolicy(),
              stepHandlers: handlers,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Barre large : `EteeloButton.primary` porte le libellé ; barre compacte :
  // un bouton-icône dont le libellé n'est que le tooltip. Le test se joue en
  // 1280×900, donc en barre large.
  Finder continueButton() => find.text(l10n.next);

  testWidgets('sans dernier mot, l\'étape se franchit', (tester) async {
    await pumpStepper(tester);

    expect(flow.state.currentStep, 0);
    await tester.tap(continueButton());
    await tester.pumpAndSettle();

    expect(flow.state.currentStep, 1);
  });

  testWidgets('un dernier mot favorable laisse franchir', (tester) async {
    await pumpStepper(tester, onConfirm: () async => true);

    await tester.tap(continueButton());
    await tester.pumpAndSettle();

    expect(flow.state.currentStep, 1);
  });

  testWidgets('un dernier mot défavorable RETIENT sur l\'étape', (
    tester,
  ) async {
    await pumpStepper(tester, onConfirm: () async => false);

    await tester.tap(continueButton());
    await tester.pumpAndSettle();

    expect(flow.state.currentStep, 0);
  });

  testWidgets('deux tapes rapides ne posent la question qu\'une fois', (
    tester,
  ) async {
    // La question est asynchrone : entre la tape et la popin, le bouton reste
    // tapable. Sans verrou, deux tapes lanceraient deux confrontations.
    final gate = Completer<bool>();
    var asked = 0;

    await pumpStepper(
      tester,
      onConfirm: () {
        asked++;
        return gate.future;
      },
    );

    await tester.tap(continueButton());
    await tester.pump();
    await tester.tap(continueButton());
    await tester.pump();

    expect(asked, 1);

    gate.complete(true);
    await tester.pumpAndSettle();
    expect(flow.state.currentStep, 1);
  });
}
