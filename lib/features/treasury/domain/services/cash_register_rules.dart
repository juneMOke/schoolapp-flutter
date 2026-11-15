import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Les règles de la configuration des caisses (R13, R14), sans Flutter. Le
/// serveur applique les mêmes et fait foi ; l'écran s'en sert pour activer ou
/// désactiver ses boutons sans attendre.
abstract final class CashRegisterRules {
  /// Longueur minimale d'un motif d'ajustement, espaces retirés.
  static const int minReasonLength = 5;

  /// Une caisse « Nouvelle » a été créée il y a moins de 7 jours.
  static const Duration newRegisterWindow = Duration(days: 7);

  /// Les devises qui n'ont pas encore leur caisse (v1 : une par devise).
  static List<TreasuryCurrency> availableCurrencies(
    Iterable<CashRegister> existing,
  ) {
    final taken = {for (final register in existing) register.currency};
    return [
      for (final currency in TreasuryCurrency.values)
        if (!taken.contains(currency)) currency,
    ];
  }

  static bool canCreateRegister(
    TreasuryCurrency currency,
    Iterable<CashRegister> existing,
  ) => availableCurrencies(existing).contains(currency);

  /// Le nom donné par le serveur à une caisse créée sans nom.
  static String defaultName(TreasuryCurrency currency) =>
      'Caisse ${currency.code}';

  /// Un autre nom de caisse identique, sans tenir compte de la casse.
  static bool isDuplicateName(String name, Iterable<CashRegister> existing) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return false;
    return existing.any(
      (register) => register.name.trim().toLowerCase() == wanted,
    );
  }

  static bool isReasonValid(String reason) =>
      reason.trim().length >= minReasonLength;

  /// R14 : un nouveau montant différent de l'actuel, un motif suffisant, une
  /// caisse pas encore clôturée aujourd'hui, et un franc entier en CDF.
  static bool canAdjust({
    required TreasuryCurrency currency,
    required int currentInCents,
    required int? newAmountInCents,
    required String reason,
    required bool closedToday,
  }) =>
      !closedToday &&
      newAmountInCents != null &&
      newAmountInCents >= 0 &&
      newAmountInCents != currentInCents &&
      currency.acceptsCents(newAmountInCents) &&
      isReasonValid(reason);

  static bool isNew(CashRegister register, DateTime now) =>
      now.difference(register.inServiceAt) < newRegisterWindow;
}
