import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';

/// Ce que le promoteur a coché à l'étape 3, indexé par **clé de colonne**.
///
/// Une colonne est un niveau de tronc commun, ou un couple niveau × barème pour
/// un niveau qui en porte plusieurs. La clé est donc `levelCode` ou
/// `levelCode|officialCode` — **jamais une position** : les niveaux d'un même
/// cycle n'offrent pas les mêmes filières, et un index se décalerait au premier
/// barème ajouté au catalogue.
///
/// **La matrice n'est pas un produit cartésien.** HG1 porte quatre barèmes,
/// HG2 à HG4 n'en portent que trois : cela fait treize colonnes, pas seize. Les
/// construire en multipliant les niveaux par les filières du cycle produirait
/// trois colonnes qui n'existent pas, et que le serveur refuserait en 422.
class StructureSelection extends Equatable {
  /// Nombre de classes par colonne. Une colonne absente vaut zéro.
  final Map<String, int> counts;

  const StructureSelection(this.counts);

  static const StructureSelection empty = StructureSelection(<String, int>{});

  /// Borne de l'écran. Le serveur en accepte seize par filière et par niveau ;
  /// l'écran s'arrête à dix, et **c'est la borne la plus stricte qui prime** —
  /// laisser saisir jusqu'à seize pour se faire refuser au bout serait cruel.
  static const int maxPerColumn = 10;

  /// Clé d'une colonne de tronc commun.
  static String levelKey(String levelCode) => levelCode;

  /// Clé d'une colonne niveau × barème.
  static String sectionKey(String levelCode, String officialCode) =>
      '$levelCode|$officialCode';

  /// Les colonnes réellement offertes par un niveau, dans l'ordre du catalogue.
  ///
  /// Zéro ou une section → une colonne simple. Plusieurs → une colonne par
  /// barème, et le compteur simple devient interdit : le serveur refuse alors
  /// qu'on lui dise « trois classes » sans dire lesquelles.
  static List<String> columnsOf(CatalogLevel level) {
    if (!level.hasMultipleSections) return [levelKey(level.code)];
    return [
      for (final section in level.sections)
        sectionKey(level.code, section.officialCode),
    ];
  }

  int countFor(String key) => counts[key] ?? 0;

  /// Le niveau ouvre-t-il au moins une classe, toutes colonnes confondues.
  bool isLevelOpen(CatalogLevel level) =>
      columnsOf(level).any((key) => countFor(key) > 0);

  /// Classes ouvertes sur un niveau.
  int classroomsOf(CatalogLevel level) =>
      columnsOf(level).fold(0, (total, key) => total + countFor(key));

  /// Classes ouvertes sur un cycle.
  int classroomsOfCycle(CatalogCycle cycle) =>
      cycle.levels.fold(0, (total, level) => total + classroomsOf(level));

  /// Niveaux ouverts d'un cycle.
  int openLevelsOf(CatalogCycle cycle) =>
      cycle.levels.where(isLevelOpen).length;

  /// Le cycle est-il retenu — au moins une classe quelque part.
  bool isCycleOpen(CatalogCycle cycle) => classroomsOfCycle(cycle) > 0;

  /// Codes des niveaux qui ouvrent au moins une classe. C'est l'assiette
  /// proposable à l'étape 4 : on ne facture pas un niveau qu'on n'ouvre pas.
  List<String> openLevelCodes(ProvisioningCatalog catalog) => [
    for (final cycle in catalog.cycles)
      for (final level in cycle.levels)
        if (isLevelOpen(level)) level.code,
  ];

  /// Pose une valeur sur une colonne, bornée à `[0, maxPerColumn]`.
  StructureSelection withCount(String key, int value) {
    final bounded = value.clamp(0, maxPerColumn);
    final next = Map<String, int>.from(counts);
    if (bounded == 0) {
      next.remove(key);
    } else {
      next[key] = bounded;
    }
    return StructureSelection(next);
  }

  /// Coche ou décoche un niveau entier.
  ///
  /// Cocher rétablit la proposition du catalogue plutôt que « 1 » en dur : sur
  /// un niveau à barèmes, cocher doit rouvrir **toutes** ses filières, comme à
  /// la première ouverture.
  StructureSelection withLevelChecked(CatalogLevel level, bool checked) {
    var next = this;
    for (final key in columnsOf(level)) {
      next = next.withCount(key, checked ? level.defaultClassrooms : 0);
    }
    return next;
  }

  /// Applique une valeur à tous les niveaux **sans barèmes** d'un cycle.
  ///
  /// Les niveaux à filières en sont exclus : « trois classes » n'y veut rien
  /// dire tant qu'on n'a pas dit lesquelles, et le serveur le refuserait.
  StructureSelection withCycleDefault(CatalogCycle cycle, int value) {
    var next = this;
    for (final level in cycle.levels) {
      if (level.hasMultipleSections) continue;
      next = next.withCount(levelKey(level.code), value);
    }
    return next;
  }

