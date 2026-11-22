import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/data/control/fee_control_export_api.dart';
import 'package:school_app_flutter/features/recouvrement/data/control/fee_control_export_repository_impl.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/fee_control_export_repository.dart';

class _MockApi extends Mock implements FeeControlExportApi {}

class _MockCount extends Mock implements CountPendingPaymentsUseCase {}

LocalRecoveryLine _line(String id, {int expected = 24000, int paid = 0}) =>
    LocalRecoveryLine(
      schoolLevelId: 'lvl-1',
      studentId: id,
      charges: [
        RecoveryChargePosition(
          feeCode: 'TUITION',
          position: FeeChargePosition(
            currency: 'USD',
            expectedInCents: expected,
            paidMirrorInCents: paid,
            paidPendingInCents: 0,
          ),
        ),
      ],
    );

void main() {
  late _MockApi api;
  late _MockCount count;
  late FeeControlExportRepositoryImpl repo;
  final now = DateTime.utc(2026, 9, 5, 8, 30);

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(RecoveryExportFormat.pdf);
  });
  setUp(() {
    api = _MockApi();
    count = _MockCount();
    when(() => count()).thenAnswer((_) async => const Right(2));
    when(() => api.export(any(), any())).thenAnswer(
      (_) async => RecoveryExportFile(
        format: RecoveryExportFormat.pdf,
        bytes: Uint8List.fromList([1]),
        fileName: 'controle-X.pdf',
      ),
    );
    repo = FeeControlExportRepositoryImpl(
      api: api,
      countPending: count,
      now: () => now,
    );
  });

  test('format v2 : filtre, seuil et devise, lignes en trois sacs, sans '
      'critère', () async {
    await repo.export(
      classroomId: 'c-1',
      feeCodes: const ['TUITION'],
      filter: FeeControlExportFilter.paidAtLeast,
      threshold: const Money(10000, 'USD'),
      lines: [_line('s-1', paid: 12000)],
      format: RecoveryExportFormat.xlsx,
    );
    final body =
        verify(
              () => api.export(captureAny(), RecoveryExportFormat.xlsx),
            ).captured.single
            as Map<String, dynamic>;
    expect(body['scope'], {'kind': 'CLASSROOM', 'id': 'c-1'});
    expect(body['filter'], 'PAID_AT_LEAST');
    expect(body.containsKey('criterion'), isFalse);
    expect(body['thresholdInCents'], 10000);
    expect(body['thresholdCurrency'], 'USD');
    expect(body['pendingWrites'], 2);
    expect(body['arretedAt'], now.toIso8601String());
    final line = (body['lines'] as List).single as Map;
    expect(line['studentId'], 's-1');
    expect(line['due'], [
      {'currency': 'USD', 'amountInCents': 24000},
    ]);
    expect(line['outstanding'], [
      {'currency': 'USD', 'amountInCents': 12000},
    ]);
  });

  test(
    '« Non affectés » part sans identifiant ; pas de seuil hors segment',
    () async {
      await repo.export(
        classroomId: 'UNASSIGNED',
        feeCodes: const ['TUITION'],
        filter: FeeControlExportFilter.noPayment,
        threshold: const Money(10000, 'USD'),
        lines: [_line('s-1')],
        format: RecoveryExportFormat.pdf,
      );
      final body =
          verify(() => api.export(captureAny(), any())).captured.single
              as Map<String, dynamic>;
      expect(body['scope'], {'kind': 'UNASSIGNED'});
      expect(body.containsKey('thresholdInCents'), isFalse);
    },
  );

  test('au-delà de 5 000 lignes, refusé avant le voyage', () async {
    final result = await repo.export(
      classroomId: 'c-1',
      feeCodes: const ['TUITION'],
      filter: FeeControlExportFilter.all,
      lines: [for (var i = 0; i < 5001; i++) _line('s-$i')],
      format: RecoveryExportFormat.pdf,
    );
    expect(
      result.fold((f) => (f as ApiValidationFailure).detailCode, (_) => null),
      'REPORT_LINE_CAP',
    );
    verifyNever(() => api.export(any(), any()));
  });
}
