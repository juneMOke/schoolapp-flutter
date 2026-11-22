import 'dart:convert';
import 'dart:io';

import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_wire.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// Les données de démonstration de la spec v2 (478 élèves, 13 classes,
/// « Frais de scolarité » : attendu 130 920 $, perçu 36 123 $, 315 · 59 · 104),
/// au format du contrat L0 — décodées par le vrai décodeur.
const _dir = 'test/features/recouvrement/fixtures';

Map<String, dynamic> recoveryDashboardJson() =>
    jsonDecode(File('$_dir/recovery_dashboard.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> recoveryStudentsJson() =>
    jsonDecode(File('$_dir/recovery_students.json').readAsStringSync())
        as Map<String, dynamic>;

RecoveryDashboard recoveryDashboardFixture() =>
    RecoveryDashboardWire.dashboardFromJson(recoveryDashboardJson());

RecoveryStudentsPage recoveryStudentsFixture() =>
    RecoveryDashboardWire.studentsFromJson(recoveryStudentsJson());

/// La même réponse, en sélection mixte (inscription en francs cochée aussi) :
/// deux devises, pas d'anneau, « a payé au moins » indisponible.
RecoveryDashboard recoveryMixedDashboardFixture() {
  final json = recoveryDashboardJson();
  json['currencies'] = ['CDF', 'USD'];
  json['atLeastAvailable'] = false;
  json['keyFigures'] = [
    {
      'currency': 'CDF',
      'dueInCents': 221500000,
      'paidInCents': 97500000,
      'outstandingInCents': 124000000,
      'ratePercent': 44,
    },
    ...(json['keyFigures'] as List),
  ];
  json['feeRates'] = [
    {
      'feeCode': 'REGISTRATION',
      'label': "Frais d'inscription",
      'currency': 'CDF',
      'dueInCents': 221500000,
      'paidInCents': 97500000,
      'outstandingInCents': 124000000,
      'ratePercent': 44,
      'billedStudents': 478,
    },
    ...(json['feeRates'] as List),
  ];
  (json['ruleCounts'] as Map)['AT_LEAST'] = null;
  return RecoveryDashboardWire.dashboardFromJson(json);
}
