import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_report.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_report_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_sales_report_button.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

import '../dashboard_fixtures.dart';

class _MockReport extends Mock implements GetBoutiqueSalesReportUseCase {}

void main() {
  final l10n = AppLocalizationsFr();
  final query = SalesQuery(academicYearId: 'ay-1', window: thisWeek);

  setUpAll(() => registerFallbackValue(query));

  group('message', () {
    test('429 : attendre, le délai annoncé', () {
      expect(
        BoutiqueSalesReportButton.message(
          const TooManyRequestsFailure(),
          const BoutiqueSalesReportState(retryAfter: Duration(seconds: 30)),
          l10n,
        ),
        l10n.boutiqueSalesReportBusy(30),
      );
    });

    test('403 : pas d\'accès, jamais « réessayez »', () {
      expect(
        BoutiqueSalesReportButton.message(
          const UnauthorizedFailure(),
          const BoutiqueSalesReportState(),
          l10n,
        ),
        l10n.boutiqueSalesReportForbidden,
      );
    });

    test('sans phrase du serveur : la nôtre', () {
      expect(
        BoutiqueSalesReportButton.message(
          const ServerFailure(''),
          const BoutiqueSalesReportState(),
          l10n,
        ),
        l10n.boutiqueSalesReportFailed,
      );
    });
  });

  group('cubit', () {
    test('un second appui pendant le rendu ne lance rien', () async {
      final getReport = _MockReport();
      final done = Completer<Either<Failure, BoutiqueSalesReport>>();
      when(() => getReport(any())).thenAnswer((_) => done.future);
      final cubit = BoutiqueSalesReportCubit(getReport: getReport);
      addTearDown(cubit.close);

      final first = cubit.download(query);
      await cubit.download(query);
      verify(() => getReport(any())).called(1);

      done.complete(
        Right(BoutiqueSalesReport(bytes: Uint8List(4), fileName: 'v.pdf')),
      );
      await first;
      expect(cubit.state.report, isNotNull);
      cubit.acknowledge();
      expect(cubit.state.hasDelivery, isFalse);
    });

    test('429 : le bouton reste désarmé le temps annoncé', () async {
      final getReport = _MockReport();
      when(() => getReport(any())).thenAnswer(
        (_) async => const Left(
          TooManyRequestsFailure(retryAfter: Duration(milliseconds: 20)),
        ),
      );
      final cubit = BoutiqueSalesReportCubit(getReport: getReport);
      addTearDown(cubit.close);

      await cubit.download(query);
      expect(cubit.state.status, BoutiqueSalesReportStatus.cooldown);
      cubit.acknowledge();
      expect(cubit.state.isBusy, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(cubit.state.status, BoutiqueSalesReportStatus.idle);
    });
  });
}
