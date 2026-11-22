import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/data/control/fee_control_export_api.dart';
import 'package:school_app_flutter/features/recouvrement/data/models/relance_list_request_model.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/fee_control_export_repository.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';

class FeeControlExportRepositoryImpl implements FeeControlExportRepository {
  final FeeControlExportApi _api;
  final CountPendingPaymentsUseCase _countPending;
  final DateTime Function() _now;

  const FeeControlExportRepositoryImpl({
    required FeeControlExportApi api,
    required CountPendingPaymentsUseCase countPending,
    DateTime Function() now = DateTime.now,
  }) : _api = api,
       _countPending = countPending,
       _now = now;

  @override
  Future<Either<Failure, RecoveryExportFile>> export({
    required String classroomId,
    required List<String> feeCodes,
    required FeeControlExportFilter filter,
    Money? threshold,
    required List<LocalRecoveryLine> lines,
    required RecoveryExportFormat format,
  }) async {
    // Le plafond se vérifie ici, avant le voyage : même code et mêmes
    // chiffres que le refus du serveur.
    if (lines.length > AppConstants.recouvrementRelanceListLineCap) {
      return Left(
        ApiValidationFailure(
          code: ApiErrorCode.businessRule,
          detailCode: 'REPORT_LINE_CAP',
          details: {
            'lines': lines.length,
            'cap': AppConstants.recouvrementRelanceListLineCap,
          },
        ),
      );
    }
    final pending = (await _countPending()).fold((_) => 0, (n) => n);
    final body = <String, dynamic>{
      'scope': classroomId == recoveryUnassigned
          ? {'kind': 'UNASSIGNED'}
          : {'kind': 'CLASSROOM', 'id': classroomId},
      'feeCodes': feeCodes,
      'filter': filter.wire,
      if (filter == FeeControlExportFilter.paidAtLeast &&
          threshold != null) ...{
        'thresholdInCents': threshold.amountInCents,
        'thresholdCurrency': threshold.currency,
      },
      'arretedAt': _now().toUtc().toIso8601String(),
      if (pending > 0) 'pendingWrites': pending,
      'lines': [
        for (final line in lines) RelanceLineModel.fromLine(line).toJson(),
      ],
    };
    return guardOnline(() => _api.export(body, format));
  }
}
