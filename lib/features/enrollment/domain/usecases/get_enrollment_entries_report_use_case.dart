import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

/// Le registre PDF des inscrits de la fenêtre — **les mêmes lignes que la
/// table, dans un autre ordre**.
///
/// Même fenêtre et mêmes lignes : le serveur les dérive par le même code, donc
/// la feuille et l'écran ne peuvent pas porter des effectifs différents. Mais
/// le document se range par nom ([EnrollmentEntriesOrder.document]) là où la
/// table suit l'ordre du guichet, parce qu'on ne lit pas un registre imprimé
/// comme on regarde un écran : on y cherche un élève. Il en tire son index par
/// initiale, que le serveur ne pose que sur une liste rangée.
///
/// L'autre différence est voulue de la même façon : le document ne se pagine
/// pas — on ne remet pas « la page 3 sur 12 » — et c'est son volume total que
/// le serveur plafonne.
///
/// Il porte la **double permission** de la liste (`enrollment.stats.read` et
/// `enrollment.read`) : ce sont des noms d'élèves, et une fois imprimés ils
/// circulent sans que personne ne revérifie qui les lit.
class GetEnrollmentEntriesReportUseCase {
  final EnrollmentStatsRepository _repository;

  const GetEnrollmentEntriesReportUseCase(this._repository);

  Future<Either<Failure, EnrollmentEntriesReport>> call({
    required EnrollmentStatsWindow window,
  }) => _repository.getEntriesReport(
    window: window,
    order: EnrollmentEntriesOrder.document,
  );
}
