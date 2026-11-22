import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// Le segment du contrôle des frais, tel que le serveur le vérifie
/// (`filter=…`).
enum FeeControlExportFilter {
  all('ALL'),
  noPayment('NO_PAYMENT'),
  partial('PARTIAL'),
  settled('SETTLED'),
  paidAtLeast('PAID_AT_LEAST');

  final String wire;

  const FeeControlExportFilter(this.wire);
}

/// L'export du résultat entier du contrôle des frais (R11), en ligne.
abstract class FeeControlExportRepository {
  /// [classroomId] : une classe ou `UNASSIGNED`. [lines] : **toutes** les
  /// lignes du résultat, déjà filtrées par l'écran. [threshold] : exigé avec
  /// [FeeControlExportFilter.paidAtLeast].
  Future<Either<Failure, RecoveryExportFile>> export({
    required String classroomId,
    required List<String> feeCodes,
    required FeeControlExportFilter filter,
    Money? threshold,
    required List<LocalRecoveryLine> lines,
    required RecoveryExportFormat format,
  });
}