  /// Décoche un cycle entier.
  StructureSelection withCycleChecked(CatalogCycle cycle, bool checked) {
    var next = this;
    for (final level in cycle.levels) {
      next = next.withLevelChecked(level, checked && level.defaultSelected);
    }
    return next;
  }

  /// La **valeur commune** des niveaux sans barèmes d'un cycle, ou leur moyenne
  /// arrondie s'ils divergent.
  ///
  /// C'est ce que le réglage global affiche à l'ouverture : partir de zéro
  /// donnerait l'impression que rien n'est ouvert, et partir de un écraserait
  /// une saisie déjà faite dès qu'on touche la molette.
  int cycleDefaultOf(CatalogCycle cycle) {
    final values = [
      for (final level in cycle.levels)
        if (!level.hasMultipleSections) countFor(levelKey(level.code)),
    ];
    if (values.isEmpty) return 0;
    final first = values.first;
    if (values.every((value) => value == first)) return first;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  /// La **proposition par défaut** : tout est coché, chaque niveau ouvre le
  /// nombre de classes que le catalogue propose, et chaque barème servi ouvre
  /// une classe.
  ///
  /// Reconstruite depuis le catalogue à chaque fois, **jamais depuis une
  /// constante** : le jour où le référentiel gagne un niveau, la proposition
  /// doit le contenir sans release de l'application.
  static StructureSelection defaultFor(ProvisioningCatalog catalog) {
    final counts = <String, int>{};
    for (final cycle in catalog.cycles) {
      if (!cycle.defaultSelected) continue;
      for (final level in cycle.levels) {
        if (!level.defaultSelected) continue;
        for (final key in columnsOf(level)) {
          counts[key] = level.defaultClassrooms;
        }
      }
    }
    return StructureSelection(counts);
  }

  /// Relit une sélection depuis un brouillon.
  ///
  /// Le catalogue tranche : une clé qu'il ne connaît plus est **abandonnée**
  /// silencieusement. La garder ferait partir un code que le serveur refuserait
  /// en 422, et l'écran ne saurait pas dire d'où il vient — un brouillon vieux
  /// de plusieurs semaines n'a pas à bloquer une mise en service.
  static StructureSelection fromDraft(
    ProvisioningRequest draft,
    ProvisioningCatalog catalog,
  ) {
    final known = <String, CatalogLevel>{
      for (final cycle in catalog.cycles)
        for (final level in cycle.levels) level.code: level,
    };

    final counts = <String, int>{};
    for (final cycle in draft.cycles) {
      for (final level in cycle.levels) {
        final catalogLevel = known[level.catalogCode];
        if (catalogLevel == null) continue;

        if (level.sections.isNotEmpty) {
          final offered = {
            for (final section in catalogLevel.sections) section.officialCode,
          };
          for (final section in level.sections) {
            if (!offered.contains(section.officialCode)) continue;
            counts[sectionKey(level.catalogCode, section.officialCode)] =
                section.classrooms.clamp(0, maxPerColumn);
          }
          continue;
        }

        final classrooms = level.classrooms ?? 0;
        if (classrooms > 0 && !catalogLevel.hasMultipleSections) {
          counts[levelKey(level.catalogCode)] = classrooms.clamp(
            0,
            maxPerColumn,
          );
        }
      }
    }
    return StructureSelection(counts);
  }

  /// Traduit la sélection en corps de requête.
  ///
  /// Deux règles du serveur y sont tenues : un cycle sans niveau retenu est
  /// **omis entièrement** (400 sinon), et un niveau à barèmes n'envoie que ses
  /// sections, jamais un compteur simple (422 sinon).
  List<CycleInput> toCycles(ProvisioningCatalog catalog) {
    final cycles = <CycleInput>[];

    for (final cycle in catalog.cycles) {
      final levels = <LevelInput>[];

      for (final level in cycle.levels) {
        if (level.hasMultipleSections) {
          final sections = [
            for (final section in level.sections)
              if (countFor(sectionKey(level.code, section.officialCode)) > 0)
                SectionInput(
                  officialCode: section.officialCode,
                  classrooms: countFor(
                    sectionKey(level.code, section.officialCode),
                  ),
                ),
          ];
          if (sections.isEmpty) continue;
          levels.add(LevelInput(catalogCode: level.code, sections: sections));
          continue;
        }

        final classrooms = countFor(levelKey(level.code));
        if (classrooms == 0) continue;
        levels.add(LevelInput(catalogCode: level.code, classrooms: classrooms));
      }

      if (levels.isEmpty) continue;
      cycles.add(CycleInput(catalogCode: cycle.code, levels: levels));
    }

    return cycles;
  }

  @override
  List<Object?> get props => [counts];
}
