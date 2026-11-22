import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_call_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import 'simulation_test_harness.dart';

class _Repo extends Mock implements RecoveryDashboardRepository {}

class _Pending extends Mock implements CountPendingPaymentsUseCase {}

RecoveryStudentsPage _page(
  int page,
  int totalPages,
  List<RecoveryStudentRow> rows,
) {
  final base = recoveryStudentsFixture();
  return RecoveryStudentsPage(
    situationAt: base.situationAt,
    pendingWrites: 0,
    title: base.title,
    currencies: base.currencies,
    atLeastAvailable: true,
    counts: base.counts,
    situationCounts: base.situationCounts,
    content: rows,
    page: page,
    size: 100,
    totalElements: rows.length * totalPages,
    totalPages: totalPages,
  );
}

void main() {
  late _Repo repo;
  final queries = <RecoveryStudentsQuery>[];
  final students = recoveryStudentsFixture().content;
  const question = RecoveryQuestion(feeCodes: ['TUITION']);
  final row = simRow('c5', '3ème primaire', headcount: 36, targeted: 12);

  setUpAll(() {
    registerFallbackValue(const RecoveryStudentsQuery(question: question));
  });

  setUp(() {
    repo = _Repo();
    queries.clear();
    final pending = _Pending();
    when(pending.call).thenAnswer((_) async => const Right(0));
    getIt.registerFactory<RecoveryStudentsCubit>(
      () => RecoveryStudentsCubit(repository: repo, countPending: pending),
    );
  });

  tearDown(() => getIt.unregister<RecoveryStudentsCubit>());

  void answer(Either<Failure, RecoveryStudentsPage> Function(int page) f) =>
      when(
        () => repo.students(
          any(),
          any(),
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((inv) async {
        final q = inv.positionalArguments[1] as RecoveryStudentsQuery;
        queries.add(q);
        return f(q.page);
      });

  Future<void> open(WidgetTester tester, {double width = 1280}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRecoverySimulationCallList(
                context,
                academicYearId: 'y1',
                question: question,
                row: row,
                criterionLabel: "N'ont rien payé",
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('les élèves visés de la classe, à signer (O5)', (tester) async {
    answer((_) => Right(_page(0, 1, students.take(3).toList())));
    await open(tester);

    final q = queries.single;
    expect(q.tab, RecoveryTab.toChase);
    expect(q.classroomId, 'c5');
    expect(q.size, 100);
    expect(find.text('Élèves visés — 3ème primaire'), findsOneWidget);
    expect(find.text(students.first.displayName), findsOneWidget);
    expect(find.text(students.first.matriculationNumber!), findsOneWidget);
    expect(find.text('Signature du parent'), findsOneWidget);
    expect(find.text('Visa du percepteur'), findsOneWidget);
    expect(find.text('Imprimer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toutes les pages sont lues : personne ne disparaît', (
    tester,
  ) async {
    answer((page) => Right(_page(page, 2, [students[page]])));
    await open(tester);

    expect(queries.map((q) => q.page), [0, 1]);
    expect(find.text(students[0].displayName), findsOneWidget);
    expect(find.text(students[1].displayName), findsOneWidget);
  });

  testWidgets('« Non affectés » se lit sous UNASSIGNED', (tester) async {
    answer((_) => Right(_page(0, 1, students.take(1).toList())));
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRecoverySimulationCallList(
              context,
              academicYearId: 'y1',
              question: question,
              row: simRow(null, 'Non affectés', headcount: 6, targeted: 4),
              criterionLabel: "N'ont rien payé",
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    addTearDown(tester.view.reset);
    await tester.tap(find.text('ouvrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(queries.single.classroomId, recoveryUnassigned);
  });

  testWidgets('erreur : un message, pas de feuille vide', (tester) async {
    answer((_) => const Left(NetworkFailure()));
    await open(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Signature du parent'), findsNothing);
    expect(find.textContaining('Vérifiez la connexion'), findsOneWidget);
  });

  testWidgets('plein écran sous 760, centrée au-delà (A14)', (tester) async {
    answer((_) => Right(_page(0, 1, students.take(3).toList())));
    await open(tester, width: 360);
    expect(
      find.byWidgetPredicate(
        (w) => w is Dialog && w.runtimeType.toString() == 'Dialog',
      ),
      findsWidgets,
    );
    final size = tester.getSize(find.byType(Dialog).first);
    expect(size.width, 360);
    expect(tester.takeException(), isNull);
  });
}
