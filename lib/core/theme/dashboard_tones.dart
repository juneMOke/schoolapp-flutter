import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// Les six couleurs qui traversent **tous** les tableaux de bord avec le même
/// sens (spec Tableaux de bord §07).
///
/// C'est le socle du système : une couleur qui change de sens d'un écran à
/// l'autre coûte plus cher que dix teintes en trop. Un encaissement est vert
/// partout, un reste à percevoir rouge partout, une dépense terre cuite
/// partout — quel que soit le module qui l'affiche.
class DashboardSense {
  const DashboardSense._();

  /// Attendu · neutre · structurel — effectifs, caisse dollars, jours.
  static const Color attendu = AppColors.bleuArdoise;

  /// Encaissé · soldé · conforme — perçu, caisse francs, taux de présence.
  static const Color encaisse = AppColors.vertSavane;

  /// Manquant · alerte · critique — reste à percevoir, absences non justifiées.
  static const Color manquant = AppColors.error;

  /// En attente · vigilance — paiement partiel, reçus émis, pré-inscriptions.
  static const Color attente = AppColors.insOcre;

  /// Marque · décaissement — total dépensé, par source.
  static const Color marque = AppColors.terreCuite;

  /// Prestige · sélection — glyphes de pavé, anneau de sélection, filet.
  ///
  /// ⚠️ **Jamais du texte** : 2,1 à 3,4:1 selon le fond. Sur fond clair
  /// employer [AppColors.ambreInk], sur fond sombre `#F3D9A6`.
  static const Color prestige = AppColors.orDoux;
}

/// Grammaire chromatique partagée par les tableaux de bord.
///
/// Trois composants portent toute la couleur de ces écrans, et leurs formules
/// sont **identiques partout** : seul l'argument change. Les écrire une fois
/// ici, plutôt qu'une fois par module, est ce qui empêche qu'un module dérive
/// le jour où le mélange évolue.
///
/// Vit dans `core` et non dans un module : quatre features la consomment, et
/// aucune ne peut être la propriétaire des trois autres.
class DashboardTones {
  const DashboardTones._();

  /// Part de l'accent conservée dans un fond de **pavé** — les 22 % restants
  /// sont du bleu profond. C'est cet assombrissement qui rend l'encre crème
  /// lisible sans changer l'identité de la couleur.
  static const double paveAccentShare = 0.78;

  /// Part du ton conservée dans un **bandeau de tableau** — 20 % de bleu
  /// profond. Une table est moins haute qu'un pavé et supporte un ton plus
  /// franc.
  static const double enteteToneShare = 0.80;

  /// Zébrure d'une ligne, en pourcentage du ton dilué dans `--surface`.
  static const int zebrurePercent = 6;

  /// Fond plein d'un pavé de chiffre clé.
  ///
  /// ⚠️ Toujours passer par [paveAccentSur] d'abord : un accent trop clair
  /// produit un pavé illisible, et rien dans le type ne l'empêche.
  static Color pave(Color accent) =>
      ColorMix.darken(AppColors.bleuProfond, accent, paveAccentShare);

  /// Bandeau plein d'en-tête de tableau.
  static Color entete(Color tone) =>
      ColorMix.darken(AppColors.bleuProfond, tone, enteteToneShare);

  /// Surface claire : [tone] dilué à [percent] % dans le blanc.
  static Color teinte(Color tone, int percent) =>
      ColorMix.tint(AppColors.surfaceRaised, tone, percent);

  /// Zébrure d'une ligne paire.
  static Color zebrure(Color tone) =>
      ColorMix.mix(AppColors.surface, tone, zebrurePercent / 100);

  /// Force de teinte donnant une **densité perçue constante** (§02).
  ///
  /// À force égale un carmin et un ocre ne pèsent pas pareil : les tons chauds
  /// saturés descendent à 9, les froids et sourds montent à 10, et le bleu
  /// profond — le plus dense — tombe à 8. On règle une perception, pas un
  /// chiffre.
  static int forceDe(Color tone) {
    if (tone == AppColors.bleuProfond) return 8;
    const chaudsSatures = <Color>[
      AppColors.enrollmentStatsFemale,
      AppColors.terreCuite,
      AppColors.error,
    ];
    return chaudsSatures.contains(tone) ? 9 : 10;
  }

