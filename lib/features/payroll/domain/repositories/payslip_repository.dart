import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';

/// Les bulletins scellés (BP) — en ligne seulement, comme toute l'éditique.
abstract class PayslipRepository {
  /// Le bulletin d'un agent ; scellé par le serveur au premier appel.
  Future<Either<Failure, Uint8List>> payslip(
    String month,
    String staffMemberId,
  );

  /// Les bulletins scellés de [month] en un PDF (T16).
  Future<Either<Failure, Uint8List>> monthPayslips(String month);

  /// L'état de paie de [month], A4 paysage (T16).
  Future<Either<Failure, Uint8List>> statement(String month);
}
