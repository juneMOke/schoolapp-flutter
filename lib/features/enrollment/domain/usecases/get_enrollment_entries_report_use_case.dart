import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

/// Le registre PDF des inscrits de la fenêtre — **la sortie exacte de la
/// table** qu'il accompagne.
///
/// Même fenêtre, même ordre ([EnrollmentEntriesOrder.dashboard]), mêmes
/// lignes : le serveur dérive les deux par le même code, donc la feuille et
/// l'écran ne peuvent pas se contredire. La seule différence est voulue : le
/// document ne se pagine pas — on ne remet pas « la page 3 sur 12 » — et
/// c'est son volume total que le serveur plafonne.
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
    order: EnrollmentEntriesOrder.dashboard,
  );
}