  /// Fond et bord d'une carte de section, à la force qui convient à son ton.
  static (Color background, Color border) section(Color tone) {
    final force = forceDe(tone);
    return (
      teinte(tone, force),
      ColorMix.tint(AppColors.border, tone, (force * 3).clamp(16, 100)),
    );
  }

  /// **Garde-fou** : la version d'un accent qui peut porter du texte.
  ///
  /// Trois accents du produit sont des couleurs de **surface** : l'or, l'ambre
  /// et le gris muet. Employés tels quels sur un fond clair — en valeur de
  /// chiffre clé, en libellé — ils tombent sous le seuil. Employés comme fond
  /// de pavé, ils donnent un aplat trop clair pour l'encre crème.
  ///
  /// Les deux cas qui l'imposent sont réels et **invisibles en relecture** :
  ///
  /// * le pavé « Poste principal » des Dépenses prend la couleur du poste
  ///   dominant, **envoyée par le serveur**. Quand c'est « Électricité » (or),
  ///   la valeur tombe à 2,28:1 sur carte blanche ; quand c'est « Divers »
  ///   (gris), à 3,69:1. Le défaut ne se déclenche que chez les écoles dont la
  ///   dépense dominante est celle-là ;
  /// * le taux « Absence justifiée » de Disciplines s'écrit en 700/30 dans
  ///   l'ambre `#D68910` : **2,82:1**, sous le seuil même pour du texte large.
  ///
  /// La substitution est donc systématique, jamais conditionnelle : toute
  /// couleur destinée à porter du texte ou à fonder un pavé passe par ici.
  /// L'accent d'origine reste employé pour les **surfaces** — médaillon, filet,
  /// segment de barre — où il est parfaitement lisible et où il porte le sens.
  /// Version d'un accent qui peut **fonder un pavé** — assez sombre pour
  /// porter l'encre crème.
  static Color paveAccentSur(Color accent) =>
      _substitutsFond[accent.toARGB32()] ?? accent;

  /// Version d'un accent qui peut **porter du texte sur une surface claire**.
  ///
  /// ⚠️ Ce n'est **pas** la même table que [paveAccentSur], et la différence
  /// n'est pas cosmétique : l'ocre `#A66A00` fonde un pavé très correctement
  /// (5,63:1 sous l'encre crème) mais ne tient que **4,48:1** écrit sur du
  /// blanc. « Assez sombre pour porter de l'encre » et « assez sombre pour
  /// être lu » sont deux exigences distinctes, et les confondre laisse passer
  /// un défaut dans un sens ou dans l'autre.
  ///
  /// Les trois ambres du produit — or, ambre d'alerte, ocre — convergent donc
  /// ici vers la même encre lisible, celle que les specs prescrivent.
  static Color encreLisible(Color accent) =>
      _substitutsEncre[accent.toARGB32()] ?? accent;

  /// Vrai si [accent] est une couleur de surface, à ne jamais écrire telle
  /// quelle sur un fond clair.
  static bool estCouleurDeSurface(Color accent) =>
      _substitutsEncre.containsKey(accent.toARGB32());

  /// Fonds de pavé : il suffit d'être assez sombre pour l'encre crème.
  static final Map<int, Color> _substitutsFond = {
    AppColors.orDoux.toARGB32(): DashboardSense.attente,
    AppColors.warning.toARGB32(): DashboardSense.attente,
    AppColors.textMuted.toARGB32(): AppColors.textMutedAa,
  };

  /// Encres sur surface claire : le seuil est plus haut, et l'ocre n'y suffit
  /// plus.
  static final Map<int, Color> _substitutsEncre = {
    AppColors.orDoux.toARGB32(): AppColors.ambreInk,
    AppColors.warning.toARGB32(): AppColors.ambreInk,
    AppColors.insOcre.toARGB32(): AppColors.ambreInk,
    AppColors.textMuted.toARGB32(): AppColors.textMutedAa,
  };

  // ---- Élévations et anneau (spec §11) ----

