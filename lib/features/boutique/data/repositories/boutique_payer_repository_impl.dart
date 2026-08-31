import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_payer_directory_dao.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_payer_repository.dart';

class BoutiquePayerRepositoryImpl implements BoutiquePayerRepository {
  final BoutiquePayerDirectoryDao _dao;
  final CurrentUserContext _currentUser;

  const BoutiquePayerRepositoryImpl({
    required BoutiquePayerDirectoryDao dao,
    required CurrentUserContext currentUser,
  }) : _dao = dao,
       _currentUser = currentUser;

  @override
  Future<Either<Failure, List<BoutiquePayer>>> findByPhone(
    String phoneNumber,
  ) async {
    try {
      return Right(
        await _dao.findByPhone(
          schoolId: _currentUser.schoolId ?? '',
          phoneNumber: phoneNumber,
        ),
      );
    } catch (e) {
      // Une suggestion de confort ne fait pas échouer une vente : l'appelant
      // replie sur « aucune proposition », et le guichet saisit l'identité.
      return Left(StorageFailure('Répertoire des payeurs illisible : $e'));
    }
  }
}
