import 'dart:convert';

import 'package:equatable/equatable.dart';

/// La nature d'une avance au personnel : retenue en une fois, ou étalée.
enum ExpenseStaffAdvanceKind {
  advance('ADVANCE'),
  loan('LOAN');

  const ExpenseStaffAdvanceKind(this.wire);
  final String wire;

  static ExpenseStaffAdvanceKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value?.trim().toUpperCase()) return kind;
    }
    return null;
  }
}

/// Le bloc R.H. d'une dépense de type « Avance / prêt au personnel »
/// (`STAFF_ADVANCE`, B5, T12) : l'agent, la nature, les échéances, le motif.
/// Contenu « dernier écrit gagne » de la dépense, corrigeable tant qu'elle
/// est en attente ou refusée. [firstMonth] est fixé au paiement (T13).
///
/// Sans `hr.pay.read`, le serveur ne le descend pas (T14) : le registre des
/// dépenses voit le montant, pas l'agent.
class ExpenseStaffAdvance extends Equatable {
  final String staffMemberId;
  final ExpenseStaffAdvanceKind kind;

  /// 1 pour une avance ; 2 à 4 pour un prêt (B8).
  final int installments;

  /// Valeur du fil de `SalaryAdvanceReason` (`MEDICAL`…).
  final String reason;
  final String? reasonDetail;

  /// `YYYY-MM` — la paie de la première retenue, posée par le geste PAY.
  final String? firstMonth;

  const ExpenseStaffAdvance({
    required this.staffMemberId,
    required this.kind,
    required this.installments,
    required this.reason,
    this.reasonDetail,
    this.firstMonth,
  });

  /// Le code stable du type semé par le serveur (T12) — le seul type que la
  /// tablette reconnaît par son code.
  static const String typeCode = 'STAFF_ADVANCE';

  static const int maxInstallments = 4;

  Map<String, dynamic> toJson() => {
    'staffMemberId': staffMemberId,
    'kind': kind.wire,
    'installments': installments,
    'reason': reason,
    'reasonDetail': reasonDetail,
    'firstMonth': ?firstMonth,
  };

  String encode() => jsonEncode(toJson());

  /// `null` si le bloc est absent ou illisible.
  static ExpenseStaffAdvance? tryParse(Object? raw) {
    if (raw is String) {
      try {
        return tryParse(jsonDecode(raw));
      } catch (_) {
        return null;
      }
    }
    if (raw is! Map) return null;
    final member = raw['staffMemberId'];
    final kind = ExpenseStaffAdvanceKind.fromWire(raw['kind'] as String?);
    final installments = raw['installments'];
    final reason = raw['reason'];
    if (member is! String ||
        member.isEmpty ||
        kind == null ||
        installments is! num ||
        reason is! String) {
      return null;
    }
    final first = raw['firstMonth'];
    final detail = raw['reasonDetail'];
    return ExpenseStaffAdvance(
      staffMemberId: member,
      kind: kind,
      installments: installments.toInt(),
      reason: reason,
      reasonDetail: detail is String && detail.trim().isNotEmpty
          ? detail
          : null,
      firstMonth: first is String && first.length == 7 ? first : null,
    );
  }

  ExpenseStaffAdvance withFirstMonth(String month) => ExpenseStaffAdvance(
    staffMemberId: staffMemberId,
    kind: kind,
    installments: installments,
    reason: reason,
    reasonDetail: reasonDetail,
    firstMonth: month,
  );

  @override
  List<Object?> get props => [
    staffMemberId,
    kind,
    installments,
    reason,
    reasonDetail,
    firstMonth,
  ];
}
