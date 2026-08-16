import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_disciplinary_pull_usecase.dart';

class _MockPullCoordinator extends Mock implements PullCoordinator {}

/// Depuis ADR-015 F6, ce use case ne possède plus qu'une chose : **l'ensemble
/// des ressources dont la fiche élève a besoin**. Le gate de connectivité qu'il
/// portait vit dans le socle, avec la sonde de crédentiels, le filtre de
/// permission et l'isolation des échecs — prouvés là-bas, une seule fois, pour
/// les deux points d'entrée du coordinateur.
///
/// La garde de permission de la PAGE (`Perm.disciplineRead`), elle, reste et
/// garde autre chose : l'affichage du volet. Elle est prouvée par
/// `disciplinary_student_detail_gating_test.dart`, qui vérifie aussi qu'un
/// profil sans le droit ne déclenche pas ce use case du tout.
void main() {
  late _MockPullCoordinator coordinator;
  late SyncDisciplinaryPullUseCase useCase;

  setUpAll(() => registerFallbackValue(<String>{}));

  setUp(() {
    coordinator = _MockPullCoordinator();
    when(
      () => coordinator.pullSubset(any()),
    ).thenAnswer((_) async => const PullRunReport(updated: 1));
    useCase = SyncDisciplinaryPullUseCase(coordinator);
  });

  Set<String> demande() =>
      verify(() => coordinator.pullSubset(captureAny())).captured.single
          as Set<String>;

  test('demande la ressource Discipline, et elle seule', () async {
    await useCase();

    expect(demande(), {kDisciplinaryResource});
  });

  test('délègue sans condition : aucune garde n\'est rejouée ici', () async {
    await useCase();

    verify(() => coordinator.pullSubset(any())).called(1);
    verifyNoMoreInteractions(coordinator);
  });

  test('rend le bilan du cycle tel quel, sans le réinterpréter', () async {
    const bilan = PullRunReport(
      notModified: 1,
      outcomes: {kDisciplinaryResource: PullResult.notModified},
    );
    when(() => coordinator.pullSubset(any())).thenAnswer((_) async => bilan);

    final rapport = await useCase();

    expect(identical(rapport, bilan), isTrue);
    expect(rapport.succeeded(kDisciplinaryResource), isTrue);
  });
}
