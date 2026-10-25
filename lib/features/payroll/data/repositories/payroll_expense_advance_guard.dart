import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_advance_guard.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ids.dart';

/// Le port des Dépenses tenu par la Paie (B6) : une avance dont une retenue
/// est figée, ou dont une paie concernée est fermée, ne se rouvre plus ; sa
/// première retenue ne tombe que sur une paie encore ouverte.
class PayrollExpenseAdvanceGuard implements ExpenseAdvanceGuard {
  final PayrollDao _payrolls;
  final SalaryAdvanceDao _advances;
  final CurrentUserContext _currentUser;

  const PayrollExpenseAdvanceGuard({
    required PayrollDao payrolls,
    required SalaryAdvanceDao advances,
    required CurrentUserContext currentUser,
  }) : _payrolls = payrolls,
       _advances = advances,
       _currentUser = currentUser;

  @override
  Future<bool> isDeducted(String expenseId) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return false;
    final born = await _bornOf(schoolId, expenseId);
    // Une demande payée hors ligne n'a encore que son premier identifiant.
    final ids = {
      PayrollIds.salaryAdvanceIdOf(expenseId),
      for (final advance in born) advance.id,
    };
    final frozen = await _payrolls.frozenLines(schoolId);
    return frozen.values.any(
      (lines) => lines.any(
        (line) => line.advances.any(
          (taken) => ids.contains(taken.advanceId) && taken.takenInCents > 0,
        ),
      ),
    );
  }

  @override
  Future<bool> isMonthLocked(String expenseId, {String? firstMonth}) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return false;
    final live = (await _bornOf(
      schoolId,
      expenseId,
    )).where((advance) => !advance.isCancelled);
    final month = live.isEmpty ? firstMonth : live.first.firstMonth;
    if (month == null) return false;
    final headers = await _payrolls.headers(schoolId);
    return headers.entries.any(
      (entry) =>
          entry.key.compareTo(month) >= 0 &&
          entry.value.status != PayrollStatus.draft,
    );
  }

  @override
  Future<bool> acceptsFirstMonth(String month) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) return false;
    final header = (await _payrolls.headers(schoolId))[month];
    return header == null || header.status == PayrollStatus.draft;
  }

  Future<List<SalaryAdvance>> _bornOf(
    String schoolId,
    String expenseId,
  ) async => [
    for (final advance in await _advances.forSchool(schoolId))
      if (advance.expenseId == expenseId) advance,
  ];
}
