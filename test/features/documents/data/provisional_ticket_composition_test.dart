import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/repositories/provisional_ticket_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_receipt_lookup_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/receipt/payment_receipt_resolver_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class _MockFinanceOfflineRepository extends Mock
    implements FinanceOfflineRepository {}

class _EntitledAccess implements EditiqueCacheAccess {
  const _EntitledAccess();

  @override
  Future<bool> isEntitled() async => true;
}

/// Un reçu appris par le pull des pièces : métadonnées seules, sans PDF.
EditiqueCacheEntry _knownReceipt({int? cancelledAt}) => EditiqueCacheEntry(
  id: 'c-77',
  documentId: 'rcpt-77',
  documentNumber: 'CF-RC-2627-000279',
  docType: 'RC',
  studentId: 's-1',
  schoolId: 'school-1',
  ownerUid: 'u-1',
  sizeBytes: 0,
  cancelledAt: cancelledAt,
  createdAt: 2000,
  lastAccessedAt: 3000,
);

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalMention: 'provisoire',
  referenceLabel: 'Réf.',
  dateLabel: 'Date :',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  cashierLabel: 'Caissier :',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  annualMatriculationLabel: 'Mat. annuel :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  derivedAmountPrefix: 'soit',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance',
  balanceLabel: 'Solde restant à payer pour ce(s) frais',
  balanceTotalLabel: 'Total',
  historyLabel: 'Historique des paiements',
  historyTotalLabel: 'Total verse',
  signatureLabel: 'Signature du caissier',
  keepTicketNotice: 'Conservez ce ticket.',
  thanksNotice: 'Merci.',
  editorNotice: 'Recu edite par ETEELO CONNECT',
  editorSite: 'eteeloconnect.com',
);

