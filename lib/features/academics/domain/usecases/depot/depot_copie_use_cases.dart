import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/person_name_comparator.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/depot_copie_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';

// Les cas d'usage des copies déposées par les parents (portail parent, V180).

/// La classe du devoir et la copie de chacun : le roster de la saisie des
/// notes, croisé avec les dépôts. Une copie d'un élève sorti de la classe
/// n'est pas montrée : elle n'a plus de ligne où se ranger.
class LoadCopiesRenduesUseCase {
  final GetNotesElevesUseCase _roster;
  final DepotCopieRepository _depots;

  const LoadCopiesRenduesUseCase(this._roster, this._depots);

  Future<Either<Failure, CopiesRendues>> call(String evaluationId) async {
    final roster = await _roster(evaluationId);
    return roster.fold(Left.new, (eleves) async {
      final depots = await _depots.depots(evaluationId);
      return depots.fold(Left.new, (list) {
        final byStudent = {for (final d in list) d.studentId: d};
        final rows = [
          for (final eleve in eleves)
            CopieRendue(
              studentId: eleve.studentId,
              firstName: eleve.firstName,
              lastName: eleve.lastName,
              middleName: eleve.middleName,
              depot: byStudent[eleve.studentId],
            ),
        ]..sort(_byName);
        return Right(CopiesRendues(rows));
      });
    });
  }
}

final Comparator<CopieRendue> _byName = PersonNameComparator.by<CopieRendue>(
  lastName: (e) => e.lastName,
  surname: (e) => e.middleName,
  firstName: (e) => e.firstName,
  id: (e) => e.studentId,
);

class OpenDepotFichierUseCase {
  final DepotCopieRepository _depots;

  const OpenDepotFichierUseCase(this._depots);

  Future<Either<Failure, Uint8List>> call(
    String evaluationId,
    DepotFichier fichier,
  ) => _depots.fichier(evaluationId, fichier);
}
