import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';

/// Où en est une paie **à l'écran** : le statut serveur, plus le geste de
/// cette tablette qui n'est pas encore accusé. « Validée » ne s'affiche jamais
/// sur la foi du poste.
enum PayrollPhase {
  draft,
  submitting,
  submitted,
  returning,
  validating,
  validated,
  reopening,

  /// Validée, et tous les nets non nuls versés — dérivé, jamais stocké.
  paid;

  bool get inFlight =>
      this == submitting ||
      this == returning ||
      this == validating ||
      this == reopening;

  /// Les montants sont figés (validée, versée, ou en cours de réouverture).
  bool get isLocked => this == validated || this == paid || this == reopening;
}

/// Pourquoi la paie ne peut pas être soumise ou validée maintenant.
enum PayrollBlocker {
  /// La paie du mois précédent existe et n'est pas validée (E9).
  previousNotValidated,

  /// Le Pointage de M−1 n'est pas clos (A1, A9).
  attendanceOpen,

  /// Aucun agent au livre.
  emptyLedger,

  /// Un versement vivant existe : la paie ne se rouvre plus (A4).
  hasDisbursements,
}

/// Le livre d'un mois, prêt pour l'écran.
class PayrollMonthView {
  /// `YYYY-MM`.
  final String month;
  final PayrollHeader? header;
  final PayrollPhase phase;

  /// Calculées tant que la paie n'est pas validée, figées ensuite.
  final List<PayrollLine> lines;
  final List<PayrollTotal> totals;

  /// Le versement vivant (ou en file) de chaque agent.
  final Map<String, PayrollDisbursement> disbursements;

  /// Les agents sans aucun contrat : « contrat à poser ».
  final List<String> withoutContract;

  /// Les vacataires à l'heure sans minute pointée en M−1 (N4).
  final List<String> zeroHourMembers;
  final PayrollAttendanceState attendance;

  /// Le dernier geste du mois, s'il a été refusé (confrontation, motif).
  final PayrollGesture? lastRefusal;
  final PayrollBlocker? submitBlocker;
  final PayrollBlocker? validateBlocker;
  final PayrollBlocker? reopenBlocker;

  const PayrollMonthView({
    required this.month,
    required this.header,
    required this.phase,
    required this.lines,
    required this.totals,
    required this.disbursements,
    required this.withoutContract,
    required this.zeroHourMembers,
    required this.attendance,
    this.lastRefusal,
    this.submitBlocker,
    this.validateBlocker,
    this.reopenBlocker,
  });

  bool get isEditable => phase == PayrollPhase.draft;

  bool get canPay =>
      (phase == PayrollPhase.validated || phase == PayrollPhase.paid) &&
      header?.validationGestureId != null;

  /// Les lignes qui ont un net à verser.
  Iterable<PayrollLine> get payable =>
      lines.where((line) => line.netInCents > 0);

  int get paidCount =>
      payable.where((line) => disbursements[line.staffMemberId] != null).length;

  int get remainingCount => payable.length - paidCount;

  PayrollLine? line(String staffMemberId) {
    for (final line in lines) {
      if (line.staffMemberId == staffMemberId) return line;
    }
    return null;
  }
}
