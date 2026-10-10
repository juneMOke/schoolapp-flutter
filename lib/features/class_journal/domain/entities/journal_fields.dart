import 'package:equatable/equatable.dart';

/// Les sept champs du cahier pour une séance.
///
/// Une séance est **renseignée** dès que l'objectif et le contenu sont
/// remplis ; elle est **vide** quand aucun champ ne l'est (une séance vidée).
class JournalFields extends Equatable {
  /// Plafond par champ, fixé au contrat (refus 400 du serveur au-delà).
  static const int maxLength = 4000;

  /// C.B — compétence de base.
  final String cb;
  final String objectif;

  /// Contenu — matière / sujet.
  final String contenu;
  final String strategie;
  final String ressources;
  final String evaluation;
  final String observation;

  const JournalFields({
    this.cb = '',
    this.objectif = '',
    this.contenu = '',
    this.strategie = '',
    this.ressources = '',
    this.evaluation = '',
    this.observation = '',
  });

  static const JournalFields empty = JournalFields();

  bool get isFilled => objectif.trim().isNotEmpty && contenu.trim().isNotEmpty;

  bool get isBlank => props.every((v) => (v as String).trim().isEmpty);

  JournalFields copyWith({
    String? cb,
    String? objectif,
    String? contenu,
    String? strategie,
    String? ressources,
    String? evaluation,
    String? observation,
  }) => JournalFields(
    cb: cb ?? this.cb,
    objectif: objectif ?? this.objectif,
    contenu: contenu ?? this.contenu,
    strategie: strategie ?? this.strategie,
    ressources: ressources ?? this.ressources,
    evaluation: evaluation ?? this.evaluation,
    observation: observation ?? this.observation,
  );

  @override
  List<Object?> get props => [
    cb,
    objectif,
    contenu,
    strategie,
    ressources,
    evaluation,
    observation,
  ];
}
