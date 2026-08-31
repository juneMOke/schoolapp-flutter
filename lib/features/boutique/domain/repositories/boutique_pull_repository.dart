import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_pull_outcome.dart';

/// Pull des ventes de l'année — **dont celles de l'autre guichet**.
abstract class BoutiquePullRepository {
  Future<Either<Failure, BoutiquePullOutcome>> syncSales();
}
