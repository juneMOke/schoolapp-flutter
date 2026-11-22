import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// Le décodage des réponses du Recouvrement v2 (`/finance-stats/recovery/…`).
///
/// Lit le JSON **tel que le serveur l'a envoyé** — c'est aussi ce que garde le
/// cache hors ligne : une seule lecture, pas d'aller-retour par un modèle
/// intermédiaire qui pourrait perdre un champ. Un champ requis absent ou du
/// mauvais type lève une [FormatException] : mieux vaut « erreur » qu'un
/// tableau de bord à zéro.
abstract final class RecoveryDashboardWire {
  static RecoveryDashboard dashboardFromJson(Object? json) {
    final m = _map(json, 'dashboard');
    final sim = _map(m['simulation'], 'simulation');
    final rules = _map(m['ruleCounts'], 'ruleCounts');
    return RecoveryDashboard(
      situationAt: _date(m['situationAt']),
      academicYear: _str(m['academicYear']),
      pendingWrites: _int(m['pendingWrites']),
      perimeterLabel: m['perimeterLabel'] as String?,
      fees: [for (final f in _list(m['fees'])) _fee(f)],
      currencies: _strings(m['currencies']),
      atLeastAvailable: m['atLeastAvailable'] as bool,
      studentCount: _int(m['studentCount']),
      keyFigures: [for (final f in _list(m['keyFigures'])) _figures(f)],
      situations: situationsFromJson(m['situations']),
      feeRates: [for (final r in _list(m['feeRates'])) _feeRate(r)],
      classRankings: [for (final r in _list(m['classRankings'])) _ranking(r)],
      ruleCounts: RecoveryRuleCounts(
        somePayment: _int(rules['SOME_PAYMENT']),
        fullySettled: _int(rules['FULLY_SETTLED']),
        atLeast: (rules['AT_LEAST'] as num?)?.toInt(),
      ),
      simulation: RecoverySimulation(
        rows: [for (final r in _list(sim['rows'])) _simRow(r)],
        headcount: _int(sim['headcount']),
        targetedStudents: _int(sim['targetedStudents']),
        remainingHeadcount: _int(sim['remainingHeadcount']),
        lostCollected: _moneys(sim['lostCollected']),
        abandonedOutstanding: _moneys(sim['abandonedOutstanding']),
      ),
    );
  }

  static RecoveryStudentsPage studentsFromJson(Object? json) {
    final m = _map(json, 'students');
    final counts = _map(m['counts'], 'counts');
    return RecoveryStudentsPage(
      situationAt: _date(m['situationAt']),
      pendingWrites: _int(m['pendingWrites']),
      title: _str(m['title']),
      perimeterLabel: m['perimeterLabel'] as String?,
      currencies: _strings(m['currencies']),
      atLeastAvailable: m['atLeastAvailable'] as bool,
      counts: RecoveryTabCounts(
        toChase: _int(counts['TO_CHASE']),
        inOrder: _int(counts['IN_ORDER']),
        all: _int(counts['ALL']),
      ),
      situationCounts: situationsFromJson(m['situationCounts']),
      content: [for (final r in _list(m['content'])) _student(r)],
      page: _int(m['page']),
      size: _int(m['size']),
      totalElements: _int(m['totalElements']),
      totalPages: _int(m['totalPages']),
    );
  }

  static RecoverySituationCounts situationsFromJson(Object? json) {
    final m = _map(json, 'situations');
    return RecoverySituationCounts(
      noPayment: _int(m['NO_PAYMENT']),
      partial: _int(m['PARTIAL']),
      settled: _int(m['SETTLED']),
    );
  }

  /// `NO_PAYMENT` · `PARTIAL` · `SETTLED`, le vocabulaire du serveur.
  static StudentChargeStatus situationFromWire(String wire) => switch (wire) {
    'NO_PAYMENT' => StudentChargeStatus.due,
    'PARTIAL' => StudentChargeStatus.partial,
    'SETTLED' => StudentChargeStatus.paid,
    _ => throw FormatException('Situation inconnue : $wire'),
  };

  static String situationToWire(StudentChargeStatus status) => switch (status) {
    StudentChargeStatus.due => 'NO_PAYMENT',
    StudentChargeStatus.partial => 'PARTIAL',
    StudentChargeStatus.paid => 'SETTLED',
  };

