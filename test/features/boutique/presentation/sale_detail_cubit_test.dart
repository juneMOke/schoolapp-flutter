import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/claim_sale_receipt_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/sale_detail_cubit.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

class _MockGetDetail extends Mock implements GetBoutiqueSaleDetailUseCase {}

class _MockMarkPrinted extends Mock implements MarkSaleTicketPrintedUseCase {}

class _MockClaimReceipt extends Mock implements ClaimSaleReceiptUseCase {}

SaleDetail _detail({String? receiptNumber, String? receiptDocumentId}) =>
    SaleDetail(
      sale: RecordedSale(
        sale: BoutiqueSaleLocalModel(
          id: 's-1',
          schoolId: 'E1',
          academicYearId: 'ay-1',
          soldAt: '2026-09-19T08:00:00Z',
          receiptNumber: receiptNumber,
          receiptDocumentId: receiptDocumentId,
          syncStatus: 'SYNCED',
          updatedAt: 0,
        ),
        lines: const [],
      ),
    );

final _claimed = EditiqueDocument(
  type: EditiqueDocumentType.saleReceipt,
  bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
  fileName: 'ETL-RV-2526-000413.pdf',
  documentNumber: 'ETL-RV-2526-000413',
  documentId: 'doc-7',
);

void main() {
  late _MockGetDetail getDetail;
  late _MockMarkPrinted markPrinted;
  late _MockClaimReceipt claimReceipt;

  SaleDetailCubit cubit() => SaleDetailCubit(
    getDetail: getDetail,
    markPrinted: markPrinted,
    claimReceipt: claimReceipt,
    saleId: 's-1',
  );

  setUp(() {
    getDetail = _MockGetDetail();
    markPrinted = _MockMarkPrinted();
    claimReceipt = _MockClaimReceipt();
  });

  test('la piece reclamee est rendue a l appelant', () async {
    // Elle ne passe pas par l'état : l'écran l'affiche avec les octets en main,
    // au lieu de la re-télécharger par la restitution.
    when(() => getDetail(any())).thenAnswer((_) async => Right(_detail()));
    when(() => claimReceipt(any())).thenAnswer((_) async => Right(_claimed));

    final subject = cubit();
    await subject.load();
    final outcome = await subject.claimReceipt();

    expect(outcome.isRight(), isTrue);
    outcome.fold(
      (f) => fail('Attendu Right, reçu Left($f)'),
      (document) => expect(document.documentNumber, 'ETL-RV-2526-000413'),
    );
    await subject.close();
  });

  test('la relecture fait DISPARAITRE la reference provisoire', () async {
    // Le numéro arrive en base pendant la réclamation, et l'état doit suivre :
    // c'est ce qui retire le `PROV-` de la ligne « Reçu », du titre, et de tout
    // ticket réimprimé ensuite.
    //
    // ⚠️ **Ce cas ne prouve PAS l'utilité de l'égalité complète de
    // `SaleDetail`** — je l'avais cru, la contre-épreuve dit le contraire :
    // `load()` émet `loading` avant de réémettre `ready`, et cet état
    // intermédiaire rompt l'égalité à lui seul. Des `props` partiels laissent
    // donc ce test VERT (vérifié en les rétablissant). L'égalité complète reste
    // juste, mais elle corrige un piège **latent**, pas ce qui fait marcher cet
    // écran.
    var reads = 0;
    when(() => getDetail(any())).thenAnswer((_) async {
      reads++;
      return Right(
        reads == 1
            ? _detail()
            : _detail(
                receiptNumber: 'ETL-RV-2526-000413',
                receiptDocumentId: 'doc-7',
              ),
      );
    });
    when(() => claimReceipt(any())).thenAnswer((_) async => Right(_claimed));

    final subject = cubit();
    await subject.load();
    expect(subject.state.detail!.sale.sale.receiptNumber, isNull);

    await subject.claimReceipt();

    expect(
      subject.state.detail!.sale.sale.receiptNumber,
      'ETL-RV-2526-000413',
      reason: 'l état n a pas suivi ce que la base porte apres la reclamation',
    );
    expect(subject.state.detail!.canClaimReceipt, isFalse);
    await subject.close();
  });

  test('la fiche est relue MEME quand la reclamation echoue', () async {
    // La pièce a pu être consignée pendant que la réponse se perdait : garder
    // l'écran sur un état périmé y afficherait un `PROV-` que la base ne porte
    // plus.
    when(() => getDetail(any())).thenAnswer((_) async => Right(_detail()));
    when(
      () => claimReceipt(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('hors ligne')));

    final subject = cubit();
    await subject.load();
    final outcome = await subject.claimReceipt();

    expect(outcome.isLeft(), isTrue);
    // Deux lectures : celle du montage, et celle d'après la réclamation.
    verify(() => getDetail('s-1')).called(2);
    // L'écran reste sur une fiche lisible, jamais sur une carte d'erreur : la
    // vente est encaissée, et seul le papier a manqué.
    expect(subject.state.status, SaleDetailStatus.ready);
    await subject.close();
  });

  test('un cubit ferme ne relit rien apres la reclamation', () async {
    when(() => getDetail(any())).thenAnswer((_) async => Right(_detail()));
    when(() => claimReceipt(any())).thenAnswer((_) async => Right(_claimed));

    final subject = cubit();
    await subject.load();
    final pending = subject.claimReceipt();
    await subject.close();
    await pending;

    // Une seule lecture : celle du montage. Émettre après fermeture lèverait.
    verify(() => getDetail('s-1')).called(1);
  });
}
