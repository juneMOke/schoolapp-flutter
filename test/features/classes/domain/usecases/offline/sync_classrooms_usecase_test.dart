import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';

class _MockPullCoordinator extends Mock implements PullCoordinator {}

/// Depuis ADR-015 F6, ce use case ne possède plus qu'une chose : **l'ensemble
/// des ressources dont l'écran Classes a besoin**. Le gate de connectivité qu'il
/// portait vit dans le socle, avec la sonde de crédentiels, le filtre de
/// permission et l'isolation des échecs.
///
/// L'`academicYearId` a disparu de sa signature : les handlers du coordinateur
/// résolvent l'année courante eux-mêmes, par la même ligne de DAO que l'écran
/// (`findCurrentAcademicYearId`, scopée école). Il n'y a donc plus rien à
/// vérifier sur ce paramètre — et rien à vérifier NON PLUS sur l'ordre des deux
/// ressources : `pullSubset` itère le registre filtré, jamais l'ensemble reçu.
/// L'ordre du registre est ancré par
/// `test/core/di/offline_pull_registration_order_test.dart`.
void main() {
  late _MockPullCoordinator coordinator;
  late SyncClassroomsUseCase useCase;

  setUpAll(() => registerFallbackValue(<String>{}));

  setUp(() {
    coordinator = _MockPullCoordinator();
    when(
      () => coordinator.pullSubset(any()),
    ).thenAnswer((_) async => const PullRunReport(updated: 2));
    useCase = SyncClassroomsUseCase(coordinator);
  });

  Set<String> demande() =>
      verify(() => coordinator.pullSubset(captureAny())).captured.single
          as Set<String>;

  test(
    'demande les classes ET le roster — l\'écran a besoin des deux',
    () async {
      await useCase();

      expect(demande(), {kClassroomsResource, kClassroomMembersResource});
    },
  );

  test('l\'ensemble annoncé publiquement est celui réellement demandé', () async {
    // Le BLoC interroge `PullRunReport.succeeded` sur cette constante : si elle
    // divergeait de l'appel, il jugerait la synchro sur des ressources qui n'ont
    // jamais été demandées — et afficherait un échec permanent.
    await useCase();

    expect(demande(), SyncClassroomsUseCase.resources);
  });

  test('délègue sans condition : aucune garde n\'est rejouée ici', () async {
    await useCase();

    verify(() => coordinator.pullSubset(any())).called(1);
    verifyNoMoreInteractions(coordinator);
  });

  test('rend le bilan du cycle tel quel, sans le réinterpréter', () async {
    const bilan = PullRunReport(
      updated: 1,
      failed: 1,
      outcomes: {
        kClassroomsResource: PullResult.updated,
        kClassroomMembersResource: PullResult.error,
      },
    );
    when(() => coordinator.pullSubset(any())).thenAnswer((_) async => bilan);

    final rapport = await useCase();

    expect(identical(rapport, bilan), isTrue);
    expect(rapport.succeeded(kClassroomsResource), isTrue);
    expect(rapport.succeeded(kClassroomMembersResource), isFalse);
  });
}
