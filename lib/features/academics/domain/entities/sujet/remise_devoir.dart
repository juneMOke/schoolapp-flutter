import 'package:equatable/equatable.dart';

/// Comment un devoir se remet : par le parent depuis le portail, ou en
/// classe.
enum ModeRemise {
  enClasse('EN_CLASSE'),
  enLigne('EN_LIGNE');

  const ModeRemise(this.apiValue);

  final String apiValue;

  /// Une valeur inconnue se lit « en classe » : le défaut du serveur (V179),
  /// et le seul mode qui n'ouvre rien au parent.
  static ModeRemise fromApi(Object? value) =>
      value == 'EN_LIGNE' ? enLigne : enClasse;
}

/// La remise d'un DEVOIR (V179) : à quelle heure il est dû, s'il se remet en
/// ligne ou en classe, et si un dépôt en retard est accepté. Le jour
/// d'échéance reste la date du devoir.
///
/// Un devoir sans remise saisie a la remise par défaut du serveur ([parDefaut]).
/// Une interrogation ou un examen n'en a **pas** : le serveur refuserait les
/// trois champs (`HOMEWORK_DELIVERY_ON_TEST`), ils ne partent donc jamais.
class RemiseDevoir extends Equatable {
  final ModeRemise mode;

  /// `HH:mm` ; `null` = fin du jour.
  final String? heureLimite;

  /// N'a de sens qu'en ligne : en classe, il vaut toujours `false`.
  final bool depotTardifPermis;

  const RemiseDevoir({
    this.mode = ModeRemise.enClasse,
    this.heureLimite,
    this.depotTardifPermis = false,
  });

  /// Les valeurs par défaut du serveur : en classe, fin du jour, pas de
  /// retard.
  static const RemiseDevoir parDefaut = RemiseDevoir();

  static final RegExp _heure = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  bool get enLigne => mode == ModeRemise.enLigne;

  /// Copie cohérente : pas de dépôt tardif en classe, une heure illisible
  /// ramenée à « fin du jour ».
  RemiseDevoir normalized() => RemiseDevoir(
    mode: mode,
    heureLimite: heureLimite != null && _heure.hasMatch(heureLimite!)
        ? heureLimite
        : null,
    depotTardifPermis: enLigne && depotTardifPermis,
  );

  RemiseDevoir copyWith({
    ModeRemise? mode,
    String? Function()? heureLimite,
    bool? depotTardifPermis,
  }) => RemiseDevoir(
    mode: mode ?? this.mode,
    heureLimite: heureLimite == null ? this.heureLimite : heureLimite(),
    depotTardifPermis: depotTardifPermis ?? this.depotTardifPermis,
  );

  /// Les trois champs du contrat, **toujours ensemble** : un `modeRemise`
  /// présent fait prendre la remise entière (une `heureLimite` nulle retire
  /// l'heure).
  Map<String, Object?> toJson() {
    final remise = normalized();
    return {
      'heureLimite': remise.heureLimite,
      'modeRemise': remise.mode.apiValue,
      'depotTardifPermis': remise.depotTardifPermis,
    };
  }

  /// Tolérant : un champ absent ou illisible prend sa valeur par défaut.
  factory RemiseDevoir.fromJson(Map<String, dynamic> json) => RemiseDevoir(
    mode: ModeRemise.fromApi(json['modeRemise']),
    heureLimite: json['heureLimite'] is String
        ? json['heureLimite'] as String
        : null,
    depotTardifPermis: json['depotTardifPermis'] == true,
  ).normalized();

  @override
  List<Object?> get props => [mode, heureLimite, depotTardifPermis];
}
