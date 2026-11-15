import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/cash_register_lock.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sale_repository.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/correct_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/record_payment_use_case.dart';

class _Lock implements CashRegisterLock {
  final Set<String> closed;
  const _Lock(this.closed);

  @override
  Future<Set<String>> closedToday() async => closed;
}

class _BrokenLock implements CashRegisterLock {
  @override
  Future<Set<String>> closedToday() => Future.error(StateError('base'));
}

class _MockFinance extends Mock implements FinanceOfflineRepository {}

class _MockCorrections extends Mock implements PaymentCorrectionRepository {}

class _MockSales extends Mock implements BoutiqueSaleRepository {}

RecordPaymentDraft _draft({String? method, String currency = 'USD'}) =>
    RecordPaymentDraft(
      studentId: 's1',
      academicYearId: 'y1',
      method: method,
      paidAt: '2026-10-22T09:00:00Z',
      tenders: [
        TenderDraft(
          amountInCents: 5000,
          currency: currency,
          rateMicros: 1000000,
          pivotCurrency: currency,
        ),
      ],
      allocations: const [],
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_draft());
    registerFallbackValue(
      const PaymentCorrectionDraft(
        paymentId: 'p0',
        reason: PaymentCorrectionReason.wrongAmount,
      ),
    );
  });

  group('guardCashRegisters', () {
    test('une devise close aujourd hui retient, avec sa devise', () async {
      final result = await guardCashRegisters(const _Lock({'USD'}), ['usd']);
      expect(
        result.fold((f) => f, (_) => null),
        const CashRegisterClosedFailure('USD'),
      );
    });

    test('l autre devise passe', () async {
      final result = await guardCashRegisters(const _Lock({'USD'}), ['CDF']);
      expect(result, const Right<Failure, Unit>(unit));
    });

    test('sans verrou, ou base illisible : le guichet reste ouvert', () async {
      expect(await guardCashRegisters(null, ['USD']), isA<Right>());
      expect(await guardCashRegisters(_BrokenLock(), ['USD']), isA<Right>());
    });
  });

  group('RecordPaymentUseCase', () {
    late _MockFinance repo;

    setUp(() {
      repo = _MockFinance();
      when(
        () => repo.recordPayment(any()),
      ).thenAnswer((_) async => const Right('p1'));
    });

    test(
      'caisse USD close : rien n est écrit, et le refus nomme la devise',
      () async {
        final useCase = RecordPaymentUseCase(repo, lock: const _Lock({'USD'}));
        final result = await useCase(_draft());
        expect(
          result.fold((f) => f, (_) => null),
          const CashRegisterClosedFailure('USD'),
        );
        verifyNever(() => repo.recordPayment(any()));
      },
    );

    test('sans lignes de perçu : la devise se lit sur les montants', () {
      final draft = RecordPaymentDraft(
        studentId: 's1',
        academicYearId: 'y1',
        paidAt: '2026-10-22T09:00:00Z',
        amounts: MoneyBag.of(const [Money(5000, 'CDF')]),
        allocations: const [],
      );
      expect(cashCurrenciesOf(draft), {'CDF'});
    });

    test('ni perçu ni montants : la devise se lit sur les imputations', () {
      const draft = RecordPaymentDraft(
        studentId: 's1',
        academicYearId: 'y1',
        paidAt: '2026-10-22T09:00:00Z',
        allocations: [
          AllocationDraft(
            feeCode: 'TUITION',
            studentChargeLabel: 'Minerval',
            amountInCents: 5000,
            currency: 'USD',
          ),
        ],
      );
      expect(cashCurrenciesOf(draft), {'USD'});
    });

    test(
      'un versement en francs passe quand seule la caisse USD est close',
      () async {
        final useCase = RecordPaymentUseCase(repo, lock: const _Lock({'USD'}));
        expect(await useCase(_draft(currency: 'CDF')), const Right('p1'));
      },
    );

    test('un versement par mobile money ne touche pas la caisse', () async {
      final useCase = RecordPaymentUseCase(repo, lock: const _Lock({'USD'}));
      expect(await useCase(_draft(method: 'MOBILE_MONEY')), const Right('p1'));
    });
  });

  group('CorrectPaymentUseCase', () {
    late _MockCorrections repo;

    setUp(() {
      repo = _MockCorrections();
      when(() => repo.correctPayment(any())).thenAnswer(
        (_) async => const Right(PaymentCorrectionOutcome(correctionId: 'c1')),
      );
    });

    test('un remplaçant qui fait entrer des dollars est retenu', () async {
      final useCase = CorrectPaymentUseCase(repo, lock: const _Lock({'USD'}));
      final result = await useCase(
        PaymentCorrectionDraft(
          paymentId: 'p0',
          reason: PaymentCorrectionReason.wrongAmount,
          cashMoved: true,
          replacement: _draft(),
        ),
      );
      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.correctPayment(any()));
    });

    test('sans argent qui change de main, la correction passe', () async {
      final useCase = CorrectPaymentUseCase(repo, lock: const _Lock({'USD'}));
      final result = await useCase(
        PaymentCorrectionDraft(
          paymentId: 'p0',
          reason: PaymentCorrectionReason.wrongAmount,
          replacement: _draft(),
        ),
      );
      expect(result.isRight(), isTrue);
    });
  });

  group('boutique', () {
    const polo = BoutiqueArticle(
      id: 'art-polo',
      academicYearId: 'ay-1',
      code: 'POLO',
      label: 'Polo',
      family: ArticleFamily.uniforme,
      pricingMode: PricingMode.prixUnique,
      unitPriceInCents: 5000,
      currency: 'USD',
    );
    const cart = BoutiqueCart(
      lines: [CartLine(key: 'k0', article: polo)],
    );

    test('la devise posée est celle du catalogue', () {
      expect(tenderedCurrenciesOf(cart), {'USD'});
    });

    test('la vente elle-même est refusée sans rien écrire', () async {
      final repo = _MockSales();
      final useCase = RecordBoutiqueSaleUseCase(
        repo,
        lock: const _Lock({'USD'}),
      );
      final result = await useCase(cart: cart, academicYearId: 'ay-1');
      expect(
        result.fold((f) => f, (_) => null),
        const CashRegisterClosedFailure('USD'),
      );
      verifyZeroInteractions(repo);
    });

    test('un polo en dollars réglé en francs pèse sur la caisse CDF', () {
      expect(tenderedCurrenciesOf(cart.withTenderCurrency('USD', 'CDF')), {
        'CDF',
      });
    });
  });
}
