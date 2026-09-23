import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';

/// Teintes des écrans de liste d'inscription (spec Première inscription).
///
/// ## Ce qui vit ici, et ce qui n'y vit plus
///
/// Les surfaces et les encres de la grammaire « bleu = la demande, terre cuite
/// = la réponse » ont été remontées dans [ListingTones], sous `core` : elles
/// sont partagées par tous les écrans de liste du produit, et un composant
/// partagé — `BiModeSearchForm`, qui coiffe quatre écrans — ne peut pas
/// importer un fichier de `features`. Ce fichier n'en garde que les **noms**,
/// pour que les appelants d'Inscriptions ne changent pas, et y ajoute ce qui
/// est réellement propre au module : la couleur d'un **statut de dossier**.
///
/// Les valeurs, elles, sont inchangées — `enrollment_listing_tones_test.dart`
/// continue de vérifier que les quatre surfaces publiées par la spec se
/// reproduisent exactement.
///
/// ## Ce que ce fichier ne décide pas
///
/// **La couleur des avatars.** La spec §13 propose une palette fermée de six
/// valeurs indexée par `nomComplet.hashCode`. Le produit fait mieux depuis
/// longtemps et le garde : `AvatarPalette.colorFor` hache l'**identifiant** de
/// l'élève en FNV-1a, puis descend la luminosité jusqu'à garantir 4,5:1 contre
/// le blanc cassé *et* la surface alternative. Deux raisons de ne pas régresser :
///
/// * `String.hashCode` n'est stable **ni entre deux exécutions ni entre deux
///   versions du VM** — la spec du tableau de bord l'interdit d'ailleurs
///   explicitement, pour cette raison exacte, dans sa palette de cycles ;
/// * hacher le **nom** fait changer la couleur d'une personne dès qu'on corrige
///   une faute de frappe dans son état civil. L'identifiant, lui, ne bouge pas.
///
/// Le contraste des avatars est donc *calculé*, là où la palette de la spec
/// serait seulement *auditée* — et deux de ses six valeurs sont hors palette
/// ETEELO de son propre aveu (écart E3).
class EnrollmentListingTones {
  const EnrollmentListingTones._();

  // ---- Les deux zones ----

  /// Ce que l'utilisateur demande : bandeau de recherche, champs, filtres.
  static const Color zoneSaisie = ListingTones.zoneSaisie;

  /// Ce que la machine répond, et ce qu'on écrit : barre, table, bouton.
  static const Color zoneResultat = ListingTones.zoneResultat;

  // ---- Surfaces dérivées, par rôle ----

  /// Fond de la barre de résultats — terre cuite à 10 %.
  static Color get barreFond => ListingTones.barreFond;

  /// Bord de la barre de résultats.
  static Color get barreBord => ListingTones.barreBord;

  /// Fond du corps de formulaire de recherche — bleu à 7 %.
  static Color get formulaireFond => ListingTones.formulaireFond;

  /// Bord du corps de formulaire de recherche.
  static Color get formulaireBord => ListingTones.formulaireBord;

  /// Bandeau d'en-tête du tableau de résultats.
  static Color get tableEntete => ListingTones.table.header;

  /// Zébrure des lignes paires du tableau de résultats.
  static Color get tableZebrure => ListingTones.table.zebra;

  /// Bord du cadre du tableau — même force que celui de la barre, et c'est
  /// voulu : les deux surfaces encadrent la **même** réponse.
  static Color get tableBord => ListingTones.table.border;

  /// L'habillage complet du tableau de résultats, prêt à passer au socle.
  static DataTableTone get table => ListingTones.table;

  // ---- Encres ----

  /// Encre d'en-tête de tableau.
  static const Color inkEnteteTable = ListingTones.inkEnteteTable;

  /// Encre de la colonne triée.
  static const Color inkEnteteTri = ListingTones.inkEnteteTri;

  /// Sous-titre posé sur le dégradé du bandeau de recherche.
  static const Color inkSousTitre = ListingTones.inkSousTitre;

  /// Sous-texte de tiroir.
  static const Color inkTiroirSub = ListingTones.inkTiroirSub;

  /// Eyebrow « RÉSULTATS » et pastille « niveau visé » : la terre cuite
  /// **assombrie**, jamais `terreCuite` — qui tombe à 4,04:1 sur son voile
  /// (écart E2 de la spec).
  static const Color inkTerreCuite = ListingTones.inkResultat;

  // ---- Statut d'un dossier ----
  //
  // La seule chose de ce fichier qui soit vraiment propre au module : `core`
  // ne connaît pas les statuts d'un dossier d'inscription.

  /// Couleur pleine et voile de chaque statut de dossier.
  ///
  /// Le statut se porte par un **filet** ou une **pastille**, jamais par le
  /// fond de la ligne : une liste bicolore n'a plus de zébrure lisible, et le
  /// statut disparaît à l'impression (§12).
  static const Map<String, ({Color color, Color soft})> statut = {
    'done': (
      color: AppColors.vertSavane,
      soft: AppColors.enrollmentStatsReSoft,
    ),
    'progress': (
      color: AppColors.bleuArdoise,
      soft: AppColors.enrollmentStatsAccentSoft,
    ),
  };

  /// Teinte d'un statut, depuis sa clé.
  static ({Color color, Color soft}) statutOf(String key) {
    final entry = statut[key];
    assert(entry != null, 'Aucun ton déclaré pour le statut « $key ».');
    return entry ??
        (
          color: AppColors.bleuArdoise,
          soft: AppColors.enrollmentStatsAccentSoft,
        );
  }
}
