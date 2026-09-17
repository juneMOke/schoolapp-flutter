import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';

/// Ordre d'affichage des listes d'élèves : **Nom → Post-nom → Prénom**.
///
/// C'est l'ordre que les tables affichent et celui du roster SQL
/// (`classroom_local_data_source.dart`, `_rosterOrderBy`). Trier sur une autre
/// cascade que celle qu'on lit dans la colonne donnerait un ordre que l'œil ne
/// peut pas vérifier.
///
/// **Pourquoi le tri vit ici et pas en SQL.** `COLLATE NOCASE` de SQLite est
/// ASCII-only : il replie `a`/`A` mais pas `é`/`E`, et une comparaison brute de
/// chaînes compare des unités UTF-16 (`É` = 201 passe après `Z` = 90). « Émile »
/// se rangerait donc après « Zacharie ». `sqflite` n'expose aucune API de
/// collation personnalisée, et le projet n'embarque pas `intl` : aucun
/// collateur ICU n'est disponible. Le repli d'accents ne peut donc se faire
/// qu'en Dart.
///
/// Il s'adosse à [SearchNormalizationHelper], qui sert déjà la **recherche** de
/// ces mêmes colonnes — sans quoi le tri et la recherche ne plieraient pas les
/// accents de la même façon : « écolé » trouverait « Ecole », mais « Émile » se
/// rangerait quand même après « Zacharie ».
///
/// Générique plutôt que lié à une entité : le socle ne dépend pas des features,
/// et les formes divergent d'un module à l'autre (`surname` côté inscription,
/// `middleName` côté classe et discipline). Chaque appelant dit où lire ses
/// parties, la règle d'ordre ne se réécrit qu'ici.
abstract final class StudentNameComparator {
  /// Comparateur par Nom → Post-nom → Prénom, casse et accents repliés.
  ///
  /// [surname] est optionnel : une forme qui n'a pas de post-nom saute ce rang
  /// au lieu de le simuler. [id] départage deux homonymes complets — sans lui
  /// l'ordre de deux fiches identiques dépendrait de l'ordre d'arrivée, et une
  /// liste pourrait se réordonner toute seule d'un chargement à l'autre.
  static Comparator<T> by<T>({
    required String? Function(T item) lastName,
    required String? Function(T item) firstName,
    String? Function(T item)? surname,
    String? Function(T item)? id,
  }) {
    return (a, b) {
      final byLast = comparePart(lastName(a), lastName(b));
      if (byLast != 0) return byLast;

      final bySurname = comparePart(surname?.call(a), surname?.call(b));
      if (bySurname != 0) return bySurname;

      final byFirst = comparePart(firstName(a), firstName(b));
      if (byFirst != 0) return byFirst;

      return (id?.call(a) ?? '').compareTo(id?.call(b) ?? '');
    };
  }

  /// Compare une partie de nom : minuscules, accents repliés, espaces de
  /// bordure ignorés.
  ///
  /// Une partie vide (ou absente) **ferme la marche**, quel que soit le sens de
  /// tri demandé par l'appelant : intercaler un élève sans nom au milieu de
  /// l'alphabet casserait précisément l'ordre qu'on vient y chercher. Deux
  /// parties vides sont équivalentes — le rang suivant tranchera.
  static int comparePart(String? a, String? b) {
    final left = SearchNormalizationHelper.normalize(a?.trim() ?? '');
    final right = SearchNormalizationHelper.normalize(b?.trim() ?? '');
    if (left.isEmpty || right.isEmpty) {
      if (left.isEmpty && right.isEmpty) return 0;
      return left.isEmpty ? 1 : -1;
    }
    return left.compareTo(right);
  }
}
