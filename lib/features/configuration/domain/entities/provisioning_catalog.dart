import 'package:equatable/equatable.dart';

/// Catalogue du système éducatif, servi par le serveur.
///
/// **Rien de ce référentiel n'est écrit dans l'application** (D-8 du plan) :
/// codes, libellés, ordre d'affichage, pré-cochage, barèmes proposables et
/// nombre de cours viennent tous de `GET /provisioning/catalog`. Une constante
/// Dart divergerait au premier amendement du catalogue, et le serveur refuse en
/// 422 tout code qu'il ne connaît pas.
///
/// Seules restent côté application les couleurs d'accent par cycle, indexées sur
/// le code servi.
class ProvisioningCatalog extends Equatable {
  /// Version du référentiel (`2026.1`). Clé de cache : une version différente
  /// invalide tout ce qui a été construit dessus.
  final String version;

  /// Pays du référentiel (`CD`).
  final String country;

  final List<CatalogCycle> cycles;

  const ProvisioningCatalog({
    required this.version,
    required this.country,
    required this.cycles,
  });

  @override
  List<Object?> get props => [version, country, cycles];
}

/// Un cycle du système éducatif — ce que l'API nomme `schoolLevelGroup`.
class CatalogCycle extends Equatable {
  final String code;

  /// Libellé à afficher, **tel quel**. « Cycle Terminal de l'Éducation de Base »
  /// et « Humanités Générales » : ni « Secondaire — CTEB » ni « Secondaire —
  /// Humanités », qui n'existent pas dans le catalogue.
  final String name;

  /// `TRIMESTER` ou `SEMESTER`. Porté par le cycle, pas réglé dans l'assistant :
  /// le découpage en périodes se règle dans Résultats.
  final String periodType;

  final int displayOrder;

  /// Le cycle est-il proposé coché à la première ouverture.
  final bool defaultSelected;

  final List<CatalogLevel> levels;

  const CatalogCycle({
    required this.code,
    required this.name,
    required this.periodType,
    required this.displayOrder,
    required this.defaultSelected,
    required this.levels,
  });

  @override
  List<Object?> get props => [
    code,
    name,
    periodType,
    displayOrder,
    defaultSelected,
    levels,
  ];
}

/// Un niveau — ce que l'API nomme `schoolLevel`.
class CatalogLevel extends Equatable {
  final String code;
  final String name;
  final int displayOrder;
  final bool defaultSelected;

  /// Nombre de classes proposé par défaut sur ce niveau.
  final int defaultClassrooms;

  /// Barèmes officiels proposables sur ce niveau.
  ///
  /// **C'est `sections.length` qui décide du rendu**, pas une règle locale :
  /// une seule section sans filière → compteur simple ; plusieurs → une ligne
  /// par filière ; zéro → compteur simple, et un avertissement.
  final List<CatalogSection> sections;

  /// Avertissements servis sur ce niveau, `NO_OFFICIAL_GRID` en tête.
  ///
  /// **Ne jamais les déduire de `sections.isEmpty`** : la liste des codes peut
  /// s'enrichir, et le serveur est seul juge de ce qui mérite d'être signalé.
  final List<String> warnings;

  const CatalogLevel({
    required this.code,
    required this.name,
    required this.displayOrder,
    required this.defaultSelected,
    required this.defaultClassrooms,
    required this.sections,
    required this.warnings,
  });

  /// Le niveau porte plusieurs barèmes : le compteur simple y est refusé par le
  /// serveur, il faut un compteur par section.
  bool get hasMultipleSections => sections.length > 1;

  /// Aucun barème officiel : les classes se créeront, sans aucun cours.
  bool get hasNoOfficialGrid =>
      warnings.contains(ProvisioningWarningCodes.noOfficialGrid);

  @override
  List<Object?> get props => [
    code,
    name,
    displayOrder,
    defaultSelected,
    defaultClassrooms,
    sections,
    warnings,
  ];
}

/// Un barème officiel proposable sur un niveau.
///
/// C'est en désignant l'un d'eux qu'une classe devient scientifique ou
/// pédagogique — et c'est lui qui fournit le `grilleId`, sans quoi la classe
/// naîtrait sans cours.
class CatalogSection extends Equatable {
  /// Identité du barème (`DEGRE_TERMINAL_6E`, `SCIENTIFIQUE_1`).
  final String officialCode;

  /// Filière (`SCIENTIFIQUE`…), `null` pour un tronc commun.
  ///
  /// **C'est `filiere` qui décide** si le nom de la classe annonce une filière,
  /// jamais le rang de la section dans la liste.
  final String? filiere;

  /// Forme courte de la filière (`Sci`), telle qu'elle entre dans le nom d'une
  /// classe. `null` pour un tronc commun, qui n'a rien à distinguer.
  ///
  /// **Servie, jamais reconstruite** : la déduire d'un `substring` de [filiere]
  /// donnerait « Lat » pour `LATIN_PHILO` et « Ped » sans accent.
  final String? filiereAbregee;

  /// Libellé lisible (« Degré Terminal », « Humanités Scientifiques »).
  final String libelle;

  /// Référence MINEDUC du document papier (`IGE/P.S/006`).
  final String codeOfficiel;

  /// Nombre de cours qu'entraînera une classe suivant ce barème. C'est ce que
  /// coûte, en volume pédagogique, une classe de cette filière.
  final int courseCount;

  const CatalogSection({
    required this.officialCode,
    required this.filiere,
    required this.filiereAbregee,
    required this.libelle,
    required this.codeOfficiel,
    required this.courseCount,
  });

  @override
  List<Object?> get props => [
    officialCode,
    filiere,
    filiereAbregee,
    libelle,
    codeOfficiel,
    courseCount,
  ];
}

/// Codes d'avertissement servis par le catalogue et par le plan.
///
/// Miroir de ce que le serveur émet. Un code inconnu s'affiche quand même — il
/// porte son message rédigé — mais ceux-ci sont nommés parce que l'écran les
/// place différemment : sous le niveau pour le premier, dans le bloc du
/// récapitulatif pour les autres.
class ProvisioningWarningCodes {
  const ProvisioningWarningCodes._();

  /// Niveau ouvert sans barème officiel : ses classes n'auront aucun cours.
  static const String noOfficialGrid = 'NO_OFFICIAL_GRID';

  /// Niveau retenu mais sans aucune classe : paramétré, non ouvert.
  static const String levelWithoutClassroom = 'LEVEL_WITHOUT_CLASSROOM';

  /// Niveau ouvert sans aucun tarif : ses élèves n'auront aucune charge.
  static const String levelWithoutFee = 'LEVEL_WITHOUT_FEE';
}
