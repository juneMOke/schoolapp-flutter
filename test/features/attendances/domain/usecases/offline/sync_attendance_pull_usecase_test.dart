import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_attendance_pull_usecase.dart';

class _MockPullCoordinator extends Mock implements PullCoordinator {}

/// Depuis ADR-015 F6, ce use case ne possède plus qu'une chose : **l'ensemble
/// des ressources dont l'écran a besoin**. Les gardes qu'il portait — pré-garde
/// de connectivité, sonde de crédentiels, filtre de permission, isolation des
/// échecs — sont dans le socle, où elles valent pour les deux points d'entrée du
/// coordinateur et sont prouvées une seule fois.
///
/// Les tester encore ici les prouverait sur un mock, c'est-à-dire nulle part :
/// un `PullCoordinator` bouchonné ne refuse rien. Ce fichier vérifie donc le
/// contrat qui reste — quelles ressources sont demandées, et que rien n'est
/// décidé avant de les demander.
void main() {
  late _MockPullCoordinator coordinator;
  late SyncAttendancePullUseCase useCase;

  setUpAll(() => registerFallbackValue(<String>{}));

  setUp(() {
    coordinator = _MockPullCoordinator();
    when(
      () => coordinator.pullSubset(any()),
    ).thenAnswer((_) async => const PullRunReport(updated: 1));
    useCase = SyncAttendancePullUseCase(coordinator);
  });

  Set<String> demande() =>
      verify(() => coordinator.pullSubset(captureAny())).captured.single
          as Set<String>;

  test('demande la ressource Présence, et elle seule', () async {
    await useCase();

    expect(demande(), {kAttendanceResource});
  });

  test('délègue sans condition : aucune garde n\'est rejouée ici', () async {
    await useCase();

    verify(() => coordinator.pullSubset(any())).called(1);
    // Le socle décide de tirer ou non ; le use case ne consulte ni la
    // connectivité, ni les crédentiels, ni les droits — il n'a plus de quoi.
    verifyNoMoreInteractions(coordinator);
  });

  test('rend le bilan du cycle tel quel, sans le réinterpréter', () async {
    const bilan = PullRunReport(
      failed: 1,
      outcomes: {kAttendanceResource: PullResult.error},
    );
    when(() => coordinator.pullSubset(any())).thenAnswer((_) async => bilan);

    final rapport = await useCase();

    expect(identical(rapport, bilan), isTrue);
    expect(rapport.succeeded(kAttendanceResource), isFalse);
  });
}
