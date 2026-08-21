import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/repositories/provisional_ticket_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

import '../../offline_full_db.dart';

class _MockFinanceOfflineRepository extends Mock
    implements FinanceOfflineRepository {}

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalBanner: 'Provisoire',
  referenceLabel: 'Réf.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance',
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve de synchronisation',
  keepTicketNotice: 'Conservez ce ticket.',
);

LocalStudentCharge _charge({
  required int expected,
  required int paid,
  String currency = 'CDF',
  // Nullable : `academic_year_id` l'est en base par construction, et c'est
  // précisément le cas que le solde imprimé oubliait.
  String? academicYearId = 'y-1',
}) => LocalStudentCharge(
  id: 'c-1',
  studentId: 's-1',
  academicYearId: academicYearId,
  feeCode: 'TUITION',
  label: 'Frais scolaires',
  expectedAmountInCents: expected,
  amountPaidInCents: paid,
  amountPaidPendingInCents: 0,
  currency: currency,
  status: StudentChargeStatus.due,
);

void main() {
  late Database db;
  late ProvisionalTicketDao dao;
  late _MockFinanceOfflineRepository finance;
  late ProvisionalTicketRepositoryImpl repository;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ProvisionalTicketDao(db);
    finance = _MockFinanceOfflineRepository();
    when(
      () => finance.getCharges(any()),
    ).thenAnswer((_) async => const Right(<LocalStudentCharge>[]));
    repository = ProvisionalTicketRepositoryImpl(
      dao: dao,
      finance: finance,
      deviceIdentity: _FakeDeviceIdentity(),
    );
  });

  tearDown(() async => db.close());

  Future<void> seedPayment({
    String? cashierFirstName = 'Jean',
    String? cashierLastName = 'Kabeya',
    String? deviceId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
    String currency = 'CDF',
  }) async {
    await db.insert('students', {
      'id': 's-1',
      'first_name': 'Amina',
      'last_name': 'Mbala',
      'surname': 'Kasa',
      'gender': 'FEMALE',
      'date_of_birth': '2014-02-01',
      'matriculation_number': 'MAT-0042',
      'sync_status': 'SYNCED',
      'updated_at': 0,
    });
    await db.insert('payments', {
      'id': 'p-1',
      'client_uuid': 'p-1',
      'student_id': 's-1',
      'academic_year_id': 'y-1',
      'amount_in_cents': 150000,
      'currency': currency,
      'method': 'CASH',
      'paid_at': '2026-08-04T14:07:00.000',
      'payer_first_name': 'Papa',
      'payer_last_name': 'Mbala',
      'cashier_first_name': cashierFirstName,
      'cashier_last_name': cashierLastName,
      'device_id': deviceId,
      'sync_status': 'PENDING_SYNC',
      'updated_at': 0,
    });
    await db.insert('payment_allocations', {
      'id': 'a-1',
      'client_uuid': 'a-1',
      'payment_id': 'p-1',
      'fee_code': 'TUITION',
      'student_charge_label': 'Frais scolaires',
      'amount_in_cents': 150000,
      'currency': currency,
    });
    await db.insert('generated_documents', {
      'id': 'doc-1',
      'doc_domain': 'PAYMENT',
      'payment_id': 'p-1',
      'student_id': 's-1',
      'doc_type': 'RC',
      'number': 'PROV-A1B2C3-9F8E7D6C',
      'provisional_number': 'PROV-A1B2C3-9F8E7D6C',
      'status': 'PROVISIONAL',
      'created_at': 10,
    });
  }

  /// Le rattrapage d'impression n'est PAS une réimpression : il ne s'offre que
  /// sur un versement dont aucun papier n'est sorti, encaissé sur CETTE
  /// tablette. Ces deux conditions vivent dans le repository parce qu'elles
  /// sont métier — l'écran, lui, n'ajoute que l'annulation du reçu.
  group('rattrapage d\'impression', () {
    test('un versement de ce poste jamais imprimé l attend', () async {
      await seedPayment(deviceId: 'device-1');

      expect(await repository.awaitsTicketPrint('p-1'), isTrue);
    });

    test('une fois le papier sorti, plus jamais', () async {
      await seedPayment(deviceId: 'device-1');
      await repository.markTicketPrinted('p-1');

      // C'est ce qui empêche le rattrapage de devenir une réimpression, que
      // l'ADR-013 interdit.
      expect(await repository.awaitsTicketPrint('p-1'), isFalse);
      expect(await repository.hasPrintedTicket('p-1'), isTrue);
    });

    test('un versement encaissé ailleurs n est pas proposé', () async {
      await seedPayment(deviceId: 'autre-tablette');

      // Le ticket sortirait sans référence provisoire locale et avec les codes
      // de frais en guise de libellés : un papier illisible pour la famille.
      expect(await repository.awaitsTicketPrint('p-1'), isFalse);
    });

    test('un versement sans appareil connu n est pas proposé', () async {
      await seedPayment(deviceId: null);

      expect(await repository.awaitsTicketPrint('p-1'), isFalse);
    });

    test('un versement introuvable n est pas proposé', () async {
      expect(await repository.awaitsTicketPrint('inconnu'), isFalse);
    });
  });

  test('compose le ticket depuis les seules lignes locales', () async {
    await seedPayment();

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );

    final model = result.getOrElse(() => throw StateError('échec'));
    expect(model.studentFullName, 'Mbala Kasa Amina');
    expect(model.matriculationNumber, 'MAT-0042');
    expect(model.provisionalReference, 'PROV-A1B2C3-9F8E7D6C');
    expect(model.cashierFullName, 'Jean Kabeya');
    expect(model.amountReceivedInCents, 150000);
    expect(model.allocations.single.label, 'Frais scolaires');
  });

  // Le scellement écrase `number` : c'est `provisional_number` qui garde la
  // trace du papier déjà remis au parent.
  test('lit le numéro provisoire même après scellement', () async {
    await seedPayment();
    await db.update(
      'generated_documents',
      {'number': 'ETL-RC-2526-000212', 'status': 'DEFINITIVE'},
      where: 'id = ?',
      whereArgs: ['doc-1'],
    );

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );

    expect(
      result.getOrElse(() => throw StateError('échec')).provisionalReference,
      'PROV-A1B2C3-9F8E7D6C',
    );
  });

  test(
    'reprend le solde du domaine Facturation, pas un calcul maison',
    () async {
      await seedPayment();
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async => Right([_charge(expected: 400000, paid: 150000)]),
      );

      final result = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );

      expect(
        result
            .getOrElse(() => throw StateError('échec'))
            .remainingBalanceInCents,
        250000,
      );
    },
  );

  // La devise est libre PAR LIGNE dans ce modèle : additionner des devises
  // différentes produirait un chiffre faux sur un papier remis à un parent.
  test(
    'omet le solde quand aucune créance n est dans la devise du versement',
    () async {
      await seedPayment(currency: 'USD');
      when(
        () => finance.getCharges('s-1'),
      ).thenAnswer((_) async => Right([_charge(expected: 400000, paid: 0)]));

      final result = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );

      expect(
        result
            .getOrElse(() => throw StateError('échec'))
            .remainingBalanceInCents,
        isNull,
      );
    },
  );

  test('omet le solde quand la lecture des créances échoue', () async {
    await seedPayment();
    when(
      () => finance.getCharges('s-1'),
    ).thenAnswer((_) async => const Left(StorageFailure('illisible')));

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );

    expect(
      result.getOrElse(() => throw StateError('échec')).remainingBalanceInCents,
      isNull,
    );
  });

  // Référentiel jamais pullé, roster absent, encaissement antérieur à la v19 :
  // trois absences NORMALES hors ligne. Aucune n'empêche d'imprimer.
  test('imprime malgré école, classe et caissier inconnus', () async {
    await seedPayment(cashierFirstName: null, cashierLastName: null);

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );
    final model = result.getOrElse(() => throw StateError('échec'));

    expect(model.schoolName, isEmpty);
    expect(model.classroomName, isNull);
    expect(model.cashierFullName, isNull);

    final rendered = TicketTextLayout.render(model).join('\n');
    expect(rendered, contains('MBALA KASA AMINA'));
    expect(rendered, contains('PROVISOIRE'));
  });

  /// La CAUSE, ancrée côté données, du refus posé dans
  /// `provisional_ticket_print_flow.dart`. Le symptôme s'observe à l'écran ; il
  /// vient d'ici : le repository fait `student?.fullName ?? ''`, donc une ligne
  /// `students` ABSENTE ne se distingue en rien d'un élève réellement anonyme —
  /// le modèle sort valide, avec un nom vide, et le gabarit l'imprime.
  ///
  /// Cette absence est le cas NORMAL sur une tablette de caisse : `students`
  /// n'est hydratée que par le pull d'Inscription, gardé sur `enrollment.read`.
  test('sans ligne `students`, le nom composé est VIDE, pas absent', () async {
    await seedPayment();
    await db.delete('students', where: 'id = ?', whereArgs: ['s-1']);

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );
    final model = result.getOrElse(() => throw StateError('échec'));

    // Pas un `Left`, pas un `null` : une chaîne vide. Rien en aval ne peut
    // distinguer ce cas d'un nom légitimement absent, d'où la garde en amont.
    expect(model.studentFullName, isEmpty);
    expect(model.matriculationNumber, isNull);
    // Le reste du ticket est intact — c'est bien un papier complet et anonyme
    // qui sortirait, pas un rendu cassé.
    expect(model.amountReceivedInCents, 150000);
    expect(model.provisionalReference, 'PROV-A1B2C3-9F8E7D6C');
  });

  test('refuse d imprimer un encaissement introuvable', () async {
    final result = await repository.buildForPayment(
      paymentId: 'inconnu',
      labels: _labels,
    );

    expect(result.isLeft(), isTrue);
  });

  test('porte l école et la classe quand le référentiel est là', () async {
    await seedPayment();
    await db.insert('ref_school', {
      'id': 'sc-1',
      'name': 'Complexe scolaire La Colombe',
      'municipality': 'Ngaliema',
    });
    await db.insert('ref_classrooms', {
      'id': 'cl-1',
      'name': '5e primaire A',
      'academic_year_id': 'y-1',
    });
    await db.insert('ref_classroom_members', {
      'id': 'm-1',
      'student_id': 's-1',
      'classroom_id': 'cl-1',
      'academic_year_id': 'y-1',
      'student_first_name': 'Amina',
      'student_last_name': 'Mbala',
    });

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );
    final model = result.getOrElse(() => throw StateError('échec'));

    expect(model.schoolName, 'Complexe scolaire La Colombe');
    expect(model.schoolMunicipality, 'Ngaliema');
    expect(model.classroomName, '5e primaire A');
  });

  // Le solde du ticket doit être celui de l'ANNÉE du versement, comme l'écran.
  // Sans ce filtre, un élève réinscrit verrait son arriéré N-1 additionné au
  // reste dû N — deux vérités contradictoires sur le même élève au même instant,
  // dont l'une est remise sur papier.
  test('exclut les créances des autres années du solde imprimé', () async {
    await seedPayment();
    when(() => finance.getCharges('s-1')).thenAnswer(
      (_) async => Right([
        _charge(expected: 400000, paid: 150000), // année du versement
        _charge(expected: 300000, paid: 200000, academicYearId: 'y-0'),
      ]),
    );

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );

    // 250 000 seulement — pas 350 000.
    expect(
      result.getOrElse(() => throw StateError('échec')).remainingBalanceInCents,
      250000,
    );
  });

  /// Le pendant du test précédent, et le plus coûteux des deux s'il manque :
  /// une créance SANS année compte dans toutes les années. C'est la règle que
  /// suit tout le reste de Facturation — lecture du grand-livre, garde-fou de
  /// génération, paiements — et l'égalité stricte qui vivait ici imprimait donc
  /// une dette PLUS PETITE que celle affichée à l'écran, sur un papier remis à
  /// un parent. L'écart ne se rattrape nulle part : le reste à payer est clampé
  /// à zéro, donc une créance écartée disparaît purement et simplement.
  test('compte les créances sans année dans le solde imprimé', () async {
    await seedPayment();
    when(() => finance.getCharges('s-1')).thenAnswer(
      (_) async => Right([
        _charge(expected: 400000, paid: 150000), // 250 000 sur l'année
        _charge(expected: 100000, paid: 0, academicYearId: null), // 100 000
      ]),
    );

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );

    expect(
      result.getOrElse(() => throw StateError('échec')).remainingBalanceInCents,
      350000,
    );
  });

  test('omet le solde quand le versement ne porte aucune année', () async {
    await seedPayment();
    await db.update(
      'payments',
      {'academic_year_id': null},
      where: 'id = ?',
      whereArgs: ['p-1'],
    );
    when(
      () => finance.getCharges('s-1'),
    ).thenAnswer((_) async => Right([_charge(expected: 400000, paid: 0)]));

    final result = await repository.buildForPayment(
      paymentId: 'p-1',
      labels: _labels,
    );

    expect(
      result.getOrElse(() => throw StateError('échec')).remainingBalanceInCents,
      isNull,
    );
  });
}

/// L'identité d'appareil ne sert qu'au rattrapage d'impression : la composition
/// du ticket ne la consulte jamais.
class _FakeDeviceIdentity implements DeviceIdentityService {
  @override
  Future<String> getOrCreateDeviceId() async => 'device-1';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
