import 'package:equatable/equatable.dart';

/// Les cinq fenêtres de temps du tableau de bord des inscriptions.
///
/// Les valeurs partent **en anglais** sur le fil (`day`, `week`, `month`,
/// `year`, `custom`) : l'endpoint parle anglais partout. « Période précise »
/// n'est que le libellé de l'onglet.
enum EnrollmentStatsWindowKind { day, week, month, year, custom }

/// Une fenêtre de temps **valide par construction**.
///
/// Le serveur refuse délibérément trois requêtes en 400 plutôt que de les
/// rattraper :
///
///  1. `date` posé avec une autre période que `day` ;
///  2. `custom` sans ses deux bornes — pas de repli sur l'année, « une fenêtre
///     non demandée afficherait des chiffres exacts sous une légende fausse » ;
///  3. des bornes inversées, qu'il **n'échange pas** : ce peut être un bug de
///     calcul côté client, et mieux vaut le voir.
///
/// Ces trois refus sont de bons refus, et la bonne réponse n'est pas de les
/// afficher à l'utilisateur : c'est de **ne pas pouvoir** construire la requête
/// fautive. D'où les constructeurs nommés et l'assertion ci-dessous — une
/// fenêtre qui existe est une fenêtre que le serveur acceptera.
class EnrollmentStatsWindow extends Equatable {
  final EnrollmentStatsWindowKind kind;

  /// Jour visé. Non nul **si et seulement si** [kind] vaut `day`.
  final DateTime? day;

  /// Borne basse d'une fenêtre libre. Non nulle ssi [kind] vaut `custom`.
  final DateTime? from;

  /// Borne haute d'une fenêtre libre, **incluse**. Non nulle ssi `custom`.
  final DateTime? to;

  const EnrollmentStatsWindow._({
    required this.kind,
    this.day,
    this.from,
    this.to,
  });

  /// Une journée précise. Par défaut aujourd'hui, mais n'importe quel jour se
  /// vise — la liste nominative sait en servir n'importe lequel.
  factory EnrollmentStatsWindow.day(DateTime day) => EnrollmentStatsWindow._(
    kind: EnrollmentStatsWindowKind.day,
    day: _dateOnly(day),
  );

  const EnrollmentStatsWindow.week()
    : this._(kind: EnrollmentStatsWindowKind.week);

  const EnrollmentStatsWindow.month()
    : this._(kind: EnrollmentStatsWindowKind.month);

  /// L'année scolaire. **Elle part de l'ouverture des inscriptions**, pas du
  /// 1er janvier — et cette date est un fait serveur, que le client ne calcule
  /// jamais.
  const EnrollmentStatsWindow.year()
    : this._(kind: EnrollmentStatsWindowKind.year);

  /// Une fenêtre libre, bornes incluses.
  ///
  /// Lève si les bornes sont inversées : c'est un défaut de programmation, pas
  /// une saisie utilisateur — l'interface empêche déjà de composer une plage à
  /// l'envers.
  factory EnrollmentStatsWindow.custom({
    required DateTime from,
    required DateTime to,
  }) {
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    assert(
      !start.isAfter(end),
      'EnrollmentStatsWindow.custom : bornes inversées ($start > $end). Le '
      'serveur refuserait en 400, et il a raison de ne pas les échanger.',
    );
    return EnrollmentStatsWindow._(
      kind: EnrollmentStatsWindowKind.custom,
      from: start,
      to: end,
    );
  }

  /// Valeur du paramètre `period`.
  String get apiPeriod => switch (kind) {
    EnrollmentStatsWindowKind.day => 'day',
    EnrollmentStatsWindowKind.week => 'week',
    EnrollmentStatsWindowKind.month => 'month',
    EnrollmentStatsWindowKind.year => 'year',
    EnrollmentStatsWindowKind.custom => 'custom',
  };

  /// `date`, envoyé **uniquement** avec `period=day`.
  String? get apiDate => day == null ? null : formatApiDate(day!);

  /// `from`, envoyé uniquement avec `period=custom`.
  String? get apiFrom => from == null ? null : formatApiDate(from!);

  /// `to`, envoyé uniquement avec `period=custom`.
  String? get apiTo => to == null ? null : formatApiDate(to!);

  /// Vrai quand la fenêtre couvre **une seule journée**.
  ///
  /// C'est elle qui fait dire « du jour » aux sous-titres, et « Heure » plutôt
  /// que « Date » à la première colonne de la liste nominative — et elle est
  /// vraie pour une fenêtre libre dont les deux bornes tombent le même jour,
  /// pas seulement pour l'onglet « Aujourd'hui ». La borne haute étant
  /// incluse, `from == to` cadre bien un jour.
  bool get isSingleDay =>
      kind == EnrollmentStatsWindowKind.day ||
      (kind == EnrollmentStatsWindowKind.custom && from == to);

  /// La journée couverte, quand la fenêtre en couvre exactement une.
  DateTime? get singleDay => switch (kind) {
    EnrollmentStatsWindowKind.day => day,
    EnrollmentStatsWindowKind.custom when from == to => from,
    _ => null,
  };

  /// Vrai pour la fenêtre la plus large que l'écran sache demander.
  ///
  /// Sert l'état vide : proposer d'élargir une fenêtre déjà maximale est une
  /// impasse. Une fenêtre libre ne compte pas comme la plus large — elle peut
  /// être n'importe quoi, y compris deux jours.
  bool get isWidest => kind == EnrollmentStatsWindowKind.year;

  /// `2026-09-05` — le format du contrat.
  ///
  /// Écrit à la main plutôt qu'avec `intl` : le paquet n'est pas une
  /// dépendance directe du projet, et trois `padLeft` ne justifient pas de
  /// l'ajouter.
  static String formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Retire l'heure : une fenêtre est un intervalle de jours.
  ///
  /// Sans ça, deux fenêtres du même jour construites à deux instants seraient
  /// inégales, le `buildWhen` du bloc rejouerait, et `from == to` deviendrait
  /// faux pour une plage d'un jour saisie à midi.
  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [kind, day, from, to];
}
