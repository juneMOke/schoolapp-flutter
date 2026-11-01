import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/local/cancellation_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/repositories/cancellation_ticket_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

const _url = 'https://api.eteelo.com/verify/RC/rcpt-77';

const _labels = TicketCancellationLabels(
  title: 'Ticket d\'annulation',
  receiptLabel: 'Reçu n°',
  cancelledMark: 'Annulé',
  issuedAtLabel: 'Émis le :',
  amountLabel: 'Montant annulé :',
  cancelledAtLabel: 'Annulé le :',
  reasonLabel: 'Motif :',
  detailLabel: 'Précision :',
  cashReturnedLabel: 'Argent rendu :',
  yes: 'Oui',
  no: 'Non',
  cancelledByLabel: 'Par :',
  classroomLabel: 'Classe :',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  verificationNotice: 'Scannez pour vérifier ce reçu',
  reasons: {'REFUNDED': 'Argent rendu au payeur'},
);

class _Receipts implements PaymentReceiptResolver {
  PaymentReceiptReference reference = const PaymentReceiptReference(
    number: 'CF-RC-2627-000821',
    status: PaymentReceiptStatus.definitive,
    verificationUrl: _url,
  );

  @override
  Future<PaymentReceiptReference> resolve(String paymentId) async => reference;
}

/// Révision de D-4 (2026-10-30) : le ticket d'annulation porte le QR du reçu
/// annulé — scanné, il dit « annulé ».
void main() {
  late Database db;
  late _Receipts receipts;
  late CancellationTicketRepositoryImpl repository;

  setUp(() async {
    db = await openFullOfflineDb();
    receipts = _Receipts();
    repository = CancellationTicketRepositoryImpl(
      tickets: ProvisionalTicketDao(db),
      cancellations: CancellationTicketDao(db),
      receipts: receipts,
    );
    await db.insert('payments', {
      'id': 'p-1',
      'client_uuid': 'p-1',
      'student_id': 's-1',
      'academic_year_id': 'y-1',
      'method': 'CASH',
      'paid_at': '2026-10-05T12:43:00.000',
      'cancelled_at': DateTime(2026, 10, 6, 9, 12).millisecondsSinceEpoch,
      'cancellation_reason_code': 'REFUNDED',
      'sync_status': 'SYNCED',
      'updated_at': 0,
    });
  });

  tearDown(() => db.close());

  Future<TicketCancellationModel> build() async =>
      (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

  test('l URL de vérification du reçu annulé passe au ticket', () async {
    expect((await build()).verificationUrl, _url);
  });

  test('sans URL connue, le ticket sort sans QR', () async {
    receipts.reference = const PaymentReceiptReference(
      number: 'CF-RC-2627-000821',
      status: PaymentReceiptStatus.definitive,
    );

    expect((await build()).verificationUrl, isNull);
  });
}
