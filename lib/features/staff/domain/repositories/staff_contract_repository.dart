import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';

/// Les contrats **avec** leurs montants — lus et écrits sous `hr.pay.*`.
///
/// Séparé de la fiche : un compte peut tenir le fichier sans jamais voir un
/// salaire, et ces gestes-ci ont leur propre file d'envoi.
abstract class StaffContractRepository {
  /// Les périodes d'un agent connues du poste, corrigées comprises, par date
  /// d'effet. Vide sans `hr.pay.read` : la tablette n'en a reçu aucune.
  Future<Either<Failure, List<StaffContract>>> contractsOf(
    String staffMemberId,
  );

  /// Pose une période (« Nouveau contrat à compter du… »). Le brouillon doit
  /// avoir été validé : le dépôt convertit, il ne juge pas.
  Future<Either<Failure, Unit>> addContract(
    String staffMemberId,
    StaffContractDraft draft,
  );

  /// Corrige [original] : il sort du calcul, [replacement] le remplace — ou
  /// rien, si la période était un doublon.
  Future<Either<Failure, Unit>> correctContract(
    StaffContract original, {
    required String reason,
    StaffContractDraft? replacement,
  });
}
