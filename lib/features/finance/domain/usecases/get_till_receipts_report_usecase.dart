import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_report.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

/// Le rapport PDF des paiements de la fenêtre — **toutes caisses**.
///
/// La sortie exacte de la table qu'il accompagne : même fenêtre, mêmes lignes,
/// et aucune devise pour le cadrer. Le pied du document rend un total par
/// devise plutôt qu'une somme, ce qui est la seule façon d'imprimer deux
/// unités sans inviter à les additionner.
///
/// Il porte la **seconde permission** (`finance.payment.read`) comme la table
/// dont il est la sortie.
class GetTillReceiptsReportUseCase {
  final FinanceRepository _repository;

  const GetTillReceiptsReportUseCase(this._repository);

  Future<Either<Failure, TillReport>> call({
    TillWindow window = const TillWindow.day(),
  }) => _repository.getTillReceiptsReport(window: window);
}