LocalStudentCharge _charge({
  required int expected,
  required int paid,
  String currency = 'CDF',
  String id = 'c-1',
  String feeCode = 'TUITION',
  String label = 'Frais scolaires',
  // Nullable : `academic_year_id` l'est en base par construction, et c'est
  // précisément le cas que le solde imprimé oubliait.
  String? academicYearId = 'y-1',
}) => LocalStudentCharge(
  id: id,
  studentId: 's-1',
  academicYearId: academicYearId,
  feeCode: feeCode,
  label: label,
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
  // Le cache des pièces vit dans `device.db`, un AUTRE fichier que la base de
  // l'école, comme en production.
  late Database device;
  late EditiqueCacheDao cache;

  setUp(() async {
    db = await openFullOfflineDb();
    device = await openDeviceTestDb();
    cache = EditiqueCacheDao(device);
    dao = ProvisionalTicketDao(db);
    finance = _MockFinanceOfflineRepository();
    when(
      () => finance.getCharges(any()),
    ).thenAnswer((_) async => const Right(<LocalStudentCharge>[]));
    repository = ProvisionalTicketRepositoryImpl(
      dao: dao,
      finance: finance,
      receipts: PaymentReceiptResolverImpl(
        local: PaymentReceiptLookupDao(db),
        cache: cache,
        access: const _EntitledAccess(),
        currentUser: CurrentUserContext()..set('u-1', schoolId: 'school-1'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await device.close();
  });

  Future<void> seedPayment({
    String? cashierFirstName = 'Jean',
    String? cashierLastName = 'Kabeya',
    String? deviceId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
    String currency = 'CDF',

    /// L'attribution SERVEUR, seule connue d'un versement encaissé ailleurs.
    String? collectedByName,
    String? receiptId,

    /// `payments.cancelled_at` : le versement annulé par le serveur.
    int? cancelledAt,

    /// La ligne `generated_documents` est POSÉE PAR LE POSTE qui encaisse : un
    /// versement descendu par pull n'en a aucune en local.
    bool withLocalDocument = true,
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
      // Le versement ne porte plus de montant : il se dérive de ses
      // imputations, insérées juste après.
      'method': 'CASH',
      'paid_at': '2026-08-04T14:07:00.000',
      'payer_first_name': 'Papa',
      'payer_last_name': 'Mbala',
      'cashier_first_name': cashierFirstName,
      'cashier_last_name': cashierLastName,
      'collected_by_name': collectedByName,
      'receipt_id': receiptId,
      'cancelled_at': cancelledAt,
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
    // Ce qui est ENTRÉ DANS LE TIROIR, écrit par le chemin d'encaissement à
    // côté de l'imputation — et garanti sur tout l'historique par le backfill
    // de la v41. Le montant reçu du ticket en vient : le dériver des
    // imputations était le défaut que ce lot corrige.
    await db.insert('payment_tenders', {
      'id': 't-1',
      'client_uuid': 't-1',
      'payment_id': 'p-1',
      'amount_in_cents': 150000,
      'currency': currency,
      'rate_micros': 1000000,
      'pivot_currency': currency,
    });
    if (!withLocalDocument) return;
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

  /// Une imputation de plus sur le versement `p-1` : un second frais réglé au
  /// même passage au guichet, ou une seconde tranche du même.
  Future<void> addAllocation({
    required String id,
    required String feeCode,
    required String label,
    required int amount,
    String currency = 'CDF',
  }) => db.insert('payment_allocations', {
    'id': id,
    'client_uuid': id,
    'payment_id': 'p-1',
    'fee_code': feeCode,
    'student_charge_label': label,
    'amount_in_cents': amount,
    'currency': currency,
  });

  /// La trace d'impression n'autorise plus rien : elle DIT. La réimpression
  /// est libre, et cette date sert à choisir les mots de la ligne d'écran.
  ///
  /// Elle reste purement locale — « ce poste a servi le papier » est un fait
  /// d'appareil, jamais poussé ni descendu.
  group('trace d\'impression', () {
    test('un versement jamais imprimé ici ne porte aucune date', () async {
      await seedPayment(deviceId: 'device-1');

      expect(await repository.ticketPrintedAt('p-1'), isNull);
    });

    test('le tirage pose la date, et le geste reste offert', () async {
      await seedPayment(deviceId: 'device-1');
      final before = DateTime.now();
      await repository.markTicketPrinted('p-1');

      final at = await repository.ticketPrintedAt('p-1');
      expect(at, isNotNull);
      // À la seconde près : la trace porte l'instant du tirage, ce que la
      // ligne d'écran affiche telle quelle.
      expect(
        at!.isBefore(before.subtract(const Duration(seconds: 5))),
        isFalse,
      );
    });

    /// L'horodatage est celui de la DERNIÈRE impression, pas de la première.
    /// Un caissier qui lit « Imprimé le … » doit pouvoir s'y fier pour savoir
    /// quand le dernier papier est sorti — sans quoi la mention vieillirait
    /// pendant que les tirages s'enchaînent.
    test('un second tirage réécrit la date', () async {
      await seedPayment(deviceId: 'device-1');
      await repository.markTicketPrinted('p-1');
      final first = await repository.ticketPrintedAt('p-1');

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.markTicketPrinted('p-1');
      final second = await repository.ticketPrintedAt('p-1');

      expect(second!.isBefore(first!), isFalse);
      expect(second, isNot(first));
    });

    test('un versement introuvable ne porte pas de date', () async {
      expect(await repository.ticketPrintedAt('inconnu'), isNull);
    });
  });

  /// ## Ce qui a permis de retirer la garde `device_id`
  ///
  /// Le rattrapage refusait tout versement encaissé sur une AUTRE tablette,
  /// pour une raison précise et alors exacte : le ticket serait sorti dégradé
  /// — « Réf. » sur un UUID, libellés de répartition sur les codes de frais
  /// bruts, aucun caissier à qui l'imputer.
  ///
  /// Ce lot a branché les trois sources qui manquaient. Ce test le CONSTATE sur
  /// la pièce composée, plutôt que de le déduire du code : c'est lui qui
  /// autorise la réimpression libre à s'offrir hors du poste d'encaissement.
  group('un versement encaissé ailleurs compose une pièce entière', () {
    /// La forme réelle d'un versement descendu par pull : aucune ligne
    /// `generated_documents` locale, aucun `cashier_*` de ce poste, mais
    /// l'attribution serveur et le `receipt_id` qui, eux, descendent.
    Future<void> seedForeign() => seedPayment(
      deviceId: 'autre-tablette',
      cashierFirstName: null,
      cashierLastName: null,
      collectedByName: 'Alice Nsimba',
      receiptId: 'rcpt-77',
      withLocalDocument: false,
    );

    // Le défaut constaté le 26/09/2026 : l'UUID entier du versement
    // s'imprimait en « Réf. », faute de ligne documentaire locale.
    test('la référence est le numéro scellé lu dans le cache', () async {
      await seedForeign();
      await cache.upsert(_knownReceipt());

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.reference, 'CF-RC-2627-000279');
    });

    test('inconnue du cache, la référence est le repli court', () async {
      await seedForeign();

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.reference, 'P1');
      expect(model.reference, isNot('p-1'));
    });

    test('un reçu annulé ne compose aucun ticket', () async {
      await seedForeign();
      await cache.upsert(_knownReceipt(cancelledAt: 1790400000000));

      final result = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );

      expect(result.isLeft(), isTrue);
    });

    test('un versement annulé ne compose aucun ticket', () async {
      await seedPayment(
        deviceId: 'autre-tablette',
        receiptId: 'rcpt-77',
        cancelledAt: 1790400000000,
        withLocalDocument: false,
      );

      final result = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );

      expect(result.isLeft(), isTrue);
    });

    /// La correction la plus importante des trois : `isProvisional` se lit
    /// AFFIRMATIVEMENT sur `receipt_id`. Lu par négation du numéro, il aurait
    /// rendu `true` ici — l'absence de ligne locale n'est pas l'absence de
    /// sceau — et le papier d'un reçu scellé se serait dit « provisoire ».
    test('la pièce scellée ailleurs ne se dit PAS provisoire', () async {
      await seedForeign();

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.isProvisional, isFalse);
    });

    test('l attribution serveur tient la ligne du caissier', () async {
      await seedForeign();

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      // RG-012-11 : une pièce non scellée vaut par l'humain qu'elle nomme.
      expect(model.cashierFullName, 'Alice Nsimba');
    });

    test('les libellés restent des mots, pas des codes de frais', () async {
      await seedForeign();

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.allocations.single.label, 'Frais scolaires');
      expect(model.allocations.single.label, isNot('TUITION'));
    });

    /// Les imputations ET les lignes d'encaissement descendent par le pull
    /// (`finance_ledger_sync_dao.dart`, même patron patch-puis-insert). Sans
    /// elles le papier n'aurait ni montant ni ventilation, et la garde aurait
    /// eu raison de refuser.
    test('le montant reçu et la ventilation sont là', () async {
      await seedForeign();

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));
      final out = TicketTextLayout.render(model).join('\n');

      expect(model.amountReceived.isEmpty, isFalse);
      expect(out, contains('1 500 FC'));
      expect(out, contains('Frais scolaires'));
      expect(out, contains('Alice Nsimba'));
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
    expect(model.reference, 'PROV-A1B2C3-9F8E7D6C');
    expect(model.cashierFullName, 'Jean Kabeya');
    expect(model.amountReceived, MoneyBag.of(const [Money(150000, 'CDF')]));
    expect(model.allocations.single.label, 'Frais scolaires');
  });

  // Le scellement écrase `number` : c'est `provisional_number` qui garde la
  // trace du papier déjà remis au parent.
  /// ⚠️ **Règle RENVERSÉE, et le test est inversé plutôt que supprimé.**
  ///
  /// Le ticket portait le numéro PROVISOIRE même après scellement, parce que
  /// `provisional_number` survit à l'ACK là où `number` est écrasée. Depuis que
  /// la pièce devient officielle dès qu'elle a un numéro définitif, c'est ce
  /// dernier qu'elle doit porter : un papier qui s'annonce officiel sous une
  /// référence provisoire serait irrapprochable avec le reçu scellé qu'il
  /// annonce.
  ///
  /// Le provisoire reste lisible en base — la colonne n'a pas bougé — il n'est
  /// simplement plus ce que le ticket montre.
  group('le caractère provisoire, lu affirmativement', () {
    /// ⚠️ **LE test qui garde la décision du porteur.**
    ///
    /// Un versement encaissé sur une AUTRE caisse est descendu par le pull et
    /// n'a **aucune ligne `generated_documents` locale** — le contrat le dit
    /// lui-même. Toute règle qui déduirait le caractère provisoire de l'absence
    /// d'un numéro définitif local le déclarerait donc provisoire, et la mention
    /// s'imprimerait **exactement sur les tickets qui doivent être officiels**.
    ///
    /// Sans ce test, la régression est **invisible sur un poste de
    /// développement**, où la ligne locale existe toujours.
    test('scellé ailleurs, sans ligne locale : aucune mention', () async {
      await seedPayment();
      // Le cas réel : la pièce est scellée côté serveur (receipt_id descendu),
      // et ce poste n'a jamais produit de document pour elle.
      await db.delete(
        'generated_documents',
        where: 'id = ?',
        whereArgs: ['doc-1'],
      );
      await db.update(
        'payments',
        {'receipt_id': 'rc-42'},
        where: 'id = ?',
        whereArgs: ['p-1'],
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.isProvisional, isFalse);
      expect(
        TicketTextLayout.render(model).join('\n'),
        isNot(contains('provisoire')),
      );
    });

    /// Le pendant : pas de `receipt_id`, donc pas encore scellé — la mention
    /// doit être là, quelle que soit la présence d'une ligne locale.
    test('non scellé : la mention est là', () async {
      await seedPayment();

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.isProvisional, isTrue);
      expect(
        TicketTextLayout.render(model).join('\n'),
        contains('Réf. provisoire'),
      );
    });

    /// Une chaîne vide n'est pas un scellement. Sans le `trim`, un
    /// `receipt_id` à `''` — que rien n'interdit en base — rendrait le ticket
    /// officiel sans qu'aucune pièce n'existe.
    test('un receipt_id vide ne scelle rien', () async {
      await seedPayment();
      await db.update(
        'payments',
        {'receipt_id': '   '},
        where: 'id = ?',
        whereArgs: ['p-1'],
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.isProvisional, isTrue);
    });
  });

  test('porte le numéro DÉFINITIF dès que la pièce est scellée', () async {
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
      result.getOrElse(() => throw StateError('échec')).reference,
      'ETL-RC-2526-000212',
    );
  });

  group('le solde détaillé par nature', () {
    /// Le détail EXPLIQUE les devises au lieu de les juxtaposer : « il vous
    /// reste 10 000 FC et 314 dollars » posait plus de questions qu'elle n'en
    /// résolvait.
    test('une ligne par nature, et le total les somme', () async {
      await seedPayment();
      // Le versement règle AUSSI l'organisation : sans cette imputation, son
      // solde n'aurait rien à faire sur ce ticket.
      await addAllocation(
        id: 'a-om',
        feeCode: 'OM',
        label: 'Organisation materiels examens',
        amount: 10000,
      );
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async => Right([
          _charge(id: 'c-1', expected: 400000, paid: 150000),
          _charge(
            id: 'c-2',
            feeCode: 'OM',
            label: 'Organisation materiels examens',
            expected: 60000,
            paid: 10000,
          ),
        ]),
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.remainingByCharge, hasLength(2));
      expect(model.remainingByCharge.first.label, 'Frais scolaires');
      expect(model.remainingByCharge.first.amountInCents, 250000);
      expect(model.remainingByCharge.last.amountInCents, 50000);

      // ⚠️ Le total DÉRIVE des lignes : un parent additionne ce qu'il lit.
      expect(model.remainingBalance, MoneyBag.of(const [Money(300000, 'CDF')]));
    });

    /// ⚠️ **Le cas qui a motivé la règle.** Un parent règle les frais divers ;
    /// le minerval, dû dans la même devise, sortait jusqu'ici dans le solde de
    /// CE ticket — le filtre ne portait que sur la devise. Le papier d'un
    /// versement ne dit que le solde des frais que ce versement a réglés.
    test('un frais que ce versement n a pas réglé n apparaît pas', () async {
      await seedPayment(); // règle TUITION, et lui seul
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async => Right([
          _charge(id: 'c-1', expected: 400000, paid: 150000),
          _charge(
            id: 'c-2',
            feeCode: 'MINERVAL',
            label: 'Minerval',
            expected: 900000,
            paid: 0,
          ),
        ]),
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.remainingByCharge, hasLength(1));
      expect(model.remainingByCharge.single.label, 'Frais scolaires');
      expect(model.remainingBalance, MoneyBag.of(const [Money(250000, 'CDF')]));

      // Sur le papier : le seul frais réglé, et aucun total pour le redire.
      final lines = TicketTextLayout.render(model);
      final title = lines.indexWhere((l) => l.startsWith('Solde'));
      expect(lines[title + 1], contains('Frais scolaires'));
      expect(lines.join('\n'), isNot(contains('Minerval')));
      expect(lines.where((l) => l.startsWith('Total')), isEmpty);
    });

    /// Deux tranches d'un même frais font UNE ligne, comme la ventilation.
    test('deux créances d\'un même code font une ligne', () async {
      await seedPayment();
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async => Right([
          _charge(id: 'c-1', expected: 200000, paid: 50000),
          _charge(id: 'c-2', expected: 200000, paid: 100000),
        ]),
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.remainingByCharge, hasLength(1));
      expect(model.remainingByCharge.single.amountInCents, 250000);
    });

    /// ⚠️ Jamais sur le seul code : additionner deux devises imprimerait un
    /// chiffre qui n'est l'argent de personne.
    test('un même code en deux devises fait deux lignes', () async {
      await seedPayment();
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async => Right([
          _charge(id: 'c-1', expected: 200000, paid: 50000),
          _charge(id: 'c-2', expected: 300, paid: 100, currency: 'USD'),
        ]),
      );
      // Le versement doit toucher les deux devises pour que le solde les porte.
      await db.insert('payment_allocations', {
        'id': 'a-usd',
        'client_uuid': 'a-usd',
        'payment_id': 'p-1',
        'fee_code': 'TUITION',
        'student_charge_label': 'Frais scolaires',
        'amount_in_cents': 100,
        'currency': 'USD',
      });

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.remainingByCharge, hasLength(2));
      expect(
        {for (final l in model.remainingByCharge) l.currency},
        {'CDF', 'USD'},
      );
    });

    /// Le frais que ce versement SOLDE s'imprime à zéro. L'escamoter valait
    /// tant que le bloc listait tous les frais de l'élève ; il ne porte plus
    /// que ceux que le parent vient de régler, et « 0 » est précisément ce
    /// qu'il vient lire. Omis, il emporterait le bloc entier — et un ticket
    /// sans solde se lit comme un solde inconnu.
    test('le frais que ce versement solde s imprime à zéro', () async {
      await seedPayment();
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async =>
            Right([_charge(id: 'c-1', expected: 150000, paid: 150000)]),
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));

      expect(model.remainingByCharge, hasLength(1));
      expect(model.remainingByCharge.single.label, 'Frais scolaires');
      expect(model.remainingByCharge.single.amountInCents, 0);
      // Un sac à ZÉRO, pas un sac absent : « en francs, il ne reste rien ».
      expect(model.remainingBalance, MoneyBag.of(const [Money(0, 'CDF')]));
    });

    /// Le papier lui-même : titre, détail, filet, total — dans cet ordre.
    ///
    /// Le qualificatif de temps est DANS le titre depuis qu'il a remplacé la
    /// réserve posée sous le total. L'assertion de comptage reste, avec la
    /// nouvelle chaîne : c'est elle qui empêche de le redire ligne par ligne.
    test('le papier porte le titre, le détail puis le total', () async {
      await seedPayment();
      // Deux frais réglés : sous une ligne UNIQUE, le total se tairait.
      await addAllocation(
        id: 'a-om',
        feeCode: 'OM',
        label: 'Organisation',
        amount: 10000,
      );
      when(() => finance.getCharges('s-1')).thenAnswer(
        (_) async => Right([
          _charge(id: 'c-1', expected: 400000, paid: 150000),
          _charge(
            id: 'c-2',
            feeCode: 'OM',
            label: 'Organisation',
            expected: 60000,
            paid: 10000,
          ),
        ]),
      );

      final model = (await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      )).getOrElse(() => throw StateError('échec'));
      final lines = TicketTextLayout.render(model);
      final flat = lines.join('\n');

      final title = lines.indexWhere((l) => l.startsWith('Solde'));
      // Cherché APRÈS le titre : le frais réglé est aussi dans la répartition
      // au-dessus, sous le même nom.
      final detail = lines.indexWhere(
        (l) => l.contains('Organisation'),
        title + 1,
      );
      // Cherché APRÈS le détail, lui aussi : le bloc d'historique porte
      // désormais son propre « Total verse » plus bas sur le papier.
      final total = lines.indexWhere((l) => l.startsWith('Total'), detail + 1);
      expect(title, greaterThan(0));
      expect(detail, greaterThan(title));
      expect(total, greaterThan(detail));

      // Le filet est ENTRE le détail et le total, pas ailleurs : c'est ce qui
      // fait du total une somme posée plutôt qu'une ligne de détail de plus.
      expect(lines[total - 1], '-' * 48);

      // La qualification se dit UNE fois, dans le titre. Répétée par ligne,
      // elle se lirait comme une réserve sur chaque frais.
      //
      // ⚠️ Le titre qualifie le PÉRIMÈTRE depuis le 2026-09-24 (« pour ce(s)
      // frais ») ; il portait avant un qualificatif de TEMPS (« au moment de
      // l'impression »), retiré par décision du porteur. Ne pas le rétablir.
      expect(
        'pour ce(s) frais'.allMatches(flat).length,
        1,
        reason: 'la qualification ne se répète pas',
      );
    });
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
        result.getOrElse(() => throw StateError('échec')).remainingBalance,
        MoneyBag.of(const [Money(250000, 'CDF')]),
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
        result.getOrElse(() => throw StateError('échec')).remainingBalance,
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
      result.getOrElse(() => throw StateError('échec')).remainingBalance,
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
    expect(rendered, contains('Réf.'));
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
    expect(model.amountReceived, MoneyBag.of(const [Money(150000, 'CDF')]));
    expect(model.reference, 'PROV-A1B2C3-9F8E7D6C');
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
    expect(model.schoolLocality, 'Ngaliema');
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
      result.getOrElse(() => throw StateError('échec')).remainingBalance,
      MoneyBag.of(const [Money(250000, 'CDF')]),
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
      result.getOrElse(() => throw StateError('échec')).remainingBalance,
      MoneyBag.of(const [Money(350000, 'CDF')]),
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
      result.getOrElse(() => throw StateError('échec')).remainingBalance,
      isNull,
    );
  });

  /// v39 — le papier remis à la famille doit nommer LA tranche encaissée.
  ///
  /// Avant, deux versements sur deux tranches d'un même minerval sortaient du
  /// même ticket, mot pour mot : la répartition n'imprimait que le libellé gelé,
  /// identique d'une tranche à l'autre quand l'école les nomme pareil.
  group('la répartition regroupe par nature', () {
    /// ⚠️ **La régression que le libellé par nature a introduite.** Le code de
    /// tranche `(OM1)` était ce qui distinguait deux imputations d'un même
    /// frais ; en le retirant sans regrouper, trois tranches sortaient sur
    /// TROIS lignes identiques — pire qu'avant, parce qu'un lecteur ne peut
    /// plus les départager du tout.
    ///
    /// Rien n'interdit ce cas en base : `payment_allocations` n'a aucune
    /// contrainte d'unicité sur `(payment_id, fee_code)`, et payer deux
    /// tranches d'un coup est le geste nominal du guichet.
    test('deux tranches d\'un même frais font UNE ligne', () async {
      await seedPayment();
      await db.delete('payment_allocations');
      await addAllocation(
        id: 'a-1',
        feeCode: 'OM',
        label: 'Organisation materiels examens - 1/3',
        amount: 15000,
      );
      await addAllocation(
        id: 'a-2',
        feeCode: 'OM',
        label: 'Organisation materiels examens - 1/3',
        amount: 15000,
      );

      final lines = await dao.findAllocations('p-1');

      expect(lines, hasLength(1), reason: 'deux lignes indistinguables');
      expect(lines.single.amountInCents, 30000);
    });

    /// ⚠️ **Jamais sur le seul code.** Grouper francs et dollars ensemble
    /// produirait « le chiffre qui n'est l'argent de personne » que ce gabarit
    /// refuse partout ailleurs.
    test('deux devises d\'un même frais font DEUX lignes', () async {
      await seedPayment();
      await db.delete('payment_allocations');
      await addAllocation(
        id: 'a-1',
        feeCode: 'OM',
        label: 'Organisation',
        amount: 15000,
      );
      await addAllocation(
        id: 'a-2',
        feeCode: 'OM',
        label: 'Organisation',
        amount: 2000,
        currency: 'USD',
      );

      final lines = await dao.findAllocations('p-1');
      expect(lines, hasLength(2));
      expect({for (final l in lines) l.currency}, {'CDF', 'USD'});
    });

    /// Le cas du repli : sans titre de section, deux tranches portent deux
    /// libellés figés DIFFÉRENTS. Le porteur a tranché — une seule ligne, le
    /// **premier** libellé du groupe.
    ///
    /// ⚠️ Et « premier » doit être défini, sinon ce n'est pas une règle : le
    /// ticket est librement réimprimable, donc un libellé pris sans ordre
    /// établi ferait porter deux intitulés différents à deux tirages du même
    /// versement, sur des papiers qu'une famille garde côte à côte.
    test('deux libellés figés différents : une ligne, le premier', () async {
      await seedPayment();
      await db.delete('payment_allocations');
      await addAllocation(
        id: 'a-1',
        feeCode: 'OM',
        label: 'Organisation materiels examens - 1/3',
        amount: 15000,
      );
      await addAllocation(
        id: 'a-2',
        feeCode: 'OM',
        label: 'Organisation materiels examens - 2/3',
        amount: 15000,
      );

      final lines = await dao.findAllocations('p-1');
      expect(lines, hasLength(1));
      expect(lines.single.label, 'Organisation materiels examens - 1/3');
      expect(lines.single.amountInCents, 30000);
    });

    /// Un ticket réimprimé doit être identique à l'original — vrai par principe
    /// depuis que la réimpression est libre.
    ///
    /// ⚠️ **Ce test ne prouve PAS le déterminisme, et il ne faut pas le croire.**
    /// Éprouvé en faisant gagner le DERNIER libellé du groupe : il est resté
    /// **vert**. Deux appels dans le même processus, sur la même base, obtiennent
    /// de SQLite le même ordre physique — la comparaison ne peut donc pas voir
    /// un ordre instable.
    ///
    /// Ce qui garde réellement la règle est le test précédent, qui asserte le
    /// libellé **attendu** et non l'égalité de deux exécutions ; celui-ci n'est
    /// qu'un filet de non-régression sur la forme du résultat.
    test('deux compositions du même versement rendent la même forme', () async {
      await seedPayment();
      await db.delete('payment_allocations');
      for (var i = 0; i < 6; i++) {
        await addAllocation(
          id: 'a-$i',
          feeCode: i.isEven ? 'OM' : 'TUITION',
          label: 'Nature ${i.isEven ? "OM" : "TUITION"} - tranche $i',
          amount: 1000 * (i + 1),
          currency: i % 3 == 0 ? 'USD' : 'CDF',
        );
      }

      final first = await dao.findAllocations('p-1');
      final second = await dao.findAllocations('p-1');

      expect(first.length, second.length);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].label, second[i].label);
        expect(first[i].amountInCents, second[i].amountInCents);
        expect(first[i].currency, second[i].currency);
      }
    });
  });

  group('la répartition imprimée nomme la tranche', () {
    Future<void> seedTariff(String id, {String? code}) =>
        db.insert('ref_fee_tariffs', {
          'id': id,
          'academic_year_id': 'y-1',
          'school_level_id': 'lvl-1',
          'school_level_group_id': 'grp-1',
          'fee_code': 'TUITION',
          'code': code,
          'label': 'Minerval',
          'amount_in_cents': 150000,
          'currency': 'CDF',
        });

    Future<void> pointAllocationAt(String? tariffId) => db.update(
      'payment_allocations',
      {'fee_tariff_id': tariffId},
      where: 'id = ?',
      whereArgs: ['a-1'],
    );

    /// ⚠️ **Règle RENVERSÉE, test inversé plutôt que supprimé.** Le code de
    /// tranche s'imprimait pour distinguer deux versements sur deux tranches
    /// d'un même minerval. Le porteur a arbitré que le nom du frais suffit sur
    /// un reçu remis à une famille : le code est du vocabulaire de gestion.
    test('le code de tranche ne s\'imprime plus', () async {
      await seedPayment();
      await seedTariff('tar-t2', code: 'T2');
      await pointAllocationAt('tar-t2');

      final lines = await dao.findAllocations('p-1');
      expect(lines.single.label, 'Frais scolaires');
    });

    /// Une grille simple reçoit du serveur un code qui vaut la nature. Imprimer
    /// « Frais scolaires (TUITION) » ajouterait du bruit sur tous les tickets de
    /// toutes les écoles, pour ne rien distinguer nulle part.
    test('code égal à la nature → pas de parenthèse', () async {
      await seedPayment();
      await seedTariff('tar-plain', code: 'TUITION');
      await pointAllocationAt('tar-plain');

      final lines = await dao.findAllocations('p-1');
      expect(lines.single.label, 'Frais scolaires');
    });

    /// LE cas qui compte sur un papier : le tarif a quitté l'appareil (grille
    /// caviardée, année purgée). Le ticket retombe sur le libellé seul — perdre
    /// la LIGNE reviendrait à remettre un détail qui ne fait plus la somme.
    test(
      'tarif absent de l\'appareil → la ligne survit, sans parenthèse',
      () async {
        await seedPayment();
        await pointAllocationAt('tar-jamais-pullé');

        final lines = await dao.findAllocations('p-1');
        expect(lines, hasLength(1), reason: 'LEFT JOIN, jamais JOIN');
        expect(lines.single.label, 'Frais scolaires');
        expect(lines.single.amountInCents, 150000);
      },
    );

    test('imputation sans tarif → le libellé gelé, nu', () async {
      await seedPayment();

      final lines = await dao.findAllocations('p-1');
      expect(lines.single.label, 'Frais scolaires');
    });

    /// Le repli d'origine, préservé : sans libellé gelé, le ticket imprime la
    /// nature BRUTE plutôt qu'un blanc. Le code, lui, ne s'y ajoute plus.
    test('sans libellé gelé → la nature brute, nue', () async {
      await seedPayment();
      await seedTariff('tar-t2', code: 'T2');
      await pointAllocationAt('tar-t2');
      await db.update(
        'payment_allocations',
        {'student_charge_label': '   '},
        where: 'id = ?',
        whereArgs: ['a-1'],
      );

      final lines = await dao.findAllocations('p-1');
      expect(lines.single.label, 'TUITION');
    });
  });

  group('l\'historique des versements antérieurs', () {
    /// Un versement ANTÉRIEUR du même élève, avec sa ligne de tiroir.
    ///
    /// Aucune imputation : l'historique se lit sur `payment_tenders`, et un
    /// versement sans allocation doit y figurer comme les autres.
    Future<void> seedPast(
      String id, {
      required String paidAt,
      int amount = 5000000,
      String currency = 'CDF',
      String? academicYearId = 'y-1',
      String studentId = 's-1',
      int? cancelledAt,
    }) async {
      await db.insert('payments', {
        'id': id,
        'client_uuid': id,
        'student_id': studentId,
        'academic_year_id': academicYearId,
        'method': 'CASH',
        'paid_at': paidAt,
        'sync_status': 'SYNCED',
        'cancelled_at': cancelledAt,
        'updated_at': 0,
      });
      await db.insert('payment_tenders', {
        'id': 't-$id',
        'client_uuid': 't-$id',
        'payment_id': id,
        'amount_in_cents': amount,
        'currency': currency,
        'rate_micros': 1000000,
        'pivot_currency': currency,
      });
    }

    Future<List<TicketHistoryEntry>> history() async {
      final built = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );
      return built.fold((f) => throw StateError('$f'), (m) => m.paymentHistory);
    }

    /// La séparation qui porte toute la règle : le champ dit ce que la BASE
    /// sait d'autre, le getter dit ce que le PAPIER montre.
    test('absent du champ, présent dans la liste imprimée', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');

      final built = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );
      final model = built.fold((f) => throw StateError('$f'), (m) => m);

      expect(model.paymentHistory.map((e) => e.paidAt.day), [3]);
      expect(model.printedPayments.map((e) => e.paidAt.day), [4, 3]);
      expect(model.printedPaymentsTotal.entries.single.amountInCents, 5150000);
    });

    test(
      'le versement COURANT ne figure pas dans son propre historique',
      () async {
        await seedPayment();

        expect(await history(), isEmpty);
      },
    );

    test('du plus récent au plus ancien', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');
      await seedPast('p-2', paidAt: '2026-07-12T09:30:00.000Z');

      final lines = await history();
      expect(lines.map((e) => e.paidAt.day), [12, 3]);
    });

    test('un versement extourné est OMIS, pas barré', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');
      await seedPast(
        'p-2',
        paidAt: '2026-07-12T09:30:00.000Z',
        cancelledAt: 1700000000000,
      );

      final lines = await history();
      expect(lines.map((e) => e.paidAt.day), [3]);
    });

    test('une autre année reste dehors', () async {
      await seedPayment();
      await seedPast(
        'p-0',
        paidAt: '2025-07-03T09:30:00.000Z',
        academicYearId: 'y-0',
      );

      expect(await history(), isEmpty);
    });

    test('un versement SANS année compte dans toutes les années', () async {
      await seedPayment();
      await seedPast(
        'p-0',
        paidAt: '2026-07-03T09:30:00.000Z',
        academicYearId: null,
      );

      expect((await history()).single.paidAt.day, 3);
    });

    test('un autre élève reste dehors', () async {
      await seedPayment();
      await seedPast(
        'p-0',
        paidAt: '2026-07-03T09:30:00.000Z',
        studentId: 's-2',
      );

      expect(await history(), isEmpty);
    });

    test(
      'deux devises du même versement font UN sac, pas deux entrées',
      () async {
        await seedPayment();
        await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');
        await db.insert('payment_tenders', {
          'id': 't-p-0-usd',
          'client_uuid': 't-p-0-usd',
          'payment_id': 'p-0',
          'amount_in_cents': 10000,
          'currency': 'USD',
          'rate_micros': 1000000,
          'pivot_currency': 'USD',
        });

        final lines = await history();
        expect(lines, hasLength(1));
        expect(lines.single.received.entries, hasLength(2));
      },
    );

    /// Le perçu, jamais l'imputé : un versement dont le tiroir a vu des francs
    /// pour une créance en dollars s'imprime en francs, comme le « Montant
    /// reçu » du ticket courant.
    test('lit le TIROIR, pas les imputations', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');
      await db.update(
        'payment_tenders',
        {'pivot_currency': 'USD', 'rate_micros': 2850000000},
        where: 'payment_id = ?',
        whereArgs: ['p-0'],
      );

      final lines = await history();
      expect(lines.single.received.entries.single.currency, 'CDF');
    });

    /// Sans `toLocal()`, un versement pris à 00 h 30 à Kinshasa (UTC+1)
    /// s'imprimerait daté de la veille, et l'historique contredirait la ligne
    /// « Date : » d'un ticket tiré ce jour-là.
    test('la date passe à l\'heure du guichet', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');

      final at = (await history()).single.paidAt;
      expect(at.isUtc, isFalse);
      expect(at, DateTime.parse('2026-07-03T09:30:00.000Z').toLocal());
    });

    /// Le repli d'instant courant de `_parsePaidAt` vaut pour le versement en
    /// cours, dont le geste a bien lieu maintenant. Appliqué à un versement
    /// ANCIEN, il le daterait d'aujourd'hui — une date fausse sur un papier
    /// remis à un parent.
    test('une date illisible fait sauter la ligne', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: 'pas-une-date');
      await seedPast('p-2', paidAt: '2026-07-12T09:30:00.000Z');

      final lines = await history();
      expect(lines.map((e) => e.paidAt.day), [12]);
    });

    /// ⚠️ Le bloc n'est alors PAS vide : il porte la ligne du jour, comme au
    /// premier versement de l'année. Les deux cas sont indistinguables sur le
    /// papier — c'est la contrepartie assumée d'un bloc qui sort toujours.
    test(
      'année inconnue : aucun antérieur, mais la ligne du jour reste',
      () async {
        await seedPayment();
        await db.update(
          'payments',
          {'academic_year_id': null},
          where: 'id = ?',
          whereArgs: ['p-1'],
        );
        await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');

        final built = await repository.buildForPayment(
          paymentId: 'p-1',
          labels: _labels,
        );
        final model = built.fold((f) => throw StateError('$f'), (m) => m);

        expect(model.paymentHistory, isEmpty);
        expect(model.printedPayments.map((e) => e.paidAt.day), [4]);
      },
    );

    test('le papier porte le titre, les dates puis le total', () async {
      await seedPayment();
      await seedPast('p-0', paidAt: '2026-07-03T09:30:00.000Z');
      await seedPast(
        'p-2',
        paidAt: '2026-07-12T09:30:00.000Z',
        amount: 2500000,
      );

      final built = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );
      final lines = built.fold(
        (f) => throw StateError('$f'),
        (m) => TicketTextLayout.render(m),
      );

      expect(lines.any((l) => l.contains('Historique des paiements')), isTrue);
      expect(lines.any((l) => l.contains('12/07/2026')), isTrue);
      expect(lines.any((l) => l.contains('03/07/2026')), isTrue);
      // 50 000 + 25 000 versés avant, 1 500 sur ce ticket : le total est le
      // CUMUL de l'année, pas un sous-total arrêté la veille.
      expect(
        lines.any((l) => l.contains('Total verse') && l.contains('76 500 FC')),
        isTrue,
      );
    });
  });

  group('le matricule annuel', () {
    /// Une inscription de l'élève, sur une année donnée.
    Future<void> seedInscription({
      String id = 'enr-1',
      String academicYearId = 'y-1',
      String status = 'COMPLETED',
      String? annual = 'CF-P4-000018',
      int updatedAt = 100,
    }) => db.insert('enrollments', {
      'id': id,
      'student_id': 's-1',
      'enrollment_type': 'NEW_ENROLLMENT',
      'status': status,
      'academic_year_id': academicYearId,
      'enrollment_date': '2026-07-01',
      'annual_matriculation_number': annual,
      'sync_status': 'SYNCED',
      'updated_at': updatedAt,
    });

    Future<String?> lu() async {
      final built = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );
      return built.fold(
        (f) => throw StateError('$f'),
        (m) => m.annualMatriculationNumber,
      );
    }

    test('prend celui de l année du versement', () async {
      await seedPayment();
      await seedInscription();
      await seedInscription(
        id: 'enr-0',
        academicYearId: 'y-0',
        annual: 'CF-P3-000018',
      );

      expect(await lu(), 'CF-P4-000018');
    });

    /// `(élève, année)` peut rendre plusieurs lignes : une inscription annulée
    /// et celle qui vit.
    test('préfère l inscription non annulée', () async {
      await seedPayment();
      await seedInscription(
        id: 'enr-annulee',
        status: 'CANCELLED',
        annual: 'CF-P9-999999',
        updatedAt: 999,
      );
      await seedInscription(id: 'enr-vive', annual: 'CF-P4-000018');

      expect(await lu(), 'CF-P4-000018');
    });

    /// Le ticket est librement réimprimable : deux tirages du même versement ne
    /// doivent pas porter deux matricules. Le tri est total.
    test('deux lectures rendent le même matricule', () async {
      await seedPayment();
      await seedInscription(id: 'enr-a', annual: 'CF-P4-000018');
      await seedInscription(id: 'enr-b', annual: 'CF-P5-000018');

      expect(await lu(), await lu());
    });

    test('année inconnue sur le versement : aucun matricule annuel', () async {
      await seedPayment();
      await seedInscription();
      await db.update(
        'payments',
        {'academic_year_id': null},
        where: 'id = ?',
        whereArgs: ['p-1'],
      );

      expect(await lu(), isNull);
    });

    test('aucune inscription : le gabarit tait la ligne', () async {
      await seedPayment();

      final built = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );
      final lines = built.fold(
        (f) => throw StateError('$f'),
        (m) => TicketTextLayout.render(m),
      );

      expect(lines.any((l) => l.contains('Mat. annuel')), isFalse);
    });

    test('le papier le porte sous le matricule classique', () async {
      await seedPayment();
      await seedInscription();

      final built = await repository.buildForPayment(
        paymentId: 'p-1',
        labels: _labels,
      );
      final lines = built.fold(
        (f) => throw StateError('$f'),
        (m) => TicketTextLayout.render(m),
      );

      final classique = lines.indexWhere((l) => l.startsWith('Matricule :'));
      final annuel = lines.indexWhere((l) => l.startsWith('Mat. annuel :'));

      expect(classique, isNonNegative);
      expect(annuel, classique + 1);
      expect(lines[annuel], contains('CF-P4-000018'));
    });
  });
}
