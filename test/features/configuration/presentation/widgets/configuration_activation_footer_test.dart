import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_activation_footer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

const _identity = SchoolIdentity(
  id: 'school-1',
  name: 'Complexe scolaire Kimbondo',
  country: 'RDC',
  city: 'Kinshasa',
  district: 'Mont-Amba',
  municipality: 'Lemba',
  address: '12 avenue de la Paix',
  phone: '+243810000000',
  email: 'direction@kimbondo.cd',
);

final _draft = ProvisioningRequest(
  academicYear: AcademicYearInput(
    name: '2026-2027',
    startDate: DateTime.utc(2026, 9, 1),
    endDate: DateTime.utc(2027, 6, 30),
  ),
  cycles: const [
    CycleInput(
      catalogCode: 'PRIM',
      levels: [LevelInput(catalogCode: 'P1', classrooms: 2)],
    ),
  ],
  fees: [
    FeeInput(
      feeCode: 'TUITION',
      label: 'Minerval',
      amountInCents: 5000000,
      currency: 'CDF',
      dueAt: DateTime.utc(2027, 6, 30, 23, 59, 59),
      appliesTo: const FeeScopeInput.allOpenedLevels(),
    ),
  ],
);

const _plan = ProvisioningPlan(
  dryRun: true,
  academicYearId: null,
  academicYearName: '2026-2027',
  counts: ProvisioningCounts(
    cycles: 1,
    levels: 1,
    classrooms: 2,
    courses: 12,
    fees: 1,
  ),
  cycles: [],
  fees: [],
  warnings: [],
);

void main() {
  late ConfigurationBloc bloc;
  late SchoolIdentityFormCubit cubit;

  setUp(() {
    bloc = ConfigurationBloc(
      repository: _MockRepository(),
      draftRepository: _MockDraftRepository(),
      simulationDebounce: Duration.zero,
    );
    cubit = SchoolIdentityFormCubit(repository: _MockRepository());
    cubit.emit(
      const SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: _identity,
        saved: _identity,
      ),
    );
  });

  tearDown(() async {
    await bloc.close();
    await cubit.close();
  });

  /// L'état où les quatre contrôles passent : identité complète, année datée,
  /// classes au plan, au moins un frais.
  void seed({
    ConfigurationStatus status = ConfigurationStatus.ready,
    bool isActivating = false,
    Failure? failure,
  }) {
    bloc.emit(
      ConfigurationState(
        status: status,
        step: ConfigurationStep.activation,
        maxStep: 4,
        draft: _draft,
        plan: _plan,
        isActivating: isActivating,
        failure: failure,
      ),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<ConfigurationBloc>.value(value: bloc),
              BlocProvider<SchoolIdentityFormCubit>.value(value: cubit),
            ],
            child: const ConfigurationActivationFooter(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  VoidCallback? activateAction(WidgetTester tester) {
    return tester
        .widget<FilledButton>(
          find.ancestor(
            of: find.textContaining('Activ'),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed;
  }

  testWidgets('les quatre contrôles au vert ouvrent l\'activation', (
    tester,
  ) async {
    seed();
    await pump(tester);

    expect(activateAction(tester), isNotNull);
  });

  testWidgets('un échec ferme le geste, comme il ferme les autres barres', (
    tester,
  ) async {
    // Sans cette garde, l'écran affichait le bloc d'erreur ET un bouton
    // « Activer l'école » encore vivant. Or l'écriture n'est PAS idempotente :
    // sur un sort inconnu, elle a pu aboutir côté serveur. La reprise passe par
    // le bloc d'erreur, jamais par un second clic ici.
    seed(
      status: ConfigurationStatus.failure,
      failure: const UncertainOutcomeFailure(),
    );
    await pump(tester);

    expect(activateAction(tester), isNull);
  });

  testWidgets('le chargement ferme le geste', (tester) async {
    seed(status: ConfigurationStatus.loading);
    await pump(tester);

    expect(activateAction(tester), isNull);
  });

  testWidgets('pendant l\'activation, le geste est fermé et se nomme', (
    tester,
  ) async {
    seed(isActivating: true);
    await pump(tester);

    expect(find.text('Activation…'), findsOneWidget);
    expect(activateAction(tester), isNull);
  });

  testWidgets('une identité incomplète ferme le geste', (tester) async {
    // Le PUT de l'étape 1 exige les huit champs : activer sans eux ferait
    // rendre 400 au bout du parcours le plus long de l'application.
    cubit.emit(
      const SchoolIdentityFormState(
        status: SchoolIdentityFormStatus.ready,
        identity: SchoolIdentity(
          id: 'school-1',
          name: 'Complexe scolaire Kimbondo',
          country: 'RDC',
          city: 'Kinshasa',
          district: 'Mont-Amba',
          municipality: '',
          address: '12 avenue de la Paix',
          phone: '+243810000000',
          email: 'direction@kimbondo.cd',
        ),
      ),
    );
    seed();
    await pump(tester);

    expect(activateAction(tester), isNull);
  });
}
