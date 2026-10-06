import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/chapitre_children_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

/// Enregistre une édition de chapitre : la fiche d'abord (une ressource
/// attend son chapitre), puis les ressources jointes et retirées.
///
/// La fiche gardée, l'édition est acquise même si une ressource ne l'a pas
/// été : [ChapitreEditOutcome.ressourcesKept] le dit, sans défaire la fiche.
///
/// La modale ne touche pas au contenu rédigé : il est relu au moment
/// d'écrire, sinon un enregistrement du contenu fait pendant que la modale
/// était ouverte serait écrasé par les blocs lus à son ouverture.
class SaveChapitreEditUseCase {
  final ProgrammeRepository _programme;
  final ChapitreChildrenRepository _children;

  const SaveChapitreEditUseCase(this._programme, this._children);

  Future<Chapitre?> _contentNow(ChapitreEdit edit) async {
    if (edit.isNew) return edit.chapitre;
    final detail = await _programme.loadChapitre(edit.chapitre.id);
    return detail.fold(
      (_) => null,
      (d) => edit.chapitre.copyWith(blocs: d.chapitre.blocs),
    );
  }

  Future<Either<Failure, ChapitreEditOutcome>> call(ChapitreEdit edit) async {
    final current = await _contentNow(edit);
    if (current == null) {
      return const Left(NotFoundFailure('Chapitre introuvable'));
    }
    final saved = await _programme.saveChapitre(current, create: edit.isNew);
    return saved.fold(Left.new, (chapitre) async {
      var kept = true;
      for (final id in edit.removedRessourceIds) {
        kept = (await _children.deleteRessource(id)).isRight() && kept;
      }
      for (final draft in edit.addedRessources) {
        kept =
            (await _children.addRessource(chapitre, draft)).isRight() && kept;
      }
      return Right(
        ChapitreEditOutcome(chapitre: chapitre, ressourcesKept: kept),
      );
    });
  }
}

/// Les sous-périodes où rattacher un chapitre du cours, dans l'ordre : celles
/// que le détail du cours résout déjà (année et cycle de sa classe).
class LoadSousPeriodesUseCase {
  final CourseRepository _courses;

  const LoadSousPeriodesUseCase(this._courses);

  Future<List<SousPeriodeOption>> call(String coursId) async {
    final detail = await _courses.getCoursNotationDetail(coursId);
    return detail.fold((_) => const [], (detail) {
      final periodes = [...detail.periodes]
        ..sort((a, b) => a.ordre.compareTo(b.ordre));
      return [
        for (final periode in periodes)
          for (final sp in [
            ...periode.sousPeriodes,
          ]..sort((a, b) => a.ordre.compareTo(b.ordre)))
            SousPeriodeOption(id: sp.sousPeriodeId, ordre: sp.ordre),
      ];
    });
  }
}
