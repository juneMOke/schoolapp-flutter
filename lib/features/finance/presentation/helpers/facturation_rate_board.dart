/// Les taux **corrigés à la main** au guichet, par paire de devises.
///
/// Lot R3 du chantier de refonte. Trois champs d'état vivaient dans la classe
/// `State` de la page d'encaissement — les contrôleurs, l'ensemble des boîtes
/// ouvertes, et les amorces — avec les trois méthodes qui les lisaient. Ils
/// forment en réalité un objet : *ce que le caissier a corrigé, et ce qu'il n'a
/// fait qu'ouvrir*.
///
/// ## L'amorce n'est pas une décoration
///
/// « Modifier » pré-remplit le champ avec le taux affiché. Sans mémoriser cette
/// valeur, on ne saurait plus distinguer « le caissier a ouvert le champ » de
/// « le caissier a corrigé le taux » : ouvrir sans rien taper appliquerait la
/// valeur affichée — arrondie au centième — à la place du taux du référentiel,
/// qui en porte six. Un geste sans intention changerait le montant encaissé.
///
/// ## Le rafraîchissement est injecté
///
/// Le tableau ne connaît ni widget ni `setState` : il reçoit un rappel et le
/// pose sur chaque contrôleur qu'il crée. Sans cette écoute, corriger un taux ne
/// rafraîchirait ni les montants dérivés, ni le total de la barre, ni le CTA —
/// le caissier taperait dans un champ sans effet visible.
library;

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';

class FacturationRateBoard {
  /// Un contrôleur par paire (`USD>CDF`).
  ///
  /// Par paire, parce que deux frais de devises différentes n'ont pas « le »
  /// même taux — mais jamais par ligne : deux lignes d'une même paire partagent
  /// leur taux, et en écrire deux dans un seul versement est précisément ce que
  /// la garde locale refuse.
  final Map<String, TextEditingController> _controllers = {};

  /// Les paires dont la boîte est ouverte.
  final Set<String> _editing = {};

  /// Le texte que « Modifier » a pré-rempli, par paire.
  final Map<String, String> _seeds = {};

  final VoidCallback _onChanged;

  FacturationRateBoard({required VoidCallback onChanged})
    : _onChanged = onChanged;

  /// Le contrôleur de cette paire, créé à la demande et déjà écouté.
  TextEditingController controllerOf(String pairKey) =>
      _controllers.putIfAbsent(pairKey, () {
        final controller = TextEditingController();
        controller.addListener(_onChanged);
        return controller;
      });

  /// La boîte de cette paire est-elle ouverte ?
  bool isEditing(String pairKey) => _editing.contains(pairKey);

  /// « Modifier » : ouvre la boîte et l'amorce au taux affiché.
  ///
  /// L'amorce n'est posée que sur un champ **vide** : rouvrir une boîte ne doit
  /// pas effacer ce que le caissier y avait déjà tapé.
  void open(String pairKey, ExchangeRate rate) {
    _editing.add(pairKey);
    final controller = controllerOf(pairKey);
    if (controller.text.isEmpty) {
      final seed = rate.formatted(space: '');
      controller.text = seed;
      _seeds[pairKey] = seed;
    }
  }

  /// Le taux saisi pour cette paire, en micro-unités. `null` tant que rien n'a
  /// été corrigé, ou quand la saisie n'est pas un nombre.
  int? microsOf(String pairKey) {
    final raw = _controllers[pairKey]?.text ?? '';
    // Champ ouvert mais intact : le référentiel garde la main.
    if (raw == _seeds[pairKey]) return null;
    final parsed = parseMonetaryAmount(raw);
    if (parsed == null || parsed <= 0) return null;
    // Deux décimales, celles qui seront stockées : ce qui s'affiche, ce qui
    // s'imprime et ce qui part sur le fil sont le même nombre.
    return (parsed * 100).round() * (ExchangeRate.scale ~/ 100);
  }

  /// Ce que le règlement doit appliquer — une entrée par paire réellement
  /// corrigée. Prêt pour `TenderSettlement.overriddenRates`.
  Map<String, int> get overrides => {
    for (final key in _editing) key: ?microsOf(key),
  };

  /// Referme les boîtes **ouvertes mais restées intactes**.
  ///
  /// Elles affichent le taux amorcé à l'ANCIENNE date, pendant que les montants,
  /// eux, repartent du référentiel du nouveau jour : le champ dirait 2 000,00
  /// quand le comptoir compte à 1 666,67. Refermées, la ligne réaffiche le taux
  /// du jour désigné, qui est le bon.
  ///
  /// Un taux réellement **corrigé à la main** survit (A4) : c'est une intention
  /// du caissier, pas une valeur dérivée de la date.
  void closeUntouched() {
    final untouched = [
      for (final key in _editing)
        if (_controllers[key]?.text == _seeds[key]) key,
    ];
    for (final key in untouched) {
      _editing.remove(key);
      _seeds.remove(key);
      _controllers[key]?.clear();
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }
}
