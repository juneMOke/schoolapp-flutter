import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les demandes d'avance au personnel, lues dans le registre des dépenses
/// (`expenses.staff_advance`) — en lecture seule : la dépense s'écrit par son
/// propre module. Une demande retirée n'en est plus une.
class PayrollAdvanceRequestDao {
  final DatabaseExecutor _db;

  PayrollAdvanceRequestDao(this._db);

  Future<List<PayrollAdvanceRequest>> forSchool(String schoolId) async {
    final rows = await _db.query(
      'expenses',
      where:
          'school_id = ? AND staff_advance IS NOT NULL '
          'AND deleted_at IS NULL AND server_deleted_at IS NULL',
      whereArgs: [schoolId],
      orderBy: 'expense_date, id',
    );
    return [
      for (final row in rows)
        if (ExpenseStaffAdvance.tryParse(row['staff_advance'])
            case final block?)
          PayrollAdvanceRequest(
            expenseId: row['id']! as String,
            number: row['expense_number'] as String?,
            block: block,
            amount: Money(
              (row['amount_in_cents']! as num).toInt(),
              row['currency']! as String,
            ),
            status: ExpenseStatus.fromWire(row['status'] as String?),
            fundingSource: ExpenseFundingSource.fromWire(
              row['funding_source'] as String?,
            ),
            paidOn: row['paid_on'] as String?,
            decidedAt: row['decided_at'] as String?,
            decidedByName: row['decided_by_name'] as String?,
            decisionReason: row['decision_reason'] as String?,
          ),
    ];
  }

  /// L'identifiant du type `STAFF_ADVANCE` semé pour l'école (T12), ou
  /// `null` tant que le serveur ne l'a pas semé.
  Future<String?> staffAdvanceTypeId(String schoolId) async {
    final rows = await _db.query(
      'ref_expense_types',
      columns: ['id'],
      where: 'school_id = ? AND code = ? AND active = 1',
      whereArgs: [schoolId, ExpenseStaffAdvance.typeCode],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['id'] as String?;
  }
}
