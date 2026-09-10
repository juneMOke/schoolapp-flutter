import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_till_receipts_report_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_report_cubit.dart';

class MockGetTillReceiptsReportUseCase extends Mock
    implements GetTillReceiptsReportUseCase {}

final _report = TillReport(
  bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]),
  fileName: 'encaissements-USD-2026-05-15_2026-05-15.pdf',
);

/// Le téléchargement du rapport — **un à la fois, et l'attente se respecte**.
void main() {
  setUpAll(() => registerFallbackValue(const TillWindow.day()));

  late MockGetTillReceiptsReportUseCase mockUseCase;

  setUp(() => mockUseCase = MockGetTillReceiptsReportUseCase());

  FinanceTillReportCubit buildCubit() =>
      FinanceTillReportCubit(getTillReceiptsReportUseCase: mockUseCase);

  void stub(Either<Failure, TillReport> result) {
    when(
      () => mockUseCase(window: any(named: 'window')),
    ).thenAnswer((_) async => result);
  }

  group('le rendu', () {
    blocTest<FinanceTillReportCubit, FinanceTillReportState>(
      'la fenêtre est transmise telle quelle, et rien ne cadre le document',
      setUp: () => stub(Right(_report)),
      build: buildCubit,
      act: (cubit) => cubit.download(window: const TillWindow.month()),
      verify: (cubit) {
        expect(cubit.state.report, _report);
        // ⚠️ Aucune devise ne part : le document rend les deux unités, comme la
        // table dont il est la sortie. En envoyer une le cadrerait sur une
        // caisse que personne n'a demandée — et le pied du document rend un
        // total par devise, jamais leur somme.
        verify(() => mockUseCase(window: const TillWindow.month())).called(1);
      },
    );

    blocTest<FinanceTillReportCubit, FinanceTillReportState>(
      'le bouton se désarme pendant la préparation',
      setUp: () => stub(Right(_report)),
      build: buildCubit,
      act: (cubit) => cubit.download(window: const TillWindow.day()),
      expect: () => [
        // Un rendu prend plusieurs secondes : sans cet état, deux appuis
        // lancent deux rendus et le second part en 429.
        isA<FinanceTillReportState>()
            .having(
              (s) => s.status,
              'status',
              FinanceTillReportStatus.preparing,
            )
            .having((s) => s.isBusy, 'isBusy', isTrue),
        isA<FinanceTillReportState>()
            .having((s) => s.status, 'status', FinanceTillReportStatus.idle)
            .having((s) => s.report, 'report', _report),
      ],
    );

    blocTest<FinanceTillReportCubit, FinanceTillReportState>(
      'un second appui pendant le rendu ne relance rien',
      setUp: () => stub(Right(_report)),
      build: buildCubit,
      seed: () => const FinanceTillReportState(
        status: FinanceTillReportStatus.preparing,
      ),
      act: (cubit) => cubit.download(window: const TillWindow.day()),
      expect: () => const <FinanceTillReportState>[],
      verify: (_) =>
          verifyNever(() => mockUseCase(window: any(named: 'window'))),
    );
  });

  group('l’attente imposée', () {
    blocTest<FinanceTillReportCubit, FinanceTillReportState>(
      'un 429 n’est pas un échec : il désarme le bouton pour le délai annoncé',
      setUp: () => stub(
        const Left(TooManyRequestsFailure(retryAfter: Duration(seconds: 45))),
      ),
      build: buildCubit,
      act: (cubit) => cubit.download(window: const TillWindow.day()),
      verify: (cubit) {
        // Le serveur ne compose qu'un rapport à la fois. Réarmer tout de suite
        // inviterait à reproduire exactement ce qu'il vient de refuser.
        expect(cubit.state.status, FinanceTillReportStatus.cooldown);
        expect(cubit.state.isBusy, isTrue);
        expect(cubit.state.retryAfter, const Duration(seconds: 45));
      },
    );

    blocTest<FinanceTillReportCubit, FinanceTillReportState>(
      'pendant l’attente, un nouvel appui ne part pas',
      setUp: () => stub(Right(_report)),
      build: buildCubit,
      seed: () => const FinanceTillReportState(
        status: FinanceTillReportStatus.cooldown,
        retryAfter: Duration(seconds: 60),
      ),
      act: (cubit) => cubit.download(window: const TillWindow.day()),
      expect: () => const <FinanceTillReportState>[],
      verify: (_) =>
          verifyNever(() => mockUseCase(window: any(named: 'window'))),
    );

    test('le délai écoulé réarme le bouton', () async {
      stub(
        const Left(
          TooManyRequestsFailure(retryAfter: Duration(milliseconds: 40)),
        ),
      );
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.download(window: const TillWindow.day());
      expect(cubit.state.isBusy, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Le refus était temporaire : passé son délai, le geste redevient
      // possible sans que l'utilisateur ait à recharger l'écran.
      expect(cubit.state.status, FinanceTillReportStatus.idle);
      expect(cubit.state.isBusy, isFalse);
    });

    test('un 429 sans délai annoncé retombe sur une minute', () async {
      stub(const Left(TooManyRequestsFailure()));
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.download(window: const TillWindow.day());

      // Sans repli, `retryAfter` nul laisserait le bouton désarmé pour
      // toujours — le pire des deux échecs possibles.
      expect(cubit.state.retryAfter, const Duration(seconds: 60));
    });
  });

  group('l’échec ordinaire', () {
    blocTest<FinanceTillReportCubit, FinanceTillReportState>(
      'le refus de plafond revient armé — c’est la période qu’il faut changer',
      setUp: () => stub(
        const Left(
          ValidationFailure('Le rapport dépasse 5 000 lignes (7 213).'),
        ),
      ),
      build: buildCubit,
      act: (cubit) => cubit.download(window: const TillWindow.year()),
      verify: (cubit) {
        // Contrairement au 429, rien n'est à attendre : le lecteur doit
        // resserrer sa fenêtre, et le bouton doit rester utilisable pour ça.
        expect(cubit.state.status, FinanceTillReportStatus.idle);
        expect(cubit.state.isBusy, isFalse);
        expect(
          cubit.state.failure?.message,
          contains('7 213'),
          reason:
              'le message du serveur porte le compte réel : « resserrez » sans '
              'ce chiffre ne guide rien',
        );
      },
    );
  });

  group('la remise', () {
    test('le document ne reste pas dans l’état une fois remis', () async {
      stub(Right(_report));
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.download(window: const TillWindow.day());
      expect(cubit.state.hasDelivery, isTrue);

      cubit.acknowledge();

      // Le serveur n'archive pas cette pièce : un document laissé là se ferait
      // re-remettre à la reconstruction suivante comme s'il était « le »
      // rapport, alors qu'il n'en est qu'un tirage.
      expect(cubit.state.report, isNull);
      expect(cubit.state.hasDelivery, isFalse);
    });

    test('acquitter pendant l’attente ne réarme pas le bouton', () async {
      stub(
        const Left(TooManyRequestsFailure(retryAfter: Duration(seconds: 60))),
      );
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.download(window: const TillWindow.day());
      cubit.acknowledge();

      // Le message a été dit ; l'attente, elle, court toujours.
      expect(cubit.state.status, FinanceTillReportStatus.cooldown);
      expect(cubit.state.isBusy, isTrue);
      expect(cubit.state.failure, isNull);
    });
  });
}
