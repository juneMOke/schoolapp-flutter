import 'package:flutter/material.dart';

/// Famille chromatique d'un module (spec Accueil-Couleurs §01).
///
/// Deux familles seulement : le **bleu** porte l'école — ses élèves, ses
/// documents, son paramétrage — et la **terre cuite** ce qui touche à l'argent,
/// aux classes et aux résultats. La famille n'est pas décorative : c'est elle
/// qui détermine l'encre du médaillon (or sur bleu, crème sur terre cuite).
enum AccueilModuleFamily { bleu, terre }

/// Teinte d'un pavé module : son fond plein et l'accent de son médaillon.
///
/// La spec ferme la palette à **cinq fonds** et interdit d'en introduire un
/// sixième (§09). Cette classe ne construit donc aucune couleur : elle assemble
/// des valeurs déjà déclarées dans `AppColors`, et c'est
/// `AccueilModuleTones.table` qui décide laquelle revient à quel module.
///
/// [accent] ne colore **jamais du texte** — uniquement le glyphe 24 dp du
/// médaillon et le bord de la pastille « Tableau de bord », tous deux non
/// textuels. L'or `#D9A24E` ne dépasse pas 2,9:1 sur les fonds de la palette :
/// employé sur un libellé il serait illisible (§04, §09).
@immutable
class AccueilModuleTone {
  /// Fond plein du pavé — l'une des cinq valeurs de la palette fermée.
  final Color background;

  /// Teinte du glyphe de médaillon et du bord de la pastille « Tableau de
  /// bord ». Or sur les pavés bleus, crème sur les pavés terre cuite.
  final Color accent;

  final AccueilModuleFamily family;

  const AccueilModuleTone({
    required this.background,
    required this.accent,
    required this.family,
  });
}
