import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classroom_referential_use_case.dart';

class _MockPullCoordinator extends Mock implements PullCoordinator {}

/// ADR-015 §6-D — `classroom.transfers` n'a qu'un seul déclencheur de montage,
/// et c'est ce use case. Sans lui, ce flux ne descend qu'au retour *online* :
/// sur une tablette démarrée déjà connectée — le cas nominal — le marqueur de
/// bootstrap des transferts n'est jamais posé, et l'onglet Présence de la fiche
/// élève reste à vie sur « Synchronisation en attente ».
///
/// Depuis F6, le use case ne tire plus les repositories lui-même : le marqueur
/// est posé par `ClassroomTransferPullRepositoryImpl` en fin de cycle, appelée
/// par `ClassroomTransferPullHandler` — le MÊME `syncTransfers()`. Ce qui reste
/// à prouver ici est donc devenu très étroit, et c'est exactement ce qui peut
/// encore se perdre : **que les transferts figurent dans ce qui est demandé**.
///
/// Ce que ce fichier ne teste plus, et pourquoi :
///  - l'ordre classes → transferts : `pullSubset` itère le registre, jamais
///    l'ensemble reçu ; l'ordre est ancré par
///    `test/core/di/offline_pull_registration_order_test.dart` ;
///  - l'isolation d'un échec : le socle isole par handler, prouvé chez lui ;
///  - les gardes connectivité / crédentiels / année : parties dans le socle.
void main() {
  late _MockPullCoordinator coordinator;
  late SyncClassroomReferentialUseCase useCase;

  setUpAll(() => registerFallbackValue(<String>{}));

  setUp(() {
    coordinator = _MockPullCoordinator();
    when(
      () => coordinator.pullSubset(any()),
    ).thenAnswer((_) async => const PullRunReport(updated: 3));
    useCase = SyncClassroomReferentialUseCase(coordinator);
  });

  Set<String> demande() =>
      verify(() => coordinator.pullSubset(captureAny())).captured.single
          as Set<String>;

  test('demande les trois flux du référentiel Classe', () async {
    await useCase();

    expect(demande(), {
      kClassroomsResource,
      kClassroomMembersResource,
      kClassroomTransfersResource,
    });
  });

  test(
    'les transferts sont demandés : sans eux, aucun marqueur de bootstrap et '
    'l\'onglet Présence reste à vie en attente de synchro',
    () async {
      await useCase();

      expect(demande(), contains(kClassroomTransfersResource));
    },
  );

  test(
    'l\'ensemble annoncé publiquement est celui réellement demandé',
    () async {
      await useCase();

      expect(demande(), SyncClassroomReferentialUseCase.resources);
    },
  );

  test('délègue sans condition : aucune garde n\'est rejouée ici', () async {
    await useCase();

    verify(() => coordinator.pullSubset(any())).called(1);
    verifyNoMoreInteractions(coordinator);
  });

  test('best-effort : un cycle dégradé n\'est pas un chemin d\'échec', () async {
    when(() => coordinator.pullSubset(any())).thenAnswer(
      (_) async => const PullRunReport(
        updated: 1,
        failed: 2,
        outcomes: {
          kClassroomsResource: PullResult.updated,
          kClassroomMembersResource: PullResult.error,
          kClassroomTransfersResource: PullResult.error,
        },
      ),
    );

    // Ne lève pas : les deux scopes appellent en `unawaited`, l'UI lit le local.
    final rapport = await useCase();

    expect(rapport.isDegraded, isTrue);
  });
}
