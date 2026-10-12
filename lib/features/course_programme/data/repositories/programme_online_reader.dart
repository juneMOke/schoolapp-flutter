import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_read_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';

/// Le programme lu en ligne, pour qui n'a pas le cours sur la tablette (la
/// direction). Lecture seule : aucun geste ne part d'ici. Les évaluations
/// liées ne descendent pas avec le programme : elles ne sont pas comptées.
class ProgrammeOnlineReader {
  final ProgrammeReadApi _api;
  final Map<String, dynamic> _extras;

  const ProgrammeOnlineReader({
    required ProgrammeReadApi api,
    required Map<String, dynamic> extras,
  }) : _api = api,
       _extras = extras;

  Future<Either<Failure, Programme>> readProgramme(String coursId) =>
      guardOnline(() async {
        final dtos = await _api.chapitresOfCours(_extras, coursId);
        dtos.sort((a, b) => a.ordre.compareTo(b.ordre));
        return Programme(
          coursId: coursId,
          readOnly: true,
          chapitres: [
            for (final dto in dtos)
              ProgrammeChapitre(
                chapitre: dto.toEntity(readOnly: true),
                notesCount: dto.notes.length,
              ),
          ],
        );
      });

  Future<Either<Failure, ChapitreDetail>> readChapitre(String chapitreId) =>
      guardOnline(() async {
        final dto = await _api.chapitre(_extras, chapitreId);
        return ChapitreDetail(
          chapitre: dto.toEntity(readOnly: true),
          numero: dto.ordre + 1,
        );
      });
}
