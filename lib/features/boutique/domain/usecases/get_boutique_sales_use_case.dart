import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_report.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sales_repository.dart';

class GetBoutiqueSalesUseCase {
  final BoutiqueSalesRepository _repository;

  const GetBoutiqueSalesUseCase(this._repository);

  Future<Either<Failure, BoutiqueSalesPage>> call(SalesQuery query) =>
      _repository.sales(query);
}

class GetBoutiqueSalesReportUseCase {
  final BoutiqueSalesRepository _repository;

  const GetBoutiqueSalesReportUseCase(this._repository);

  Future<Either<Failure, BoutiqueSalesReport>> call(SalesQuery query) =>
      _repository.report(query.firstPage);
}
