import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_advance_guard.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ids.dart';

/// Le port des Dépenses tenu par la Paie (B6) : une avance dont une retenue
/// est figée ne se rouvre plus, et sa première retenue ne tombe que sur une
/// paie encore ouverte.
class PayrollExpenseAdvanceGuard implements ExpenseAdvanceGuard {
  final PayrollDao _payrolls;
  final CurrentUserContext _currentUser;

  const PayrollExpenseAdvanceGuard({
    required PayrollDao payrolls,
    required CurrentUserContext currentUser,
  }) : _payrolls = payrolls,
       _currentUser = currentUser;

  @override
  Future<bool> isDeducted(String expenseId) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return false;
    final advanceId = PayrollIds.salaryAdvanceIdOf(expenseId);
    final frozen = await _payrolls.frozenLines(schoolId);
    return frozen.values.any(
      (lines) => lines.any(
        (line) => line.advances.any(
          (taken) => taken.advanceId == advanceId && taken.takenInCents > 0,
        ),
      ),
    );
  }

  @override
  Future<bool> acceptsFirstMonth(String month) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return false;
    final header = (await _payrolls.headers(schoolId))[month];
    return header == null || header.status == PayrollStatus.draft;
  }
}
