import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';

/// Encaissement d'une vente boutique.
abstract class BoutiqueSaleRepository {
  /// Écrit la vente en local et met son push en file. **Rend immédiatement** :
  /// le réseau n'est jamais sur le chemin du guichet.
  Future<Either<Failure, RecordedSale>> recordSale({
    required BoutiqueCart cart,
    required String academicYearId,
    String? cashierName,
  });
}
