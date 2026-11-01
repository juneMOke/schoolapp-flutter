import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';

/// Les rubriques de retenue de l'école et leurs saisies.
abstract class PayrollDeductionRepository {
  /// Enregistre des rubriques, chacune avec son horloge et son entrée.
  Future<Either<Failure, Unit>> saveTypes(List<PayrollDeductionType> types);

  /// Crée l'identifiant d'une rubrique neuve, sur la tablette.
  String newTypeId();

  /// Supprime une rubrique : en local si le serveur ne l'a jamais eue, sinon
  /// en ligne seulement.
  Future<Either<Failure, Unit>> removeType(String id);

  /// Enregistre les éléments variables d'un agent ([variables], s'ils ont
  /// changé) et ses saisies modifiées, dans une même transaction.
  Future<Either<Failure, Unit>> saveEntries(
    String month, {
    PayrollVariables? variables,
    List<PayrollDeductionEntry> entries,
  });

  /// Efface une saisie refusée que l'économe a lue.
  Future<Either<Failure, Unit>> dismissEntry(
    String month,
    PayrollDeductionEntry entry,
  );
}
