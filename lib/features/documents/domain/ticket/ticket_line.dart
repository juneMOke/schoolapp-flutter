import 'package:equatable/equatable.dart';

/// Une ligne de ticket **et ce que le papier doit en faire** : son texte, et
/// s'il se compose en gras.
///
/// C'est le pivot enrichi entre le gabarit et les deux renderers. Le pivot
/// historique — une simple `List<String>` — reste la façade
/// (`TicketTextLayout.render`), et c'est lui qui rend vérifiable le critère
/// d'acceptation de l'ADR-012 : « même contenu **textuel** entre les deux
/// sorties ». L'attribut ne s'y invite pas, justement parce qu'il n'est pas du
/// contenu.
///
/// ## Pourquoi le gras, et pourquoi lui seul
///
/// Il ne coûte **aucune colonne**, sur aucune des deux sorties :
///
/// - en ESC/POS, `ESC E` est une double frappe dans la **même** cellule ;
/// - en PDF, `Courier-Bold` a exactement la chasse de `Courier` (600/1000),
///   donc le corps dérivé par `TicketBlockGeometry` reste juste.
///
/// C'est ce qui le sépare de la double largeur (`GS ! n`), interdite dans ce
/// gabarit parce qu'elle divise les 48 colonnes par deux et replie les montants.
/// Toute autre variante typographique devra refaire cette démonstration avant
/// d'entrer ici.
///
/// ⚠️ **Le gras ne vaut que s'il est rare.** Tout emphatiser ne crée aucune
/// hiérarchie : ça noircit le papier, et sur une tête thermique usée la double
/// frappe bave. Il est réservé au nom de l'école, aux titres de section et aux
/// lignes de total — ce que le porteur a arbitré le 2026-09-24.
class TicketLine extends Equatable {
  final String text;
  final bool bold;

  const TicketLine(this.text, {this.bold = false});

  /// Une ligne sans attribut — ce que rend un gabarit qui n'en pose aucun.
  const TicketLine.plain(this.text) : bold = false;

  @override
  List<Object?> get props => [text, bold];

  @override
  String toString() => bold ? '**$text**' : text;
}
