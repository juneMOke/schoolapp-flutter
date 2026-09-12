import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_report_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_report_cubit.dart';

class _MockUseCase extends Mock implements GetEnrollmentEntriesReportUseCase {}

typedef _Result = Either<Failure, EnrollmentEntriesReport>;

final _report = EnrollmentEntriesReport(
  bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]),
  fileName: 'inscriptions-2026-09-01_2026-09-07.pdf',
);

/// Le téléchargement du registre — **un à la fois, et l'attente se respecte**.
void main() {
  setUpAll(() => registerFallbackValue(const EnrollmentStatsWindow.year()));

  late _MockUseCase useCase;

  setUp(() => useCase = _MockUseCase());

  EnrollmentEntriesReportCubit build() =>
      EnrollmentEntriesReportCubit(getReportUseCase: useCase);

  void stub(_Result result) {
    when(
      () => useCase(window: any(named: 'window')),
    ).thenAnswer((_) async => result);
  }

  group('le rendu', () {
    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'la fenêtre de la liste est transmise telle quelle',
      setUp: () => stub(Right(_report)),
      build: build,
      act: (cubit) =>
          cubit.download(window: const EnrollmentStatsWindow.week()),
      verify: (cubit) {
        expect(cubit.state.report, _report);
        verify(
          () => useCase(window: const EnrollmentStatsWindow.week()),
        ).called(1);
      },
    );

    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'le bouton se désarme pendant la préparation',
      setUp: () => stub(Right(_report)),
      build: build,
      act: (cubit) =>
          cubit.download(window: const EnrollmentStatsWindow.year()),
      expect: () => [
        // Un registre d'une année prend plusieurs secondes : sans cet état,
        // deux appuis lancent deux rendus et le second part en 429.
        isA<EnrollmentEntriesReportState>()
            .having(
              (s) => s.status,
              'status',
              EnrollmentEntriesReportStatus.preparing,
            )
            .having((s) => s.isBusy, 'isBusy', isTrue),
        isA<EnrollmentEntriesReportState>()
            .having(
              (s) => s.status,
              'status',
              EnrollmentEntriesReportStatus.idle,
            )
            .having((s) => s.report, 'report', _report),
      ],
    );

    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'un second appui pendant le rendu ne relance rien',
      setUp: () => stub(Right(_report)),
      build: build,
      seed: () => const EnrollmentEntriesReportState(
        status: EnrollmentEntriesReportStatus.preparing,
      ),
      act: (cubit) =>
          cubit.download(window: const EnrollmentStatsWindow.year()),
      expect: () => const <EnrollmentEntriesReportState>[],
      verify: (_) => verifyNever(() => useCase(window: any(named: 'window'))),
    );

    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'un échec ordinaire réarme le bouton et se dit une fois',
      setUp: () => stub(const Left(NetworkFailure('coupure'))),
      build: build,
      act: (cubit) =>
          cubit.download(window: const EnrollmentStatsWindow.month()),
      skip: 1,
      expect: () => [
        isA<EnrollmentEntriesReportState>()
            .having(
              (s) => s.status,
              'status',
              EnrollmentEntriesReportStatus.idle,
            )
            .having((s) => s.failure, 'failure', isA<NetworkFailure>())
            .having((s) => s.hasDelivery, 'hasDelivery', isTrue),
      ],
    );
  });

  group('l’attente imposée', () {
    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'un 429 désarme le bouton pour le délai annoncé',
      setUp: () => stub(
        const Left(TooManyRequestsFailure(retryAfter: Duration(seconds: 45))),
      ),
      build: build,
      act: (cubit) =>
          cubit.download(window: const EnrollmentStatsWindow.year()),
      verify: (cubit) {
        // Le serveur ne compose qu'un document long à la fois, file partagée
        // avec la caisse et la relance.
        expect(cubit.state.status, EnrollmentEntriesReportStatus.cooldown);
        expect(cubit.state.isBusy, isTrue);
        expect(cubit.state.retryAfter, const Duration(seconds: 45));
      },
    );

    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'pendant l’attente, un nouvel appui ne part pas',
      setUp: () => stub(Right(_report)),
      build: build,
      seed: () => const EnrollmentEntriesReportState(
        status: EnrollmentEntriesReportStatus.cooldown,
        retryAfter: Duration(seconds: 60),
      ),
      act: (cubit) =>
          cubit.download(window: const EnrollmentStatsWindow.year()),
      expect: () => const <EnrollmentEntriesReportState>[],
      verify: (_) => verifyNever(() => useCase(window: any(named: 'window'))),
    );

    test('le délai écoulé réarme le bouton', () async {
      stub(
        const Left(
          TooManyRequestsFailure(retryAfter: Duration(milliseconds: 40)),
        ),
      );
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.download(window: const EnrollmentStatsWindow.year());
      expect(cubit.state.isBusy, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(cubit.state.status, EnrollmentEntriesReportStatus.idle);
      expect(cubit.state.isBusy, isFalse);
    });

    test('un 429 sans délai annoncé retombe sur une minute', () async {
      stub(const Left(TooManyRequestsFailure()));
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.download(window: const EnrollmentStatsWindow.year());

      // Sans repli, `retryAfter` nul laisserait le bouton désarmé pour
      // toujours — le pire des deux échecs possibles.
      expect(cubit.state.retryAfter, const Duration(seconds: 60));
    });
  });

  group('la remise', () {
    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'acknowledge vide ce qui a été remis, et garde l’attente en cours',
      build: build,
      seed: () => const EnrollmentEntriesReportState(
        status: EnrollmentEntriesReportStatus.cooldown,
        failure: TooManyRequestsFailure(),
        retryAfter: Duration(seconds: 60),
      ),
      act: (cubit) => cubit.acknowledge(),
      expect: () => const [
        EnrollmentEntriesReportState(
          status: EnrollmentEntriesReportStatus.cooldown,
          retryAfter: Duration(seconds: 60),
        ),
      ],
    );

    blocTest<EnrollmentEntriesReportCubit, EnrollmentEntriesReportState>(
      'acknowledge sans rien à remettre n’émet rien',
      build: build,
      act: (cubit) => cubit.acknowledge(),
      expect: () => const <EnrollmentEntriesReportState>[],
    );

    test('quitter l’écran pendant le rendu ne fait pas lever', () async {
      // Un registre d'une année prend plusieurs secondes : le scope a pu
      // fermer le cubit avant que le document n'arrive.
      final pending = Completer<_Result>();
      when(
        () => useCase(window: any(named: 'window')),
      ).thenAnswer((_) => pending.future);
      final cubit = build();

      final download = cubit.download(
        window: const EnrollmentStatsWindow.year(),
      );
      await cubit.close();
      pending.complete(Right(_report));

      await expectLater(download, completes);
    });
  });
}
