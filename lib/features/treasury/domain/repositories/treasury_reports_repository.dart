import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';

/// Les rapports de caisse (A5, A6), en ligne seulement.
abstract class TreasuryReportsRepository {
  Future<Either<Failure, CashReportPage>> list(CashReportKind kind, int page);

  /// Le rapport `PERIOD` d'une plage : rien n'est créé côté serveur.
  Future<Either<Failure, CashReport>> period(DateTime from, DateTime to);

  Future<Either<Failure, CashReportFile>> file(
    String id,
    CashReportFormat format,
  );
}
