import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'ordre dans lequel les caisses se présentent — **les dollars d'abord**.
///
/// Le serveur ordonne par code de devise, donc `CDF` avant `USD`. L'écran
/// inverse, et ce n'est pas une préférence esthétique : la position d'une caisse
/// doit être **stable d'un jour à l'autre**. Un ordre qui suivrait l'activité
/// ferait lire un franc pour un dollar au lecteur qui a mémorisé « le dollar est
/// à gauche », le premier jour où les francs passent devant.
///
/// Toute devise hors de cette liste garde le rang du serveur, **à la suite** :
/// le modèle en admet une troisième, et la faire disparaître serait pire que la
/// placer arbitrairement.
const List<String> tillPreferredCurrencyOrder = ['USD', 'CDF'];

/// Les blocs, réordonnés pour l'affichage. L'ordre du serveur est conservé dans
/// le modèle : c'est la **présentation** qui décide de la place, pas la lecture.
List<TillCurrencyBlock> tillBlocksInDisplayOrder(
  List<TillCurrencyBlock> blocks,
) {
  final ordered = <TillCurrencyBlock>[];
  for (final currency in tillPreferredCurrencyOrder) {
    ordered.addAll(blocks.where((block) => block.currency == currency));
  }
  ordered.addAll(
    blocks.where(
      (block) => !tillPreferredCurrencyOrder.contains(block.currency),
    ),
  );
  return ordered;
}

/// La caisse à détailler, une fois la réponse arrivée.
///
/// Trois règles, dans cet ordre :
///
/// 1. **La sélection en cours est conservée** si la nouvelle fenêtre la porte
///    encore — changer de période ne doit pas ramener le lecteur sur une autre
///    caisse que celle qu'il examinait.
/// 2. Sinon **le dollar**, jamais « la plus active » : un défaut qui suivrait
///    l'activité changerait de segment d'un jour à l'autre, et le clic
///    machinal du caissier tomberait sur l'autre caisse.
/// 3. Sinon la première dans l'ordre d'affichage — une école qui ne tient pas
///    de caisse en dollars doit tout de même en voir une sélectionnée.
///
/// `null` quand aucun bloc n'existe : il n'y a alors pas de caisse à détailler,
/// et c'est l'état vide global qui parle.
String? resolveSelectedTillCurrency(
  String? current,
  List<TillCurrencyBlock> blocks,
) {
  if (blocks.isEmpty) return null;

  final codes = blocks.map((block) => block.currency).toSet();
  if (current != null && codes.contains(current)) return current;
  if (codes.contains('USD')) return 'USD';

  return tillBlocksInDisplayOrder(blocks).first.currency;
}

/// La teinte d'une caisse.
///
/// **Elle repère, elle n'informe pas** : partout où elle apparaît, le symbole de
/// la devise l'accompagne. Une couleur ne porte jamais seule l'information de
/// devise — c'est le contrat d'accessibilité propre à cet écran.
///
/// Une devise inconnue prend le gris du texte plutôt qu'une couleur inventée :
/// une teinte choisie au hasard se lirait comme une troisième catégorie.
Color tillCurrencyAccent(String currency) => switch (currency) {
  'USD' => AppColors.bleuArdoise,
  'CDF' => AppColors.vertSavane,
  _ => AppColors.textSecondary,
};

/// Le fond du médaillon d'une caisse — la teinte douce qui accompagne
/// [tillCurrencyAccent].
///
/// Même règle : elle repère, elle n'informe pas. Une devise inconnue prend le
/// fond neutre plutôt qu'une couleur inventée.
Color tillCurrencySoftAccent(String currency) => switch (currency) {
  'USD' => AppColors.bleuArdoiseSoft,
  'CDF' => AppColors.feeStatusPaidSoft,
  _ => AppColors.surfaceAlt,
};

/// « dollars », « francs » — et le **code lui-même** pour toute autre devise.
///
/// Un générique (« devise étrangère ») ne désignerait rien ; le code, lui, est
/// exact et se retrouve sur le reçu.
String tillCurrencyName(String currency, AppLocalizations l10n) =>
    switch (currency) {
      'USD' => l10n.financeTillCurrencyNameUsd,
      'CDF' => l10n.financeTillCurrencyNameCdf,
      _ => currency,
    };
