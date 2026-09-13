import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_register_view.dart';

// Samedi 12 septembre 2026.
final _today = DateTime(2026, 9, 12, 16);

final _rate = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2800 * ExchangeRate.scale,
  effectiveFrom: DateTime.utc(2026, 9, 1),
);

ExpenseType _type(String id, int rank) => ExpenseType(
  id: id,
  code: id.toUpperCase(),
  label: 'Type $id',
  shortLabel: id,
  icon: 'layers',
  colorHex: '#8C8478',
  softColorHex: '#F1EFE9',
  defaultCurrency: 'USD',
  sortOrder: rank,
  active: true,
);

Expense _expense(
  String id, {
  required String day,
  String typeId = 'elec',
  int cents = 1000,
  String currency = 'USD',
  ExpenseStatus status = ExpenseStatus.paid,
  String? number,
}) => Expense(
  id: id,
  number: number,
  typeId: typeId,
  title: 'Dépense $id',
  amountInCents: cents,
  currency: currency,
  status: status,
  expenseDate: DateTime.parse(day),
  clientUpdatedAt: DateTime.utc(2026),
);

ExpenseRegisterSnapshot _snapshot(
  List<Expense> expenses, {
  ExchangeRate? rate,
}) => ExpenseRegisterSnapshot(
  types: [_type('elec', 0), _type('four', 1)],
  expenses: expenses,
  usdToCdf: rate,
);

void main() {
  group('ExpenseRegisterView', () {
    final rows = [
      for (var i = 0; i < 45; i++)
        _expense(
          'e$i',
          day: '2026-09-${(i % 12 + 1).toString().padLeft(2, '0')}',
          status: i.isEven ? ExpenseStatus.paid : ExpenseStatus.unpaid,
          typeId: i % 3 == 0 ? 'four' : 'elec',
        ),
      _expense('aout', day: '2026-08-31'),
    ];

    test(
      'période + palier : 45 lignes de septembre, 40 affichées, 5 restantes',
      () {
        final view = ExpenseRegisterView.compute(
          snapshot: _snapshot(rows),
          period: ExpensePeriod.initial,
          query: ExpenseQuery.none,
          limit: 40,
          today: _today,
        );
        expect(view.rows, hasLength(45));
        expect(view.remaining, 5);
        expect(view.groups.expand((g) => g.expenses), hasLength(40));
        // Les compteurs décrivent la sélection entière, pas le palier.
        expect(view.paid.count + view.unpaid.count, 45);
        expect(view.total.usdCents, 45 * 1000);
      },
    );

    test(
      'filtres en ET ; les compteurs de puces ignorent les autres filtres',
      () {
        final view = ExpenseRegisterView.compute(
          snapshot: _snapshot(rows),
          period: ExpensePeriod.initial,
          query: const ExpenseQuery(
            typeIds: {'four'},
            status: ExpenseStatus.unpaid,
          ),
          limit: 40,
          today: _today,
        );
        expect(
          view.rows.every(
            (e) => e.typeId == 'four' && e.status == ExpenseStatus.unpaid,
          ),
          isTrue,
        );
        expect(view.typeCounts['four'], 15);
        expect(view.typeCounts['elec'], 30);
      },
    );

    test('une journée coupée par le palier garde son effectif et son total '
        'entiers dans l’en-tête', () {
      final view = ExpenseRegisterView.compute(
        snapshot: _snapshot(rows),
        period: ExpensePeriod.initial,
        query: ExpenseQuery.none,
        limit: 40,
        today: _today,
      );
      // 3 + 3 + 3 + 7 × 4 = 37 lignes avant le 2 septembre : le palier en
      // montre 3 sur 4.
      final cut = view.groups.last;
      expect(ExpenseDay.format(cut.day), '2026-09-02');
      expect(cut.expenses, hasLength(3));
      final day = view.dayTotals['2026-09-02']!;
      expect(day.count, 4);
      expect(day.usdCents, 4 * 1000);
    });
  });

  group('ExpenseDashboardView', () {
    test('mois en cours : variation à durée écoulée égale (A6)', () {
      final view = ExpenseDashboardView.compute(
        snapshot: _snapshot([
          _expense('sept', day: '2026-09-05', cents: 3000),
          _expense('aout-tot', day: '2026-08-05', cents: 2000),
          // Au-delà du 12 août : hors de la référence écoulée.
          _expense('aout-tard', day: '2026-08-25', cents: 9000),
        ]),
        period: ExpensePeriod.initial,
        today: _today,
      );
      expect(view.variationElapsedOnly, isTrue);
      expect(view.variationPercent, 50);
    });

    test('avec taux : postes classés par lecture en dollars', () {
      final view = ExpenseDashboardView.compute(
        snapshot: _snapshot([
          _expense(
            'a',
            day: '2026-09-02',
            typeId: 'elec',
            cents: 38500000,
            currency: 'CDF',
          ),
          _expense('b', day: '2026-09-03', typeId: 'four', cents: 20000),
          _expense('c', day: '2026-09-04', typeId: 'four', cents: 100),
        ], rate: _rate),
        period: ExpensePeriod.initial,
        today: _today,
      );
      expect(view.sharesRankedByCount, isFalse);
      // 385 000 FC = 137,50 $ < 201,00 $ de fournitures.
      expect(view.shares.map((s) => s.typeId), ['four', 'elec']);
      expect(view.total.usdCents, 20100 + 13750);
    });

    test(
      'sans taux et deux devises : classement par nombre, jamais par montant',
      () {
        final view = ExpenseDashboardView.compute(
          snapshot: _snapshot([
            _expense(
              'a',
              day: '2026-09-02',
              typeId: 'elec',
              cents: 38500000,
              currency: 'CDF',
            ),
            _expense('b', day: '2026-09-03', typeId: 'four', cents: 20000),
            _expense(
              'c',
              day: '2026-09-04',
              typeId: 'elec',
              cents: 100000,
              currency: 'CDF',
            ),
          ]),
          period: ExpensePeriod.initial,
          today: _today,
        );
        expect(view.total.usdCents, isNull);
        expect(view.sharesRankedByCount, isTrue);
        expect(view.shares.first.typeId, 'elec');
      },
    );

    test('la plus ancienne dépense non payée, et le vide', () {
      final view = ExpenseDashboardView.compute(
        snapshot: _snapshot([
          _expense('recente', day: '2026-09-10', status: ExpenseStatus.unpaid),
          _expense('ancienne', day: '2026-09-02', status: ExpenseStatus.unpaid),
          _expense('payee', day: '2026-09-01'),
        ]),
        period: ExpensePeriod.initial,
        today: _today,
      );
      expect(view.oldestUnpaid?.id, 'ancienne');
      expect(view.unpaid.count, 2);

      final empty = ExpenseDashboardView.compute(
        snapshot: _snapshot(const []),
        period: ExpensePeriod.initial,
        today: _today,
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.variationPercent, isNull);
    });

    test(
      'jour : la série couvre les 7 jours, au-delà de la journée consultée',
      () {
        final view = ExpenseDashboardView.compute(
          snapshot: _snapshot([
            _expense('j-6', day: '2026-09-06', cents: 500),
            _expense('j0', day: '2026-09-12', cents: 700),
          ]),
          period: const ExpensePeriod(granularity: ExpenseGranularity.day),
          today: _today,
        );
        expect(view.series, hasLength(7));
        expect(view.series.first.totals.usdCents, 500);
        expect(view.series.last.totals.usdCents, 700);
        // Les chiffres clés, eux, ne comptent que la journée.
        expect(view.total.count, 1);
      },
    );
  });
}
