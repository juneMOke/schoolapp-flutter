/// Les mesures du programme de cours (spec Claude Design, 1 px = 1 dp).
class ProgrammeLayout {
  ProgrammeLayout._();

  /// Médaillon d'en-tête (programme, chapitre).
  static const double headerMedallion = 54;
  static const double headerMedallionIcon = 26;

  /// Pastille numérotée d'une rangée.
  static const double rowNumber = 34;

  /// Icônes de la ligne méta d'une rangée.
  static const double metaIcon = 13;

  /// Bloc « Avancement » de l'en-tête : largeur visée, et largeur sous
  /// laquelle il passe sous le titre.
  static const double progressWidth = 230;
  static const double progressWrapBelow = 560;
  static const double progressBarHeight = 7;

  /// Sous cette largeur, Modifier / Supprimer passent dans un menu « ⋮ ».
  static const double compactRowBelow = 600;

  /// Largeur de la modale d'un chapitre.
  static const double formDialogMaxWidth = 600;

  /// Largeur maximale du contenu.
  static const double contentMaxWidth = 1180;
}
