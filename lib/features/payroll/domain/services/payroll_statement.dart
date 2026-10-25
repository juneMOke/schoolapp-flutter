import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// Une ligne de l'état de paie : les colonnes du tableur des écoles, chaque
/// montant rangé par le calcul dans sa colonne. Centimes.
class PayrollStatementRow {
  final PayrollLine line;
  final StaffMember? member;
  final String? grade;

  const PayrollStatementRow({
    required this.line,
    required this.member,
    required this.grade,
  });

  /// A/S — avances remboursées en une échéance.
  int get salaryAdvanceInCents =>
      _advances((installments) => installments <= 1);

  /// Crédit — prêts étalés sur plusieurs échéances.
  int get loanInCents => _advances((installments) => installments > 1);

  int _advances(bool Function(int installments) keep) => line.advances
      .where((advance) => keep(advance.installments))
      .fold(0, (sum, advance) => sum + advance.takenInCents);
}

/// Un groupe de l'état : une catégorie du fichier du personnel.
class PayrollStatementGroup {
  /// `null` : une catégorie que ce poste ne connaît pas.
  final StaffCategory? category;
  final List<PayrollStatementRow> rows;

  const PayrollStatementGroup({required this.category, required this.rows});
}

/// L'état de paie d'un mois, groupé par catégorie dans l'ordre du fichier,
/// puis par nom.
abstract final class PayrollStatement {
  static List<PayrollStatementGroup> of(
    PayrollSnapshot snapshot,
    List<PayrollLine> lines,
  ) {
    final byCategory = <StaffCategory?, List<PayrollStatementRow>>{};
    for (final line in lines) {
      final member = snapshot.member(line.staffMemberId);
      (byCategory[member?.category] ??= []).add(
        PayrollStatementRow(line: line, member: member, grade: gradeOf(member)),
      );
    }
    final order = [...StaffCategory.values, null];
    return [
      for (final category in order)
        if (byCategory[category] case final rows?)
          PayrollStatementGroup(
            category: category,
            rows: rows
              ..sort(
                (a, b) => (a.member?.fullName ?? a.line.staffMemberId)
                    .compareTo(b.member?.fullName ?? b.line.staffMemberId),
              ),
          ),
    ];
  }

  /// Le grade de la fiche, sinon le niveau du premier diplôme (`L2` de
  /// « L2 — Licence »).
  static String? gradeOf(StaffMember? member) {
    final grade = member?.grade?.trim();
    if (grade != null && grade.isNotEmpty) return grade;
    final diplomas = member?.diplomas ?? const [];
    if (diplomas.isEmpty) return null;
    final level = diplomas.first.level.split('—').first.trim();
    return level.isEmpty ? null : level;
  }
}
