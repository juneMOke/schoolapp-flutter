import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/data/datasources/relance_list_remote_data_source.dart';
import 'package:school_app_flutter/features/recouvrement/data/repositories/relance_list_repository_impl.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

class _MockDataSource extends Mock implements RelanceListRemoteDataSource {}

class _FakeOptions extends Fake implements Options {}

LocalRecoveryLine line(String studentId) => LocalRecoveryLine(
  schoolLevelId: 'lvl-1',
  studentId: studentId,
  charges: const [
    RecoveryChargePosition(
      feeCode: 'TUITION',
      position: FeeChargePosition(
        currency: 'USD',
        expectedInCents: 30000,
        paidMirrorInCents: 0,
        paidPendingInCents: 0,
      ),
    ),
  ],
);

/// Une réponse binaire plausible : en-têtes PDF et signature `%PDF`.
HttpResponse<Uint8List> pdfResponse({
  String contentType = 'application/pdf',
  String? disposition = 'attachment; filename="relance-6eme-A.pdf"',
  Uint8List? bytes,
}) {
  final response = Response<Uint8List>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: 200,
    headers: Headers.fromMap({
      'content-type': [contentType],
      if (disposition != null) 'content-disposition': [disposition],
    }),
  );
  return HttpResponse<Uint8List>(
    bytes ?? Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
    response,
  );
}

void main() {
  late _MockDataSource dataSource;
  late RelanceListRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeOptions()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = RelanceListRepositoryImpl(
      remoteDataSource: dataSource,
      requiredAuth: const <String, dynamic>{},
    );
  });

  Future<Object> emit({List<LocalRecoveryLine>? lines}) async =>
      (await repository.emit(
        scope: RelanceScope.schoolLevel('lvl-1'),
        feeCodes: const ['TUITION'],
        criterion: RecouvrementCriterion.noPayment,
        lines: lines ?? [line('s1')],
        arretedAt: DateTime.utc(2026, 9, 10),
      )).fold((l) => l, (r) => r);

  void stub(HttpResponse<Uint8List> response) {
    when(
      () => dataSource.emitRelanceList(any(), any(), any()),
    ).thenAnswer((_) async => response);
  }

  group('le plafond', () {
    test('refuse LOCALEMENT au-delà, sans faire le voyage', () async {
      final result = await emit(
        lines: [
          for (var i = 0; i <= AppConstants.recouvrementRelanceListLineCap; i++)
            line('s$i'),
        ],
      );

      expect(result, isA<Failure>());
      final cap = ReportLineCap.of(result as Failure);
      expect(cap, isNotNull);
      expect(cap!.cap, AppConstants.recouvrementRelanceListLineCap);
      expect(cap.lines, AppConstants.recouvrementRelanceListLineCap + 1);
      verifyNever(() => dataSource.emitRelanceList(any(), any(), any()));
    });

    test('le refus local porte le MÊME code que celui du serveur', () async {
      final result =
          await emit(
                lines: [
                  for (
                    var i = 0;
                    i <= AppConstants.recouvrementRelanceListLineCap;
                    i++
                  )
                    line('s$i'),
                ],
              )
              as Failure;

      expect(
        (result as ApiErrorDetails).detailCode,
        ReportLineCap.detailCode,
        reason:
            'l\'écran n\'a qu\'un décodeur : il ne doit pas savoir lequel '
            'des deux a refusé',
      );
    });

    test('laisse passer PILE au plafond', () async {
      stub(pdfResponse());

      await emit(
        lines: [
          for (var i = 0; i < AppConstants.recouvrementRelanceListLineCap; i++)
            line('s$i'),
        ],
      );

      verify(() => dataSource.emitRelanceList(any(), any(), any())).called(1);
    });
  });

  group('le corps envoyé', () {
    test('part gzippé, et le dit dans ses en-têtes', () async {
      stub(pdfResponse());
      await emit();

      final options =
          verify(
                () => dataSource.emitRelanceList(any(), any(), captureAny()),
              ).captured.single
              as Options;

      expect(options.headers?['content-encoding'], 'gzip');
      expect(options.requestEncoder, isNotNull);

      // L'encodeur produit bien du gzip : les deux octets magiques 0x1f 0x8b.
      // `requestEncoder` est déclaré `FutureOr` : on l'attend, comme Dio.
      final encoded = await options.requestEncoder!(
        '{"a":1}',
        RequestOptions(path: '/'),
      );
      expect(encoded.take(2), [0x1f, 0x8b]);
      expect(utf8.decode(gzip.decode(encoded)), '{"a":1}');
    });

    test('les DEUX délais sont posés pour ce seul appel', () async {
      stub(pdfResponse());
      await emit();

      final options =
          verify(
                () => dataSource.emitRelanceList(any(), any(), captureAny()),
              ).captured.single
              as Options;

      expect(
        options.receiveTimeout,
        AppConstants.recouvrementRelanceListTimeout,
        reason:
            'les 12 s du client sont calibrées sur du JSON de guichet, et '
            'le serveur reste muet 1 à 7 s pendant qu\'il rend',
      );
      expect(
        options.sendTimeout,
        AppConstants.recouvrementRelanceListSendTimeout,
        reason:
            'la montée est un budget TOTAL : 41 s au plafond sur une '
            'liaison à 50 kbit/s, et 30 s couperait un envoi sain',
      );
    });

    test('le budget de MONTÉE dépasse celui de la réception — ils ne mesurent '
        'pas la même chose', () {
      // `receiveTimeout` borne le rendu serveur (7,1 s au pire mesuré) puis
      // l'intervalle entre chunks ; `sendTimeout` borne le transfert entier.
      // Les confondre ferait couper une montée saine sur un lien étroit.
      expect(
        AppConstants.recouvrementRelanceListSendTimeout,
        greaterThan(AppConstants.recouvrementRelanceListTimeout),
      );
    });
  });

  group('les octets rendus', () {
    test('un PDF valide devient une liste', () async {
      stub(pdfResponse());

      final result = await emit();

      expect(result, isNot(isA<Failure>()));
    });

    test('un 200 en HTML — portail captif — est REFUSÉ', () async {
      stub(pdfResponse(contentType: 'text/html'));

      expect(await emit(), isA<ServerFailure>());
    });

    test('un corps vide est refusé plutôt que rendu', () async {
      stub(pdfResponse(bytes: Uint8List(0)));

      expect(await emit(), isA<ServerFailure>());
    });

    test('des octets qui ne commencent pas par %PDF sont refusés', () async {
      stub(pdfResponse(bytes: Uint8List.fromList([0x3C, 0x21, 0x44, 0x4F])));

      expect(await emit(), isA<ServerFailure>());
    });
  });
}
