import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les sept colonnes du cahier, dans l'ordre de la feuille — la même source
/// pour la feuille, les cartes et la modale de saisie.
enum JournalField {
  cb(flex: 10),
  objectif(flex: 13),
  contenu(flex: 11),
  strategie(flex: 10),
  ressources(flex: 10),
  evaluation(flex: 11),
  observation(flex: 10);

  const JournalField({required this.flex});

  /// Largeur relative de la colonne dans la feuille.
  final int flex;

  /// Objectif et contenu font d'une séance une séance renseignée.
  bool get isRequired => this == objectif || this == contenu;

  String valueOf(JournalFields fields) => switch (this) {
    cb => fields.cb,
    objectif => fields.objectif,
    contenu => fields.contenu,
    strategie => fields.strategie,
    ressources => fields.ressources,
    evaluation => fields.evaluation,
    observation => fields.observation,
  };

  JournalFields write(JournalFields fields, String value) => switch (this) {
    cb => fields.copyWith(cb: value),
    objectif => fields.copyWith(objectif: value),
    contenu => fields.copyWith(contenu: value),
    strategie => fields.copyWith(strategie: value),
    ressources => fields.copyWith(ressources: value),
    evaluation => fields.copyWith(evaluation: value),
    observation => fields.copyWith(observation: value),
  };

  /// Le titre de la colonne, aussi libellé d'une carte.
  String label(AppLocalizations l10n) => switch (this) {
    cb => l10n.journalColumnCb,
    objectif => l10n.journalColumnObjectif,
    contenu => l10n.journalColumnContenu,
    strategie => l10n.journalColumnStrategie,
    ressources => l10n.journalColumnRessources,
    evaluation => l10n.journalColumnEvaluation,
    observation => l10n.journalColumnObservation,
  };
}