  /// Ombre d'un pavé de chiffre clé.
  ///
  /// La couleur reste **bleu profond** quelle que soit la teinte du pavé : une
  /// ombre ocre sous un pavé ocre le ferait flotter dans une flaque de sa
  /// propre couleur.
  static const List<BoxShadow> paveShadow = [
    BoxShadow(color: Color(0x2E0E2D42), blurRadius: 26, offset: Offset(0, 10)),
  ];

  /// Ombre d'une carte de section — dix fois plus discrète que celle d'un
  /// pavé : une surface claire n'a pas à se détacher, seulement à exister.
  static const List<BoxShadow> sectionShadow = [
    BoxShadow(color: Color(0x120E2D42), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Anneau de sélection d'un pavé cliquable, **par-dessus** son ombre.
  ///
  /// La sélection ne change jamais la teinte du pavé : celle-ci dit la nature
  /// du chiffre, et la remplacer détruirait le code couleur de l'état qu'il
  /// représente (§10). C'est l'or — couleur de prestige, jamais de texte — qui
  /// porte l'état sélectionné.
  static const List<BoxShadow> selectionRing = [
    BoxShadow(color: DashboardSense.prestige, spreadRadius: 2, blurRadius: 0),
    BoxShadow(color: Color(0x2E0E2D42), blurRadius: 26, offset: Offset(0, 10)),
  ];

  // ---- Encres de pavé ----

  /// Valeur d'un pavé.
  static const Color inkValeur = AppColors.insInkMain;

  /// Libellé d'un pavé, en capitales.
  static const Color inkLibelle = AppColors.insInkLabel;

  /// Sous-ligne d'un pavé — l'encre générique.
  ///
  /// En **bi-devise** seulement, la seconde ligne prend la variante teintée du
  /// pavé ([AppColors.paveInkAttendu] et ses sœurs) : c'est le seul endroit du
  /// produit où une sous-ligne porte une nuance, et elle y signale une monnaie
  /// dont le montant ne s'additionne pas au premier.
  static const Color inkSousLigne = AppColors.insInkSub;

  /// Encre de la **seconde** valeur d'un pavé bi-devise.
  ///
  /// C'est le seul endroit du produit où une valeur secondaire porte une
  /// nuance plutôt que l'encre générique, et la nuance a un sens précis : elle
  /// dit « second montant », pas « commentaire ». Un pavé qui affiche
  /// `184 500 $` puis `3 420 000 FC` montre deux sommes dont le total
  /// n'existe pas ; les écrire toutes deux en encre pleine laisserait croire
  /// qu'on peut les additionner.
  ///
  /// Une table plutôt qu'une teinte unique, pour deux raisons qui se
  /// renforcent. La première est de **sens** : la seconde ligne emprunte la
  /// teinte de *son* chiffre — rosée sous le reste, verte sous le perçu — et
  /// se lit donc comme lui appartenant.
  ///
  /// La seconde est **mesurée**, et elle interdit d'étendre la table à la
  /// légère : une nuance n'est pas universellement sûre. Chacune tient
  /// largement sur son propre pavé (7,45 / 5,94 / 5,19) et sur les deux autres
  /// pavés froids, mais posée sur les deux pavés clairs — l'attente `#855D0F`
  /// et la marque `#935231` — elle tombe **sous le seuil** : 4,37 et 4,46 pour
  /// la nuance de l'attendu, 4,26 et 4,35 pour celle du reste.
  ///
  /// C'est pourquoi ces deux sens-là n'en déclarent aucune et retombent sur
  /// [inkValeur] `#FAFAF7`, qui passe sur les cinq pavés. Le repli n'est pas
  /// une commodité : c'est la seule encre correcte à cet endroit.
  ///
  /// Un accent sans nuance déclarée retombe sur [inkValeur], qui est lisible
  /// sur les cinq pavés — le défaut est sûr, jamais illisible.
  static Color encreSecondeValeur(Color accent) =>
      _encresSecondes[accent.toARGB32()] ?? inkValeur;

  /// Les trois sens qui peuvent porter deux devises : ce qui est dû, ce qui
  /// est rentré, ce qui reste.
  static final Map<int, Color> _encresSecondes = {
    DashboardSense.attendu.toARGB32(): AppColors.paveInkAttendu,
    DashboardSense.encaisse.toARGB32(): AppColors.paveInkPercu,
    DashboardSense.manquant.toARGB32(): AppColors.paveInkReste,
  };
}
