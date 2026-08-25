import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/documents_student_table.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_labels.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _FakeEnrollmentLocalListBloc extends Cubit<EnrollmentLocalListState>
    implements EnrollmentLocalListBloc {
  _FakeEnrollmentLocalListBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EnrollmentSummary _summary({
  String enrollmentId = 'e-1',
  String lastName = 'Mbala',
  String surname = 'Kasa',
  String firstName = 'Amina',
  String? schoolLevelId,
  String? schoolLevelName,
  String? schoolLevelGroupName,
}) => EnrollmentSummary(
  enrollmentId: enrollmentId,
  enrollmentCode: 'MAT-001',
  status: 'CONFIRMED',
  enrollmentType: 'NEW',
  syncState: SyncState.synced,
  schoolLevelId: schoolLevelId,
  schoolLevelName: schoolLevelName,
  schoolLevelGroupName: schoolLevelGroupName,
  student: StudentSummary(
    id: 's-$enrollmentId',
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: '2014-02-01',
    gender: Gender.female,
  ),
);

/// Fabrique d'état : le constructeur de `EnrollmentLocalListState` exige tous
/// ses champs, ce qui rendrait chaque cas de test illisible.
EnrollmentLocalListState _state({
  EnrollmentLoadStatus status = EnrollmentLoadStatus.initial,
  List<EnrollmentSummary> summaries = const <EnrollmentSummary>[],
  EnrollmentSummaryQueryType? queryType,
  EnrollmentSummariesQuery? lastQuery,
  String? errorMessage,
}) => EnrollmentLocalListState(
  summariesStatus: status,
  summaries: summaries,
  summariesPage: 0,
  summariesSize: AppConstants.enrollmentDefaultPageSize,
  summariesTotalElements: summaries.length,
  summariesTotalPages: summaries.isEmpty ? 0 : 1,
  summariesQueryType: queryType,
  lastSummariesQuery: lastQuery,
  summariesErrorType: null,
  errorMessage: errorMessage,
);

Future<void> _pump(
  WidgetTester tester,
  EnrollmentLocalListState state, {
  void Function(EnrollmentSummary)? onCatalogRequested,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<EnrollmentLocalListBloc>(
          create: (_) => _FakeEnrollmentLocalListBloc(state),
          child: DocumentsStudentTable(
            onCatalogRequested: onCatalogRequested ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Avant toute recherche : une invite, jamais un tableau vide — qui se lirait
  // « cet élève n'a rien » alors qu'on n'a encore rien demandé.
  testWidgets('invite à chercher tant qu aucune recherche n est lancée', (
    tester,
  ) async {
    await _pump(tester, _state());

    expect(find.text("Trouvez l'élève, ouvrez ses documents"), findsOneWidget);
  });

  testWidgets('affiche le tableau des élèves trouvés', (tester) async {
    await _pump(
      tester,
      _state(
        queryType: EnrollmentSummaryQueryType.byAcademicInfo,
        status: EnrollmentLoadStatus.success,
        summaries: [_summary()],
      ),
    );

    expect(find.text('Mbala'), findsOneWidget);
    expect(find.text('Amina'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ouvre le catalogue au tap de la ligne', (tester) async {
    EnrollmentSummary? opened;
    await _pump(
      tester,
      _state(
        queryType: EnrollmentSummaryQueryType.byAcademicInfo,
        status: EnrollmentLoadStatus.success,
        summaries: [_summary()],
      ),
      onCatalogRequested: (summary) => opened = summary,
    );

    await tester.tap(find.byTooltip('Ouvrir les documents'));
    await tester.pump();

    expect(opened?.enrollmentId, 'e-1');
  });

  // Le segment de classe que le sur-titre du catalogue laissait tomber : les
  // critères d'une recherche par identité ne portent aucun niveau, la ligne si.
  testWidgets('recherche par identité : la ligne ouverte porte sa classe', (
    tester,
  ) async {
    EnrollmentSummary? opened;
    await _pump(
      tester,
      _state(
        queryType: EnrollmentSummaryQueryType.byAcademicInfo,
        status: EnrollmentLoadStatus.success,
        summaries: [
          _summary(
            schoolLevelId: 'lvl-5p',
            schoolLevelName: '5e primaire',
            schoolLevelGroupName: 'Primaire',
          ),
        ],
        lastQuery: const EnrollmentSummariesQuery(
          type: EnrollmentSummaryQueryType.byAcademicInfo,
          status: '',
          academicYearId: 'y-1',
          page: 0,
          size: 10,
          lastName: 'Mbala',
        ),
      ),
      onCatalogRequested: (summary) => opened = summary,
    );

    await tester.tap(find.byTooltip('Ouvrir les documents'));
    await tester.pump();

    // Ce que la page compose ensuite : référentiel vide et aucun critère de
    // niveau — la ligne doit suffire.
    final labels = resolveEnrollmentLevelLabels(
      opened!,
      bundles: const [],
      searchedLevelId: null,
    );
    expect(labels.levelName, '5e primaire');
    expect(labels.levelGroupName, 'Primaire');
  });

  testWidgets('affiche l état vide avec les critères cherchés', (tester) async {
    await _pump(
      tester,
      _state(
        queryType: EnrollmentSummaryQueryType.byAcademicInfo,
        status: EnrollmentLoadStatus.success,
        lastQuery: const EnrollmentSummariesQuery(
          type: EnrollmentSummaryQueryType.byAcademicInfo,
          status: '',
          academicYearId: 'y-1',
          page: 0,
          size: 10,
          lastName: 'Mbala',
        ),
      ),
    );

    expect(find.text('Aucun élève trouvé'), findsOneWidget);
    expect(find.textContaining('Mbala'), findsOneWidget);
  });

  testWidgets('affiche l anatomie d erreur partagée', (tester) async {
    await _pump(
      tester,
      _state(
        queryType: EnrollmentSummaryQueryType.byAcademicInfo,
        status: EnrollmentLoadStatus.failure,
        errorMessage: 'base illisible',
      ),
    );

    expect(
      find.byKey(const ValueKey('documents-results-error')),
      findsOneWidget,
    );
  });
}
