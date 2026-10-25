import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Les briques communes aux réponses des statistiques de présence.
///
/// Strict sur ce qui fait les chiffres : un compteur manquant fait échouer la
/// lecture plutôt que d'afficher un zéro qui n'a pas été compté. Tolérant sur
/// les valeurs fermées : une catégorie ou un profil inconnu ne rend pas la
/// réponse illisible.
abstract final class HrAttendanceJson {
  static Map<String, dynamic> map(Object? json) => json as Map<String, dynamic>;

  static List<Map<String, dynamic>> list(Object? json) => [
    for (final item in json as List<dynamic>) map(item),
  ];

  /// Un compteur : présent et entier.
  static int count(Map<String, dynamic> json, String key) =>
      (json[key] as num).toInt();

  /// Un taux en % : `null` quand rien n'est pointé.
  static int? rate(Map<String, dynamic> json, String key) =>
      (json[key] as num?)?.toInt();

  static PresenceProfile profile(Map<String, dynamic> json) =>
      PresenceProfile.fromWire(json['profile'] as String?);

  /// L'identité d'un agent — à plat dans les lignes de liste, sous `agent`
  /// dans les réponses d'un seul agent : la même lecture sert les deux.
  static HrAttendanceAgent agent(Map<String, dynamic> json) =>
      HrAttendanceAgent(
        staffMemberId: json['staffMemberId'] as String,
        staffNumber: json['staffNumber'] as String,
        lastName: json['lastName'] as String,
        middleName: json['middleName'] as String?,
        firstName: json['firstName'] as String?,
        jobTitle: json['jobTitle'] as String?,
        category: StaffCategory.fromWire(json['category'] as String?),
        contractKind: StaffContractKind.fromWire(
          json['contractKind'] as String?,
        ),
        payMode: StaffPayMode.fromWire(json['payMode'] as String?),
      );

  /// Les compteurs — à plat dans une ligne d'agent, sous `kpis` ailleurs.
  static HrAttendanceKpis kpis(Map<String, dynamic> json) => HrAttendanceKpis(
    scored: count(json, 'scored'),
    presences: count(json, 'presences'),
    presenceRatePct: rate(json, 'presenceRatePct'),
    absenceRatePct: rate(json, 'absenceRatePct'),
    late: count(json, 'late'),
    lateRatePct: rate(json, 'lateRatePct'),
    lateMinutes: count(json, 'lateMinutes'),
    punctualityPct: rate(json, 'punctualityPct'),
    justifiedAbsences: count(json, 'justifiedAbsences'),
    unjustifiedAbsences: count(json, 'unjustifiedAbsences'),
    unscored: count(json, 'unscored'),
    workedMinutes: count(json, 'workedMinutes'),
  );

  /// `{currency, amountInCents}`, ou `null`.
  static Money? money(Object? json) {
    if (json == null) return null;
    final value = map(json);
    return Money.parse(
      count(value, 'amountInCents'),
      value['currency'] as String,
    );
  }
}
