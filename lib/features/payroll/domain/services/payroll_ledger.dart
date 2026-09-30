import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_phase_resolver.dart';

/// Compose le livre d'un mois à partir de ce que la tablette sait : les lignes
/// figées d'une paie validée, sinon le calcul du moteur.
abstract final class PayrollLedger {
  static PayrollMonthView monthView(PayrollSnapshot snapshot, String month) {
    final header = snapshot.headers[month];
    final server = header?.status ?? PayrollStatus.draft;
    final gestures = gesturesOf(snapshot, month);
    final frozen = snapshot.frozenLines[month];
    final computation = server == PayrollStatus.validated && frozen != null
        ? null
        : PayrollEngine.compute(inputOf(snapshot, month));
    final lines = frozen ?? computation?.lines ?? const <PayrollLine>[];
    final disbursements = liveDisbursements(snapshot, month);
    final payable = lines.where((line) => line.netInCents > 0);
    final allPaid =
        payable.isNotEmpty &&
        payable.every((line) => disbursements.containsKey(line.staffMemberId));
    final phase = PayrollPhaseResolver.resolve(
      server: server,
      monthGestures: gestures,
      allPaid: allPaid,
    );
    final attendanceMonth = PayrollMonth.previous(month);
    final attendance = PayrollAttendanceRule.stateOf(
      month: attendanceMonth,
      hasSummary: snapshot.summaries.containsKey(attendanceMonth),
      years: snapshot.schoolYears,
    );
    return PayrollMonthView(
      month: month,
      header: header,
      phase: phase,
      lines: lines,
      totals: PayrollFingerprinter.totalsOf(
        PayrollFingerprinter.digestLines(lines),
      ),
      disbursements: disbursements,
      withoutContract: computation?.withoutContract ?? const [],
      zeroHourMembers: [
        for (final line in lines)
          if (line.isHourly && (line.baseMinutes ?? 0) == 0) line.staffMemberId,
      ],
      attendance: attendance,
      awaitingFrozenLines: server == PayrollStatus.validated && frozen == null,
      lastRefusal: _lastRefusal(gestures),
      submitBlocker: _submitBlocker(snapshot, month),
      validateBlocker: attendance == PayrollAttendanceState.open
          ? PayrollBlocker.attendanceOpen
          : null,
      reopenBlocker: _hasAnyDisbursement(snapshot, month)
          ? PayrollBlocker.hasDisbursements
          : null,
    );
  }

  /// L'historique : les mois tenus et le mois en cours, du plus récent au
  /// plus ancien — composé une fois par lecture, pas à chaque rendu.
  static List<PayrollMonthView> history(
    PayrollSnapshot snapshot,
    String currentMonth,
  ) {
    final months = {...snapshot.headers.keys, currentMonth}.toList()
      ..sort((a, b) => b.compareTo(a));
    return [for (final month in months) monthView(snapshot, month)];
  }

  /// Ce que le moteur lit pour [month].
  static PayrollEngineInput inputOf(PayrollSnapshot snapshot, String month) =>
      PayrollEngineInput(
        month: month,
        settings: snapshot.settings,
        contractsByMember: {
          for (final member in snapshot.members)
            member.id: snapshot.contractsByMember[member.id] ?? const [],
        },
        variables: snapshot.variables[month] ?? const {},
        profiles: snapshot.profiles,
        attendance: snapshot.summaries[PayrollMonth.previous(month)],
        advances: snapshot.advances,
        priorLines: [
          for (final entry in snapshot.frozenLines.entries)
            if (entry.key.compareTo(month) < 0 &&
                snapshot.headers[entry.key]?.status == PayrollStatus.validated)
              ...entry.value,
        ],
      );

  /// La ligne qu'aurait [variables] — l'aperçu en direct des éléments
  /// variables, par le même moteur.
  static PayrollLine? previewLine(
    PayrollSnapshot snapshot,
    String month,
    PayrollVariables variables,
  ) {
    final input = inputOf(snapshot, month);
    final lines = PayrollEngine.compute(
      PayrollEngineInput(
        month: month,
        settings: input.settings,
        contractsByMember: {
          variables.staffMemberId:
              input.contractsByMember[variables.staffMemberId] ?? const [],
        },
        variables: {variables.staffMemberId: variables},
        profiles: input.profiles,
        attendance: input.attendance,
        advances: input.advances,
        priorLines: input.priorLines,
      ),
    ).lines;
    return lines.isEmpty ? null : lines.single;
  }

  static List<PayrollGesture> gesturesOf(
    PayrollSnapshot snapshot,
    String month,
  ) => [
    for (final gesture in snapshot.gestures)
      if (gesture.month == month) gesture,
  ];

  /// Le versement vivant — ou encore en file — de chaque agent pour [month].
  /// Un versement refusé n'en est pas un : il va « à régulariser ».
  static Map<String, PayrollDisbursement> liveDisbursements(
    PayrollSnapshot snapshot,
    String month,
  ) => {
    for (final disbursement in snapshot.disbursements)
      if (disbursement.month == month && disbursement.isLive)
        disbursement.staffMemberId: disbursement,
  };

  /// Les versements refusés, tous mois confondus : l'argent est parti.
  static List<PayrollDisbursement> toRegularize(PayrollSnapshot snapshot) => [
    for (final disbursement in snapshot.disbursements)
      if (disbursement.needsRegularization && !disbursement.isCancelled)
        disbursement,
  ];

  /// La paie précédente, si elle existe, doit être validée, **figée** sur la
  /// tablette (ses retenues comptent dans ce mois-ci), et sans geste en vol
  /// (une réouverture partie d'ailleurs la rendrait brouillon).
  static PayrollBlocker? _submitBlocker(
    PayrollSnapshot snapshot,
    String month,
  ) {
    final previousMonth = PayrollMonth.previous(month);
    final previous = snapshot.headers[previousMonth];
    if (previous == null) return null;
    final settled =
        previous.status == PayrollStatus.validated &&
        snapshot.frozenLines.containsKey(previousMonth) &&
        !gesturesOf(snapshot, previousMonth).any((g) => g.isInFlight);
    return settled ? null : PayrollBlocker.previousNotValidated;
  }

  /// Le dernier refus du mois — sauf si le serveur a enregistré depuis un
  /// geste plus récent (fait sur un autre poste) : le refus est alors dépassé.
  /// Comparé en instants, jamais sur l'ordre local, que l'horloge de la
  /// tablette fausserait.
  static PayrollGesture? _lastRefusal(List<PayrollGesture> gestures) {
    PayrollGesture? refusal;
    for (final gesture in gestures) {
      if (gesture.isRefused) refusal = gesture;
    }
    if (refusal == null) return null;
    final refusedAt = DateTime.tryParse(refusal.recordedAt);
    final overtaken = gestures.any((gesture) {
      if (gesture.isRefused || gesture.isInFlight) return false;
      final at = DateTime.tryParse(gesture.recordedAt);
      return at != null && refusedAt != null && at.isAfter(refusedAt);
    });
    return overtaken ? null : refusal;
  }

  static bool _hasAnyDisbursement(PayrollSnapshot snapshot, String month) =>
      snapshot.disbursements.any(
        (disbursement) =>
            disbursement.month == month &&
            !disbursement.isCancelled &&
            !disbursement.needsRegularization,
      );
}
