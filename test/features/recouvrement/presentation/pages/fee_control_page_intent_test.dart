import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_question.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFeeControlBloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// L'école a titré sa section : la pastille du frais porte ce titre.
class _StubFeeSectionTitlesCubit extends Cubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {
  _StubFeeSectionTitlesCubit()
    : super(
        const FeeSectionTitlesState(titles: {'TUITION': 'Minerval annuel'}),
      );

  @override
  Future<void> load() async {}
}

const tIntent = FeeControlIntent(classroomId: 'c-a', feeCodes: ['TUITION']);

const tClassroom = OfflineClassroom(
  id: 'c-a',
  academicYearId: 'ay-1',
  schoolLevelGroupId: 'g1',
  schoolLevelId: 'lvl-1',
  name: '1ère A',
);

/// Le catalogue de l'année tel que le bloc le sert : la nature et la classe
/// de l'intention existent.
const tCatalog = FeeControlState(
  catalogStatus: EnrollmentLoadStatus.success,
  natures: [
    FeeNature(feeCode: 'TUITION', currencies: ['USD']),
    FeeNature(feeCode: 'TRANSPORT', currencies: ['USD']),
  ],
  classrooms: [tClassroom],
);

/// L'écran nominatif ouvert **depuis le tableau de bord** (ou par un lien) :
/// il doit repartir de la question exacte — frais, classe, situation — sans
/// que l'opérateur resaisisse quoi que ce soit.
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
    // La dernière visite est une mémoire de séance, statique : sans remise à
    // zéro, un test hériterait de la question du précédent.
    FeeControlQuestion.lastVisit = null;
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
    GetIt.instance.registerFactory<FeeSectionTitlesCubit>(
      () => _StubFeeSectionTitlesCubit(),
    );
  });

  tearDown(() async {
    FeeControlQuestion.lastVisit = null;
    await GetIt.instance.reset();
  });

  Widget providers(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
      BlocProvider<AuthBloc>.value(value: authBloc),
    ],
    child: child,
  );

  void listen(List<FeeControlState> states) => whenListen(
    bloc,
    Stream<FeeControlState>.fromIterable(states),
    initialState: const FeeControlState.initial(),
  );

  void wideView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pump(
    WidgetTester tester, {
    required List<FeeControlState> states,
    FeeControlIntent? intent = tIntent,
  }) async {
    listen(states);
    wideView(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: providers(FeeControlPage(intent: intent)),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<FeeControlSearchRequested> searches() => verify(
    () => bloc.add(captureAny(that: isA<FeeControlSearchRequested>())),
  ).captured.cast<FeeControlSearchRequested>();

  testWidgets('l\'arrivée charge le catalogue de l\'année, une seule fois', (
    tester,
  ) async {
    await pump(tester, states: const <FeeControlState>[]);

    verify(
      () => bloc.add(const FeeControlCatalogRequested(academicYearId: 'ay-1')),
    ).called(1);
    // Sans catalogue, la question ne peut pas encore être vérifiée : rien ne
    // part.
    verifyNever(() => bloc.add(any(that: isA<FeeControlSearchRequested>())));
  });

  testWidgets('la recherche part quand le CATALOGUE arrive, sur la classe et '
      'les frais de l\'intention', (tester) async {
    await pump(tester, states: const [tCatalog]);

    final captured = searches();
    expect(captured, hasLength(1));
    expect(captured.single.academicYearId, 'ay-1');
    final request = captured.single.request;
    expect(request.classroomId, 'c-a');
    expect(request.feeCodes, ['TUITION']);
    expect(request.statusFilter, FeeControlPaymentFilter.all);
    expect(request.threshold, isNull);
  });

  testWidgets('la pastille du frais repris est affichée — la liste montre '
      'sur quoi elle porte', (tester) async {
    await pump(tester, states: const [tCatalog]);

    expect(find.text('Minerval annuel'), findsOneWidget);
  });

  testWidgets('une nature absente du catalogue est écartée : la question '
      'retombe sur la première nature de l\'année', (tester) async {
    await pump(
      tester,
      intent: const FeeControlIntent(classroomId: 'c-a', feeCodes: ['UNKNOWN']),
      states: const [tCatalog],
    );

    expect(searches().single.request.feeCodes, ['TUITION']);
  });

  testWidgets('une classe disparue de l\'année est oubliée : rien n\'est '
      'cherché, plutôt qu\'un vide inexplicable', (tester) async {
    await pump(
      tester,
      intent: const FeeControlIntent(
        classroomId: 'c-gone',
        feeCodes: ['TUITION'],
      ),
      states: const [tCatalog],
    );

    verifyNever(() => bloc.add(any(that: isA<FeeControlSearchRequested>())));
  });

  testWidgets('« Non affectés » n\'est pas une classe du catalogue, mais une '
      'rubrique : elle est cherchée telle quelle', (tester) async {
    await pump(
      tester,
      intent: const FeeControlIntent(
        classroomId: feeControlUnassigned,
        feeCodes: ['TUITION'],
      ),
      states: const [tCatalog],
    );

    final request = searches().single.request;
    expect(request.classroomId, feeControlUnassigned);
    expect(request.isUnassigned, isTrue);
  });

  testWidgets('sans intention ni dernière visite — ouverture par le menu — '
      'aucune classe n\'est choisie, rien n\'est cherché', (tester) async {
    await pump(tester, intent: null, states: const [tCatalog]);

    verify(
      () => bloc.add(const FeeControlCatalogRequested(academicYearId: 'ay-1')),
    ).called(1);
    verifyNever(() => bloc.add(any(that: isA<FeeControlSearchRequested>())));
  });

  testWidgets('sans intention, la dernière visite de la séance est reprise', (
    tester,
  ) async {
    FeeControlQuestion.lastVisit = const FeeControlQuestion(
      feeCodes: ['TRANSPORT'],
      classroomId: 'c-a',
    );

    await pump(tester, intent: null, states: const [tCatalog]);

    final request = searches().single.request;
    expect(request.classroomId, 'c-a');
    expect(request.feeCodes, ['TRANSPORT']);
  });

  testWidgets('l\'adresse porte la question : un onglet rechargé rouvre la '
      'même liste', (tester) async {
    listen(const [tCatalog]);
    wideView(tester);
    final router = GoRouter(
      initialLocation: '/controle?frais=TRANSPORT&classe=c-a&situation=rien',
      routes: [
        GoRoute(
          path: '/controle',
          builder: (_, _) => providers(const FeeControlPage()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final request = searches().single.request;
    expect(request.classroomId, 'c-a');
    expect(request.feeCodes, ['TRANSPORT']);
    expect(request.statusFilter, FeeControlPaymentFilter.none);
  });

  testWidgets('la classe porte deux devises : « a payé au moins… » tombe et '
      'la situation revient à « Tous »', (tester) async {
    await pump(
      tester,
      intent: const FeeControlIntent(
        classroomId: 'c-a',
        feeCodes: ['TUITION'],
        situation: FeeControlPaymentFilter.threshold,
        thresholdInCents: 5000,
      ),
      states: [
        tCatalog,
        // La lecture servie révèle deux devises dans la classe.
        tCatalog.copyWith(
          status: EnrollmentLoadStatus.success,
          currencies: const {'USD', 'CDF'},
          lastQuery: const FeeControlQuery(
            academicYearId: 'ay-1',
            classroomId: 'c-a',
            feeCodes: ['TUITION'],
            statusFilter: FeeControlPaymentFilter.threshold,
            page: 0,
            size: 10,
          ),
        ),
      ],
    );

    // La population est déjà lue : seule la coupe change, sans plancher.

    verify(
      () => bloc.add(
        const FeeControlSituationRequested(FeeControlPaymentFilter.all),
      ),
    ).called(1);
  });
}
