import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Lecture et écriture des corps JSON de la trésorerie (contrat PR back #222).
///
/// Une ligne illisible lève une [FormatException] : `guardOnline` la rend en
/// échec serveur, et l'écran ne reste jamais en chargement sur un chiffre qu'il
/// aurait inventé.
abstract final class TreasuryWire {
  static List<RegisterConfig> registerConfigsFromJson(Object? body) =>
      _list(body).map(registerConfigFromJson).toList(growable: false);

  static RegisterConfig registerConfigFromJson(Map<String, dynamic> json) {
    final closure = json['todayClosure'];
    return RegisterConfig(
      register: registerFromJson(_map(json['register'])),
      balanceInCents: _int(json, 'balanceInCents'),
      todayClosure: closure == null ? null : _closureFromJson(_map(closure)),
      adjustmentsCount: (json['adjustmentsCount'] as num?)?.toInt() ?? 0,
      last8Days: [
        for (final day in (json['last8Days'] as List?) ?? const [])
          DayBalance(
            day: _date(_map(day), 'day'),
            balanceInCents: _int(_map(day), 'balanceInCents'),
            closed: _map(day)['closed'] == true,
          ),
      ],
    );
  }

  static CashRegister registerFromJson(Object? body) {
    final json = _map(body);
    final currency = TreasuryCurrency.fromCode(json['currency'] as String?);
    if (currency == null) {
      throw FormatException('Devise de caisse inconnue : ${json['currency']}');
    }
    return CashRegister(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      currency: currency,
      inServiceAt: _instant(json, 'inServiceAt'),
      inServiceOn: _date(json, 'inServiceOn'),
      openingAmountInCents: _int(json, 'openingAmountInCents'),
    );
  }

  static List<CashAdjustment> adjustmentsFromJson(Object? body) =>
      _list(body).map(adjustmentFromJson).toList(growable: false);

  static CashAdjustment adjustmentFromJson(Object? body) {
    final json = _map(body);
    return CashAdjustment(
      id: _string(json, 'id'),
      number: _string(json, 'number'),
      registerId: _string(json, 'registerId'),
      cashDay: _date(json, 'cashDay'),
      adjustedAt: _instant(json, 'adjustedAt'),
      previousExpectedInCents: _int(json, 'previousExpectedInCents'),
      newAmountInCents: _int(json, 'newAmountInCents'),
      deltaInCents: _int(json, 'deltaInCents'),
      reason: _string(json, 'reason'),
      createdByName: _string(json, 'createdByName'),
    );
  }

  /// `CashAdjustmentResponse` : l'ajustement et son mouvement. L'écran
  /// Configuration n'a besoin que du premier.
  static CashAdjustment adjustmentOfResponse(Object? body) =>
      adjustmentFromJson(_map(body)['adjustment']);

  static Map<String, dynamic> createRegisterToJson({
    required TreasuryCurrency currency,
    required String? name,
    required int openingAmountInCents,
  }) {
    final trimmed = name?.trim();
    return {
      if (trimmed != null && trimmed.isNotEmpty) 'name': trimmed,
      'currency': currency.code,
      'openingAmountInCents': openingAmountInCents,
    };
  }

  static Map<String, dynamic> adjustmentToJson({
    required String id,
    required int shownExpectedInCents,
    required int newAmountInCents,
    required String reason,
  }) => {
    'id': id,
    'shownExpectedInCents': shownExpectedInCents,
    'newAmountInCents': newAmountInCents,
    'reason': reason.trim(),
  };

  static TodayClosure _closureFromJson(Map<String, dynamic> json) =>
      TodayClosure(
        closedAt: _instant(json, 'closedAt'),
        expectedInCents: _int(json, 'expectedInCents'),
        declaredInCents: _int(json, 'declaredInCents'),
        gapInCents: _int(json, 'gapInCents'),
        reopened: json['reopenedAt'] != null,
      );

  static List<Map<String, dynamic>> _list(Object? body) {
    if (body is! List) throw const FormatException('Liste attendue');
    return body.map(_map).toList(growable: false);
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const FormatException('Objet attendu');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Champ $key manquant');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toInt();
    throw FormatException('Montant $key manquant');
  }

  /// Un instant UTC du fil, gardé en UTC : c'est l'affichage qui le lit à
  /// l'heure de l'école.
  static DateTime _instant(Map<String, dynamic> json, String key) {
    final parsed = DateTime.tryParse(_string(json, key));
    if (parsed == null) throw FormatException('Instant $key illisible');
    return parsed.toUtc();
  }

  /// Une date de calendrier (`yyyy-MM-dd`), à minuit local, sans heure.
  static DateTime _date(Map<String, dynamic> json, String key) {
    final raw = _string(json, key);
    final parsed = DateTime.tryParse(
      raw.length >= 10 ? raw.substring(0, 10) : raw,
    );
    if (parsed == null) throw FormatException('Date $key illisible');
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
