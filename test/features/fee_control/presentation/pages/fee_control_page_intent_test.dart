import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_dashboard_contracts.dart';
import 'package:school_app_flutter/features/fee_control/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFeeControlBloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const tIntent = FeeControlIntent(
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'lvl-1',
  classroomId: 'c-a',
  feeCode: 'TUITION',
);

const tTariff = LocalFeeTariff(
  id: 't1',
  academicYearId: 'ay-1',
  schoolLevelId: 'lvl-1',
  feeCode: 'TUITION',
  label: 'Minerval annuel',
  code: 'T1',
  amountInCents: 100000,
  currency: 'USD',
);

/// L'écran nominatif ouvert **depuis le tableau de bord** : il doit repartir du
/// périmètre exact que la synthèse affichait, sans que l'opérateur resaisisse
/// quoi que ce soit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockFeeControlBloc bloc;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AcademicYearContextRequested());
    registerFallbackValue(const FeeControlResetRequested());
  });

  setUp(() {
    bloc = _MockFeeControlBloc();
    academicYearBloc = _MockAcademicYearBloc();
    authBloc = _MockAuthBloc();

    whenListen(
      academicYearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'ay-1',
            name: '2026-2027',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2027, 7, 1),
            current: true,
          ),
          schoolLevelGroups: const [
            SchoolLevelGroupBundle(
              group: SchoolLevelGroup(
                id: 'g1',
                name: 'Primaire',
                code: 'PRIM',
                displayOrder: 1,
              ),
              levels: [
                SchoolLevel(
                  id: 'lvl-1',
                  name: '1ère année',
                  code: 'P1',
                  displayOrder: 1,
                  splitIntoClassrooms: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.authenticated),
    );

    GetIt.instance.registerFactory<FeeControlBloc>(() => bloc);
  });

  tearDown(() async => GetIt.instance.reset());

  Future<void> pump(
    WidgetTester tester, {
    required List<FeeControlState> states,
    FeeControlIntent? intent = tIntent,
  }) async {
    whenListen(
      bloc,
      Stream<FeeControlState>.fromIterable(states),
      initialState: const FeeControlState.initial(),
    );

    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AcademicYearContextBloc>.value(
              value: academicYearBloc,
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: FeeControlPage(intent: intent),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('l\'intention charge la grille ET les classes de son niveau', (
    tester,
  ) async {
    await pump(tester, states: const <FeeControlState>[]);

    verify(
      () => bloc.add(
        const FeeControlTariffsRequested(
          academicYearId: 'ay-1',
          schoolLevelGroupId: 'g1',
          schoolLevelId: 'lvl-1',
        ),
      ),
    ).called(1);
    verify(
      () => bloc.add(
        const FeeControlClassroomsRequested(
          academicYearId: 'ay-1',
          schoolLevelId: 'lvl-1',
        ),
      ),
    ).called(1);
  });

  testWidgets('la recherche part quand la GRILLE arrive, et porte la '
      'désignation de la ligne tarifaire', (tester) async {
    await pump(
      tester,
      states: [
        const FeeControlState(
          tariffsStatus: EnrollmentLoadStatus.success,
          tariffs: [tTariff],
        ),
      ],
    );

    final captured = verify(
      () => bloc.add(captureAny(that: isA<FeeControlSearchRequested>())),
    ).captured.cast<FeeControlSearchRequested>();

    expect(captured, hasLength(1));
    final request = captured.single.request;
    expect(request.schoolLevelGroupId, 'g1');
    expect(request.schoolLevelId, 'lvl-1');
    expect(request.classroomId, 'c-a');
    expect(request.feeCode, 'TUITION');
    // La désignation vient de la grille : lancée plus tôt, la requête aurait
    // porté un libellé vide et la puce de critère aurait menti.
    expect(request.feeLabel, 'Minerval annuel');
    expect(request.feeTariffCode, 'T1');
  });

  testWidgets('la recherche ne part QU\'UNE fois, même si la grille est '
      'rechargée', (tester) async {
    await pump(
      tester,
      states: [
        const FeeControlState(tariffsStatus: EnrollmentLoadStatus.loading),
        const FeeControlState(
          tariffsStatus: EnrollmentLoadStatus.success,
          tariffs: [tTariff],
        ),
        const FeeControlState(tariffsStatus: EnrollmentLoadStatus.loading),
        const FeeControlState(
          tariffsStatus: EnrollmentLoadStatus.success,
          tariffs: [tTariff],
        ),
      ],
    );

    verify(
      () => bloc.add(any(that: isA<FeeControlSearchRequested>())),
    ).called(1);
  });

  testWidgets('la nature absente de la grille : rien n\'est cherché, plutôt '
      'qu\'un vide inexplicable', (tester) async {
    await pump(
      tester,
      states: const [
        FeeControlState(
          tariffsStatus: EnrollmentLoadStatus.success,
          tariffs: <LocalFeeTariff>[],
        ),
      ],
    );

    verifyNever(() => bloc.add(any(that: isA<FeeControlSearchRequested>())));
  });

  testWidgets(
    'sans intention — ouverture par le menu — l\'écran reste vierge',
    (tester) async {
      await pump(
        tester,
        intent: null,
        states: const [
          FeeControlState(
            tariffsStatus: EnrollmentLoadStatus.success,
            tariffs: [tTariff],
          ),
        ],
      );

      verifyNever(() => bloc.add(any(that: isA<FeeControlTariffsRequested>())));
      verifyNever(() => bloc.add(any(that: isA<FeeControlSearchRequested>())));
    },
  );

  testWidgets('le formulaire GARDE le frais pré-rempli pendant que la grille '
      'charge — sinon la liste s\'affiche sans montrer sur quoi elle porte', (
    tester,
  ) async {
    // ⚠️ Les états sont émis UN PAR UN, avec un `pump` entre chacun. Un
    // `Stream.fromIterable` est drainé avant le premier frame : le formulaire
    // ne verrait alors que l'état final, et ne traverserait jamais le
    // chargement — l'instant précis que cette garde protège.
    final controller = StreamController<FeeControlState>();
    addTearDown(controller.close);
    whenListen(
      bloc,
      controller.stream,
      initialState: const FeeControlState.initial(),
    );

    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AcademicYearContextBloc>.value(
              value: academicYearBloc,
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const FeeControlPage(intent: tIntent),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La grille est demandée, donc encore vide. Sans garde, `didUpdateWidget`
    // y voit un frais « disparu » et l'efface — alors qu'il n'est que pas
    // encore arrivé.
    controller.add(
      const FeeControlState(
        tariffsStatus: EnrollmentLoadStatus.loading,
        tariffs: <LocalFeeTariff>[],
      ),
    );
    await tester.pumpAndSettle();

    controller.add(
      const FeeControlState(
        tariffsStatus: EnrollmentLoadStatus.success,
        tariffs: [tTariff],
      ),
    );
    await tester.pumpAndSettle();

    // La VALEUR du champ, pas un texte présent ailleurs à l'écran : le libellé
    // du tarif apparaît aussi dans la liste déroulante, et le chercher là
    // rendrait le test vert quoi qu'il arrive à la sélection.
    final fee = tester
        .widgetList<EteeloSelectInput<String>>(
          find.byType(EteeloSelectInput<String>),
        )
        .firstWhere((field) => field.label == 'Frais');
    expect(fee.value, 'TUITION');
  });
}
