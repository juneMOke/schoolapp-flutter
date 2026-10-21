import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_dashboard_repository.dart';

class GetBoutiqueBeneficiariesUseCase {
  final BoutiqueDashboardRepository _repository;

  const GetBoutiqueBeneficiariesUseCase(this._repository);

  Future<Either<Failure, BoutiqueBeneficiariesPage>> call(
    BeneficiariesQuery query,
  ) => _repository.beneficiaries(query);
}
