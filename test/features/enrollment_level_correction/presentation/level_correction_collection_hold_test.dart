import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_collection_hold.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockHeld extends Mock
    implements IsCollectionHeldByLevelCorrectionUseCase {}

void main() {
  late _MockHeld held;

  setUp(() {
    held = _MockHeld();
    getIt.registerSingleton<IsCollectionHeldByLevelCorrectionUseCase>(held);
  });
  tearDown(() => getIt.reset());

  void answer(Either<Failure, bool> result) => when(
    () => held(
      studentId: any(named: 'studentId'),
      academicYearId: any(named: 'academicYearId'),
    ),
  ).thenAnswer((_) async => result);

  Future<bool?> run(WidgetTester tester) async {
    bool? allowed;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                allowed = await ensureCollectionNotHeldByLevelCorrection(
                  context,
                  studentId: 'stu-1',
                  academicYearId: 'year-1',
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return allowed;
  }

  String heldMessage(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(Scaffold)),
  )!.levelCorrectionCollectionHeld;

  testWidgets('caisse retenue : refus, et le guichet sait pourquoi', (
    tester,
  ) async {
    answer(const Right(true));
    expect(await run(tester), isFalse);
    expect(find.text(heldMessage(tester)), findsOneWidget);
  });

  testWidgets('caisse ouverte : passe, sans message', (tester) async {
    answer(const Right(false));
    expect(await run(tester), isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    "lecture en échec : passe — l'écriture du versement reste le rempart",
    (tester) async {
      answer(const Left(StorageFailure('x')));
      expect(await run(tester), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    },
  );
}
