import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_period.dart';

/// Une fenêtre de caisse **valide par construction**.
///
/// Le serveur refuse délibérément trois requêtes en 400 plutôt que de les
/// rattraper :
///
///  1. `from` ou `to` posé avec une autre période que `custom` ;
///  2. `custom` sans ses **deux** bornes — pas de repli sur le mois : « une
///     fenêtre non demandée afficherait des chiffres exacts sous une légende
///     fausse » ;
///  3. des bornes inversées, qu'il **n'échange pas** — ce peut être un bug de
///     calcul côté client, et mieux vaut le voir.
///
/// Ces trois refus sont de bons refus, et la bonne réponse n'est pas de les
/// afficher au caissier : c'est de **ne pas pouvoir** construire la requête
/// fautive. D'où les constructeurs nommés et l'assertion ci-dessous — une
/// fenêtre qui existe est une fenêtre que le serveur acceptera.
///
/// Repris de `EnrollmentStatsWindow`, qui a résolu le même problème sur le même
/// contrat. La caisse n'y a pas été factorisée pour une raison de fond : ses
/// fenêtres ne sont pas les mêmes — `day` n'existe que pour elle, et le
/// tableau de bord des inscriptions ne l'aurait pas acceptée.
class TillWindow extends Equatable {
  final TillPeriod period;

  /// Borne basse d'une fenêtre libre. Non nulle **ssi** [period] vaut `custom`.
  final DateTime? from;

  /// Borne haute d'une fenêtre libre, **incluse**. Non nulle ssi `custom`.
  final DateTime? to;

  const TillWindow._({required this.period, this.from, this.to});

  /// La journée en cours — **le défaut de l'écran**, la question qu'on pose le
  /// soir à la fermeture.
  const TillWindow.day() : this._(period: TillPeriod.day);

  const TillWindow.week() : this._(period: TillPeriod.week);

  const TillWindow.month() : this._(period: TillPeriod.month);

  /// L'année scolaire.
  ///
  /// ⚠️ **Constructible, mais non offerte par le sélecteur.** Le contrat la
  /// sert ; la spec ne l'a jamais dessinée, et le porteur a tranché pour la
  /// spec. Elle reste ici parce que le modèle doit pouvoir dire ce que le
  /// serveur accepte — la retirer ferait mentir le modèle sur le contrat.
  const TillWindow.year() : this._(period: TillPeriod.year);

  /// Une fenêtre libre, **bornes incluses**.
  ///
  /// Lève sur des bornes inversées : c'est un défaut de programmation, pas une
  /// saisie — l'interface empêche déjà de composer une plage à l'envers.
  factory TillWindow.custom({required DateTime from, required DateTime to}) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    assert(
      !start.isAfter(end),
      'TillWindow.custom : bornes inversées ($start > $end). Le serveur '
      'refuserait en 400, et il a raison de ne pas les échanger.',
    );
    return TillWindow._(period: TillPeriod.custom, from: start, to: end);
  }

  /// La fenêtre libre proposée à l'ouverture du segment : **les trente derniers
  /// jours**, borne haute incluse.
  factory TillWindow.defaultCustom(DateTime today) {
    final end = dateOnly(today);
    return TillWindow.custom(
      from: end.subtract(const Duration(days: 30)),
      to: end,
    );
  }

  /// Valeur du paramètre `period`.
  String get apiPeriod => period.apiValue;

  /// `from`, envoyé **uniquement** avec `period=custom`.
  String? get apiFrom => from == null ? null : formatApiDate(from!);

  /// `to`, envoyé uniquement avec `period=custom`.
  String? get apiTo => to == null ? null : formatApiDate(to!);

  /// La fenêtre est un intervalle libre, saisi à la main.
  bool get isCustom => period == TillPeriod.custom;

  /// Le nombre de jours couverts — bornes incluses. `null` hors fenêtre libre,
  /// où seul le serveur connaît les bornes effectives.
  int? get dayCount => isCustom ? to!.difference(from!).inDays + 1 : null;

  /// `2026-09-05` — le format du contrat.
  ///
  /// Écrit à la main plutôt qu'avec `intl` : le paquet n'est pas une dépendance
  /// directe du projet, et trois `padLeft` ne justifient pas de l'ajouter.
  static String formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Retire l'heure : une fenêtre est un intervalle de **jours**.
  ///
  /// Sans ça, deux fenêtres du même jour construites à deux instants seraient
  /// inégales, le `buildWhen` du bloc rejouerait, et une plage d'un jour saisie
  /// à midi cesserait d'être reconnue comme telle.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [period, from, to];
}
