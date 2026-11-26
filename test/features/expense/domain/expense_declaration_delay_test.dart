import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_declaration_delay.dart';

Expense _declared({
  required DateTime disbursedAt,
  DateTime? receivedAt,
  ExpenseMode mode = ExpenseMode.declaration,
}) => Expense(
  id: 'e-1',
  typeId: 't-fuel',
  title: 'Carburant',
  amountInCents: 4500,
  currency: 'USD',
  status: ExpenseStatus.paid,
  expenseDate: DateTime(2026, 11, 20),
  clientUpdatedAt: DateTime.utc(2026, 11, 20),
  mode: mode,
  visaStatus: mode == ExpenseMode.declaration
      ? ExpenseVisaStatus.pending
      : null,
  disbursedAt: disbursedAt,
  voucher: receivedAt == null
      ? null
      : ExpenseVoucher(
          id: 'v-1',
          contentType: 'image/jpeg',
          sizeBytes: 1000,
          uploadedAt: receivedAt,
        ),
);

/// E1, option du back — l'écart entre décaissement et réception.
void main() {
  test('reçue tout de suite : zéro jour, pas en retard', () {
    final e = _declared(
      disbursedAt: DateTime.utc(2026, 11, 20, 8),
      receivedAt: DateTime.utc(2026, 11, 20, 8, 1),
    );
    expect(ExpenseDeclarationDelay.days(e), 0);
    expect(ExpenseDeclarationDelay.isLate(e), isFalse);
  });

  test('les jours se comptent à l’heure de l’école (UTC+1)', () {
    // 22 h 30 UTC = 23 h 30 à Kinshasa, puis 23 h 30 UTC = 0 h 30 le lendemain.
    final e = _declared(
      disbursedAt: DateTime.utc(2026, 11, 20, 22, 30),
      receivedAt: DateTime.utc(2026, 11, 20, 23, 30),
    );
    expect(ExpenseDeclarationDelay.days(e), 1);
  });

  test('72 h pile : pas en retard ; une minute de plus : en retard', () {
    final out = DateTime.utc(2026, 11, 20, 8);
    final exact = _declared(
      disbursedAt: out,
      receivedAt: out.add(const Duration(hours: 72)),
    );
    final over = _declared(
      disbursedAt: out,
      receivedAt: out.add(const Duration(hours: 72, minutes: 1)),
    );
    expect(ExpenseDeclarationDelay.isLate(exact), isFalse);
    expect(ExpenseDeclarationDelay.isLate(over), isTrue);
    expect(ExpenseDeclarationDelay.days(over), 3);
  });

  test('pas encore reçue, ou une demande : rien à dire', () {
    expect(
      ExpenseDeclarationDelay.days(
        _declared(disbursedAt: DateTime.utc(2026, 11, 20)),
      ),
      isNull,
    );
    expect(
      ExpenseDeclarationDelay.of(
        _declared(
          disbursedAt: DateTime.utc(2026, 11, 20),
          receivedAt: DateTime.utc(2026, 11, 25),
          mode: ExpenseMode.authorization,
        ),
      ),
      isNull,
    );
  });
}
