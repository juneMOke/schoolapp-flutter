import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_sheet.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../fixtures/recovery_fixtures.dart';

class _Repo extends Mock implements RecoveryDashboardRepository {}

class _Pending extends Mock implements CountPendingPaymentsUseCase {}

RecoveryStudentsPage _page(RecoveryStudentsPage base, {bool empty = false}) =>
    RecoveryStudentsPage(
      situationAt: base.situationAt,
      pendingWrites: 0,
      title: 'Liste de tous les élèves pour Frais de scolarité',
      currencies: base.currencies,
      atLeastAvailable: true,
      counts: base.counts,
      situationCounts: const RecoverySituationCounts(
        noPayment: 12,
        partial: 13,
        settled: 15,
      ),
      content: empty ? const [] : base.content.take(5).toList(),
      page: 0,
      size: 100,
      totalElements: empty ? 0 : 5,
      totalPages: 1,
    );

void main() {
  late _Repo repo;
  final queries = <RecoveryStudentsQuery>[];
  final base = recoveryStudentsFixture();
  final row = recoveryDashboardFixture().classRankings.single.ranked[2];
  const question = RecoveryQuestion(feeCodes: ['TUITION', 'SUPPLIES']);

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

  void answer(Either<Failure, RecoveryStudentsPage> Function(String?) f) =>
      when(
        () => repo.students(
          any(),
          any(),
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((inv) async {
        final q = inv.positionalArguments[1] as RecoveryStudentsQuery;
        queries.add(q);
        return f(q.situation);
      });

  Future<void> open(
    WidgetTester tester, {
    double width = 1280,
    double height = 900,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showRecoveryClassSheet(
                context,
                academicYearId: 'y1',
                question: question,
                feeCode: 'TUITION',
                feeLabel: 'Frais de scolarité',
                row: row,
                situationAt: DateTime(2026, 9, 5),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('en-tête, chiffres, filtre à compteur, liste ; requête O2', (
    tester,
  ) async {
    answer((_) => Right(_page(base)));
    await open(tester);
    expect(find.text('PRIMAIRE · FRAIS DE SCOLARITÉ'), findsOneWidget);
    expect(find.text('1ère primaire'), findsOneWidget);
    expect(find.text('40 élèves · situation au 05/09/2026'), findsOneWidget);
    expect(find.text('${row.ratePercent} %'), findsOneWidget);
    expect(find.text('40'), findsOneWidget); // Tous = 12 + 13 + 15
    expect(find.text(base.content.first.displayName), findsOneWidget);
    expect(find.text('Ouvrir dans le contrôle'), findsOneWidget);

    final q = queries.single;
    expect(q.question.feeCodes, ['TUITION']);
    expect(q.tab, RecoveryTab.all);
    expect(q.classroomId, 'c3');
    expect(q.situation, isNull);
    expect(q.size, 100);

    final exports = tester.widget<RecoveryExportButtons>(
      find.byType(RecoveryExportButtons),
    );
    expect(exports.enabled, isTrue);
    expect(exports.title, 'Liste de tous les élèves pour Frais de scolarité');
    expect(exports.query.classroomId, 'c3');
    expect(tester.takeException(), isNull);
  });

  testWidgets('le filtre relit la liste ; vide : « Aucun élève dans ce '
      'filtre. »', (tester) async {
    answer((s) => Right(_page(base, empty: s == 'PARTIAL')));
    await open(tester);
    await tester.tap(find.text('Partiel').first);
    await tester.pumpAndSettle();
    expect(queries.last.situation, 'PARTIAL');
    expect(find.text('Aucun élève dans ce filtre.'), findsOneWidget);
    final exports = tester.widget<RecoveryExportButtons>(
      find.byType(RecoveryExportButtons),
    );
    expect(exports.enabled, isFalse);
    expect(exports.query.situation, 'PARTIAL');
  });

  testWidgets('403 : message dans la sur-couche, sans « Réessayer »', (
    tester,
  ) async {
    answer((_) => const Left(UnauthorizedFailure()));
    await open(tester);
    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('hors ligne : Réessayer, exports inactifs', (tester) async {
    answer((_) => const Left(NetworkFailure()));
    await open(tester);
    expect(find.text('Réessayer'), findsOneWidget);
    final exports = tester.widget<RecoveryExportButtons>(
      find.byType(RecoveryExportButtons),
    );
    expect(exports.enabled, isFalse);
    expect(exports.disabledReason, 'Les exports attendent le réseau.');
  });

  testWidgets('Non affectés : classroomId UNASSIGNED', (tester) async {
    answer((_) => Right(_page(base)));
    final unassigned =
        recoveryDashboardFixture().classRankings.single.unassigned!;
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRecoveryClassSheet(
              context,
              academicYearId: 'y1',
              question: question,
              feeCode: 'TUITION',
              feeLabel: 'Frais de scolarité',
              row: unassigned,
              situationAt: DateTime(2026, 9, 5),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(queries.single.classroomId, 'UNASSIGNED');
    // Sans cycle, le sur-titre est le frais seul.
    expect(find.text('FRAIS DE SCOLARITÉ'), findsOneWidget);
  });

  for (final width in [360.0, 600.0, 800.0, 1280.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$width dp, texte ×$scale : aucun débordement', (
        tester,
      ) async {
        answer((_) => Right(_page(base)));
        await open(tester, width: width, height: 800, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
