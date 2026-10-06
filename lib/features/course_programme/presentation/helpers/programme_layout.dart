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

  /// Icônes de bouton et de ligne.
  static const double iconSmall = 16;
  static const double iconMedium = 18;

  /// Bordure d'un bouton de statut rapide : choisi, ou non.
  static const double statutBorderSelected = 2;
  static const double statutBorder = 1;

  /// Icône d'en-tête de section, d'encadré.
  static const double sectionIcon = 17;
  static const double asideIcon = 15;

  /// Hauteur minimale de l'en-tête d'une section (place de son action).
  static const double sectionActionMinHeight = 40;

  /// Puce d'une liste, d'une pilule de stratégie.
  static const double bullet = 6;

  /// Décalage d'une puce pour l'aligner sur la première ligne du texte.
  static const double bulletTopOffset = 9;

  /// Trait terre cuite d'un titre de bloc.
  static const double titleMarkerWidth = 4;
  static const double titleMarkerHeight = 18;

  /// Liséré gauche d'un encadré (« À retenir », « Exemple »).
  static const double asideEdge = 4;

  /// Bordure pointillée du bouton « Joindre… » d'une liste vide.
  static const double emptyBorderWidth = 1.5;

  /// Lignes fantômes de l'en-tête en chargement.
  static const double skeletonTitleHeight = 20;
  static const double skeletonSubtitleHeight = 14;

  /// Largeur de la modale d'un chapitre.
  static const double formDialogMaxWidth = 600;

  /// Largeur minimale d'une colonne du détail (Ressources | Évaluations).
  static const double gridColumnMin = 280;

  /// Largeur de lecture confortable du contenu rédigé.
  static const double readingMaxWidth = 680;

  /// Largeur minimale d'un champ de planification (séances, sous-période).
  static const double planningFieldMinWidth = 180;

  /// Largeur maximale du contenu.
  static const double contentMaxWidth = 1180;
}
