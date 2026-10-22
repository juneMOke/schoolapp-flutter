import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/depot_copie_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/depot/depot_copie_use_cases.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';

class _Roster extends Mock implements GetNotesElevesUseCase {}

class _Depots extends Mock implements DepotCopieRepository {}

void main() {
  late _Roster roster;
  late _Depots depots;
  late LoadCopiesRenduesUseCase load;

  setUp(() {
    roster = _Roster();
    depots = _Depots();
    load = LoadCopiesRenduesUseCase(roster, depots);
  });

  test('chaque élève de la classe, trié, avec son état de remise', () async {
    when(() => roster('e1')).thenAnswer(
      (_) async => const Right([
        NoteEleve(studentId: 's2', firstName: 'Zoé', lastName: 'Mbala'),
        NoteEleve(studentId: 's1', firstName: 'Ali', lastName: 'Kanda'),
        NoteEleve(studentId: 's3', firstName: 'Ben', lastName: 'Ngoy'),
      ]),
    );
    when(() => depots.depots('e1')).thenAnswer(
      (_) async => const Right([
        DepotCopie(id: 'd1', studentId: 's1'),
        DepotCopie(id: 'd2', studentId: 's3', enRetard: true),
        // Un élève sorti de la classe : sa copie n'a pas de ligne.
        DepotCopie(id: 'd9', studentId: 'parti'),
      ]),
    );

    final copies = (await load('e1')).getOrElse(() => CopiesRendues.empty);

    expect(copies.eleves.map((e) => e.studentId), ['s1', 's2', 's3']);
    expect(copies.eleves.map((e) => e.etat), [
      EtatRendu.rendu,
      EtatRendu.pasRendu,
      EtatRendu.renduEnRetard,
    ]);
    expect(copies.rendues, 2);
    expect(copies.total, 3);
  });

  test('un roster illisible remonte son échec', () async {
    when(
      () => roster('e1'),
    ).thenAnswer((_) async => const Left(StorageFailure('x')));

    expect((await load('e1')).isLeft(), isTrue);
    verifyNever(() => depots.depots(any()));
  });
}
