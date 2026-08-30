import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';

/// La mise en forme d'un montant — **une seule règle, pour toutes les
/// surfaces**.
///
/// ## Les décimales se décident sur la devise, pas sur la valeur
///
/// Le centime de franc ne circule pas : on écrit `90 000 FC`, jamais
/// `90 000,00 FC`. Le cent de dollar, lui, circule : on écrit `425,00 $`,
/// jamais `425 $`.
///
/// C'est **l'inverse** de la règle qui régnait ici : le front décidait les
/// décimales sur la valeur — deux si le montant en portait, zéro sinon — et
/// écrivait donc `425 USD` là où il fallait `425,00 $`, et `90 000,00 CDF` là
/// où il fallait `90 000 FC`.
///
/// La valeur garde un droit : elle peut **rajouter** des décimales, jamais en
/// retirer. Un franc qui en porterait réellement s'écrit `90 000,50 FC` — une
/// convention d'écriture ne doit jamais arrondir sous les yeux du lecteur.
///
/// ## Pourquoi tout passe par ici
///
/// Quatre mises en forme coexistaient : celle du socle, celle de la boutique,
/// celle du ticket thermique et celle de la configuration. Un même montant
/// s'écrivait de quatre façons selon l'écran, et une seule des quatre savait
/// que `CDF` s'écrit « FC ». Elles sont devenues des façades sur cette classe.
abstract final class MoneyFormat {
  /// Espace insécable — le séparateur de milliers partout dans l'application.
  static const String nbsp = '\u00A0';

  /// Espace ordinaire, pour le **ticket thermique** : une imprimante ESC/POS ne
  /// rend pas l'insécable.
  static const String thermalSpace = ' ';

  /// Décimales dues à une devise, indépendamment du montant.
  ///
  /// Le franc congolais n'en a aucune ; tout le reste en a deux, y compris une
  /// devise qu'on ne connaîtrait pas encore — un défaut à deux décimales
  /// n'invente pas d'argent, un défaut à zéro en escamoterait.
  static int decimalsOf(String currency) =>
      CurrencyCode.normalize(currency) == CurrencyCode.cdf ? 0 : 2;

  /// L'abréviation d'usage d'une devise.
  ///
  /// Le code ISO circule sur le fil ; c'est l'abréviation qui s'affiche. Une
  /// devise inconnue garde son code : inventer un symbole ferait lire autre
  /// chose que ce que l'école écrit.
  static String symbolOf(String currency) {
    final code = CurrencyCode.normalize(currency);
    return switch (code) {
      CurrencyCode.usd => r'$',
      CurrencyCode.cdf => 'FC',
      CurrencyCode.eur => '€',
      _ => code,
    };
  }

  /// Le montant **avec** son abréviation : « 425,00 $ », « 90 000 FC ».
  ///
  /// Une devise vide — état réel du grand-livre local — ne produit aucun
  /// suffixe plutôt qu'un espace orphelin.
  static String format(Money amount, {String space = nbsp}) {
    final number = amountOnly(amount, space: space);
    final symbol = symbolOf(amount.currency);
    return symbol.isEmpty ? number : '$number$space$symbol';
  }

  /// Le montant **sans** son abréviation, pour les surfaces qui portent la
  /// devise ailleurs (un en-tête de colonne, un intitulé de bloc).
  static String amountOnly(Money amount, {String space = nbsp}) {
    final negative = amount.amountInCents < 0;
    final absolute = negative ? -amount.amountInCents : amount.amountInCents;
    final decimals = absolute % 100 == 0 ? decimalsOf(amount.currency) : 2;
    return _compose(absolute, decimals, negative, space);
  }

  /// « 10 $ » — la forme abrégée des cartes de catalogue, où l'on parcourt du
  /// regard plutôt qu'on ne recompte.
  ///
  /// Les décimales tombent **quand le montant n'en porte pas**, dans toutes les
  /// devises. Celles d'un montant qui en porte réellement ne sont jamais
  /// escamotées : un article à 10,50 $ affiché « 10 $ » ferait recompter le
  /// ticket au client.
  static String compact(Money amount, {String space = nbsp}) {
    final negative = amount.amountInCents < 0;
    final absolute = negative ? -amount.amountInCents : amount.amountInCents;
    final number = _compose(
      absolute,
      absolute % 100 == 0 ? 0 : 2,
      negative,
      space,
    );
    final symbol = symbolOf(amount.currency);
    return symbol.isEmpty ? number : '$number$space$symbol';
  }

  static String _compose(
    int absoluteCents,
    int decimals,
    bool negative,
    String space,
  ) {
    final sign = negative ? '-' : '';
    final units = _group((absoluteCents ~/ 100).toString(), space);
    if (decimals == 0) return '$sign$units';
    final fraction = (absoluteCents % 100).toString().padLeft(2, '0');
    return '$sign$units,$fraction';
  }

  static String _group(String units, String space) {
    final buffer = StringBuffer();
    for (var i = 0; i < units.length; i++) {
      if (i > 0 && (units.length - i) % 3 == 0) buffer.write(space);
      buffer.write(units[i]);
    }
    return buffer.toString();
  }
}
