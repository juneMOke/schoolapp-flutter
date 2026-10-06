import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/chapitre_children_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/chapitre_edit_use_cases.dart';

class _MockProgramme extends Mock implements ProgrammeRepository {}

class _MockChildren extends Mock implements ChapitreChildrenRepository {}

void main() {
  const chapitre = Chapitre(
    id: 'ch-1',
    coursId: 'c-1',
    ordre: 0,
    titre: 'Fractions',
  );
  const draft = RessourceDraft(
    id: 'r-1',
    type: RessourceType.manuel,
    nom: 'Manuel',
    reference: 'p. 4',
  );
  late _MockProgramme programme;
  late _MockChildren children;

  setUpAll(() {
    registerFallbackValue(chapitre);
    registerFallbackValue(draft);
  });

  setUp(() {
    programme = _MockProgramme();
    children = _MockChildren();
    // Une modification relit le contenu courant avant d'écrire.
    when(() => programme.loadChapitre(chapitre.id)).thenAnswer(
      (_) async => const Right(ChapitreDetail(chapitre: chapitre, numero: 1)),
    );
  });

  test('la fiche d\'abord, puis les ressources', () async {
    when(
      () => programme.saveChapitre(any(), create: any(named: 'create')),
    ).thenAnswer((_) async => const Right(chapitre));
    when(
      () => children.deleteRessource('r-0'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => children.addRessource(chapitre, draft),
    ).thenAnswer((_) async => const Right(unit));

    final result = await SaveChapitreEditUseCase(programme, children)(
      const ChapitreEdit(
        chapitre: chapitre,
        isNew: false,
        addedRessources: [draft],
        removedRessourceIds: ['r-0'],
      ),
    );

    expect(result.fold((_) => null, (o) => o.ressourcesKept), isTrue);
    verifyInOrder([
      () => programme.saveChapitre(chapitre, create: false),
      () => children.deleteRessource('r-0'),
      () => children.addRessource(chapitre, draft),
    ]);
  });

  test('une ressource non gardée ne défait pas la fiche', () async {
    when(
      () => programme.saveChapitre(any(), create: any(named: 'create')),
    ).thenAnswer((_) async => const Right(chapitre));
    when(
      () => children.addRessource(any(), any()),
    ).thenAnswer((_) async => const Left(StorageFailure()));

    final result = await SaveChapitreEditUseCase(programme, children)(
      const ChapitreEdit(
        chapitre: chapitre,
        isNew: true,
        addedRessources: [draft],
      ),
    );

    expect(result.fold((_) => null, (o) => o.ressourcesKept), isFalse);
  });

  test('le contenu rédigé pendant la modale n\'est pas écrasé', () async {
    const rewritten = ChapitreBloc(
      id: 'b-9',
      type: ChapitreBlocType.paragraphe,
      texte: 'Écrit pendant la modale',
    );
    when(() => programme.loadChapitre(chapitre.id)).thenAnswer(
      (_) async => Right(
        ChapitreDetail(
          chapitre: chapitre.copyWith(blocs: const [rewritten]),
          numero: 1,
        ),
      ),
    );
    when(
      () => programme.saveChapitre(any(), create: any(named: 'create')),
    ).thenAnswer((_) async => const Right(chapitre));

    await SaveChapitreEditUseCase(programme, children)(
      const ChapitreEdit(chapitre: chapitre, isNew: false),
    );

    final saved =
        verify(
              () => programme.saveChapitre(
                captureAny(),
                create: any(named: 'create'),
              ),
            ).captured.single
            as Chapitre;
    expect(saved.blocs, const [rewritten]);
  });

  test('une fiche refusée n\'envoie aucune ressource', () async {
    when(
      () => programme.saveChapitre(any(), create: any(named: 'create')),
    ).thenAnswer((_) async => const Left(StorageFailure()));

    final result = await SaveChapitreEditUseCase(programme, children)(
      const ChapitreEdit(
        chapitre: chapitre,
        isNew: true,
        addedRessources: [draft],
      ),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => children.addRessource(any(), any()));
  });
}
