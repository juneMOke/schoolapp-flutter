import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_reports_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';

class TreasuryReportsRepositoryImpl implements TreasuryReportsRepository {
  final TreasuryReportsApi _api;

  const TreasuryReportsRepositoryImpl(this._api);

  @override
  Future<Either<Failure, CashReportPage>> list(CashReportKind kind, int page) =>
      guardTreasury(() => _api.list(kind, page));

  @override
  Future<Either<Failure, CashReport>> period(DateTime from, DateTime to) =>
      guardTreasury(() => _api.period(from, to));

  @override
  Future<Either<Failure, CashReportFile>> file(
    String id,
    CashReportFormat format,
  ) => guardTreasury(() => _api.file(id, format));
}
