import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';

/// Le répertoire local des payeurs de la caisse.
abstract class BoutiquePayerRepository {
  /// Les payeurs dont le numéro se rapproche de [phoneNumber].
  Future<Either<Failure, List<BoutiquePayer>>> findByPhone(String phoneNumber);
}
