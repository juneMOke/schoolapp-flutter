import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';

/// Un choix du frais classé (bloc D) : un classement (frais, devise) du
/// serveur, avec le libellé du frais tel que l'école le nomme.
class RecoveryRankingOption {
  /// La valeur du choix, celle que l'adresse retient : le code du frais s'il
  /// n'apparaît qu'en une devise, sinon `code|devise` (cf. [valueOf]).
  final String value;
  final String feeLabel;
  final RecoveryClassRanking ranking;

  const RecoveryRankingOption({
    required this.value,
    required this.feeLabel,
    required this.ranking,
  });

  String get feeCode => ranking.feeCode;
  String get currency => ranking.currency;
}

/// Les frais retenus que le bloc D peut classer, dans l'ordre du serveur.
///
/// **Un même frais facturé en deux devises donne deux choix** : chaque devise
/// se classe à part, jamais additionnée. La valeur reste le simple code tant
/// que le frais n'a qu'une devise — l'adresse d'avant ne change pas — et
/// devient `code|devise` sinon, pour que les deux choix restent distincts.
abstract final class RecoveryRankingOptions {
  static const separator = '|';

  static List<RecoveryRankingOption> of(RecoveryDashboard dashboard) {
    final perCode = <String, int>{};
    for (final r in dashboard.classRankings) {
      perCode[r.feeCode] = (perCode[r.feeCode] ?? 0) + 1;
    }
    return [
      for (final r in dashboard.classRankings)
        RecoveryRankingOption(
          value: valueOf(r, ambiguous: (perCode[r.feeCode] ?? 0) > 1),
          feeLabel: labelOf(dashboard, r.feeCode),
          ranking: r,
        ),
    ];
  }

  static String valueOf(RecoveryClassRanking r, {required bool ambiguous}) =>
      ambiguous ? '${r.feeCode}$separator${r.currency}' : r.feeCode;

  /// Le libellé du serveur : le catalogue des frais, sinon la ligne du taux
  /// par frais, sinon le code (jamais vide).
  static String labelOf(RecoveryDashboard dashboard, String feeCode) {
    for (final fee in dashboard.fees) {
      if (fee.code == feeCode && fee.label.trim().isNotEmpty) return fee.label;
    }
    for (final rate in dashboard.feeRates) {
      if (rate.feeCode == feeCode && rate.label.trim().isNotEmpty) {
        return rate.label;
      }
    }
    return feeCode;
  }

  /// Le choix de [value] ; une valeur inconnue (frais décoché, adresse
  /// ancienne) ou le seul code d'un frais en deux devises retombent sur le
  /// premier choix qui convient. `null` sans aucun classement.
  static RecoveryRankingOption? resolve(
    List<RecoveryRankingOption> options,
    String value,
  ) {
    if (options.isEmpty) return null;
    for (final o in options) {
      if (o.value == value) return o;
    }
    final code = value.split(separator).first;
    for (final o in options) {
      if (o.feeCode == code) return o;
    }
    return options.first;
  }
}