  static RecoveryFee _fee(Object? json) {
    final m = _map(json, 'fee');
    return RecoveryFee(
      code: _str(m['code']),
      label: _str(m['label']),
      currencies: _strings(m['currencies']),
      sortOrder: _int(m['sortOrder']),
    );
  }

  static RecoveryFigures _figures(Object? json) {
    final m = _map(json, 'figures');
    return RecoveryFigures(
      currency: _str(m['currency']),
      dueInCents: _int(m['dueInCents']),
      paidInCents: _int(m['paidInCents']),
      outstandingInCents: _int(m['outstandingInCents']),
      ratePercent: (m['ratePercent'] as num?)?.toInt(),
    );
  }

  static RecoveryFeeRate _feeRate(Object? json) {
    final m = _map(json, 'feeRate');
    return RecoveryFeeRate(
      feeCode: _str(m['feeCode']),
      label: _str(m['label']),
      figures: _figures(m),
      billedStudents: _int(m['billedStudents']),
    );
  }

  static RecoveryClassRanking _ranking(Object? json) {
    final m = _map(json, 'ranking');
    final currency = _str(m['currency']);
    final unassigned = m['unassigned'];
    return RecoveryClassRanking(
      feeCode: _str(m['feeCode']),
      currency: currency,
      ranked: [for (final r in _list(m['ranked'])) _classRow(r, currency)],
      unassigned: unassigned == null ? null : _classRow(unassigned, currency),
    );
  }

  static RecoveryClassFeeRow _classRow(Object? json, String currency) {
    final m = _map(json, 'classRow');
    return RecoveryClassFeeRow(
      classroomId: m['classroomId'] as String?,
      classroomName: _str(m['classroomName']),
      cycleName: m['cycleName'] as String?,
      billedStudents: _int(m['billedStudents']),
      settledStudents: _int(m['settledStudents']),
      noPaymentStudents: _int(m['noPaymentStudents']),
      due: Money.parse(_int(m['dueInCents']), currency),
      outstanding: Money.parse(_int(m['outstandingInCents']), currency),
      ratePercent: (m['ratePercent'] as num?)?.toInt(),
    );
  }

  static RecoverySimulationRow _simRow(Object? json) {
    final m = _map(json, 'simulationRow');
    return RecoverySimulationRow(
      classroomId: m['classroomId'] as String?,
      classroomName: _str(m['classroomName']),
      cycleName: m['cycleName'] as String?,
      headcount: _int(m['headcount']),
      billedStudents: _int(m['billedStudents']),
      targetedStudents: _int(m['targetedStudents']),
      remainingHeadcount: _int(m['remainingHeadcount']),
      lostCollected: _moneys(m['lostCollected']),
      abandonedOutstanding: _moneys(m['abandonedOutstanding']),
    );
  }

  static RecoveryStudentRow _student(Object? json) {
    final m = _map(json, 'student');
    return RecoveryStudentRow(
      studentId: _str(m['studentId']),
      displayName: _str(m['displayName']),
      matriculationNumber: m['matriculationNumber'] as String?,
      parentName: m['parentName'] as String?,
      classroomId: m['classroomId'] as String?,
      classroomName: m['classroomName'] as String?,
      due: _moneys(m['due']),
      paid: _moneys(m['paid']),
      outstanding: _moneys(m['outstanding']),
      situation: situationFromWire(_str(m['situation'])),
      inOrder: m['inOrder'] as bool,
    );
  }

  static List<Money> _moneys(Object? json) => [
    for (final e in _list(json))
      Money.parse(
        _int(_map(e, 'money')['amountInCents']),
        _str(_map(e, 'money')['currency']),
      ),
  ];

  static Map<String, dynamic> _map(Object? json, String what) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return json.cast<String, dynamic>();
    throw FormatException('Recouvrement : $what illisible.');
  }

  static List<Object?> _list(Object? json) =>
      json == null ? const [] : (json as List).cast<Object?>();

  static List<String> _strings(Object? json) => [
    for (final e in _list(json)) e as String,
  ];

  static String _str(Object? json) {
    if (json is String) return json;
    throw const FormatException('Recouvrement : texte attendu.');
  }

  static int _int(Object? json) {
    if (json is num) return json.toInt();
    throw const FormatException('Recouvrement : nombre attendu.');
  }

  static DateTime _date(Object? json) => DateTime.parse(_str(json)).toLocal();
}
