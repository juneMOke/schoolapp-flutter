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

  /// Le contenu d'un **QR** à poser à cette place, `null` pour une ligne de
  /// texte.
  ///
  /// Le QR de vérification d'un reçu scellé (révision de D-4, 2026-10-30)
  /// prend place DANS le gabarit, contrairement au logo : il se place avant le
  /// pied, sous sa légende, et seul le gabarit sait où. Il n'entre pas pour
  /// autant dans le pivot textuel : sa ligne y vaut `''`, et chaque renderer
  /// le dessine depuis la même matrice (`TicketQrBand`).
  final String? qrPayload;

  const TicketLine(this.text, {this.bold = false}) : qrPayload = null;

  /// Une ligne sans attribut — ce que rend un gabarit qui n'en pose aucun.
  const TicketLine.plain(this.text) : bold = false, qrPayload = null;

  /// Le QR de [payload], à cette place du ticket.
  const TicketLine.qr(String payload)
    : text = '',
      bold = false,
      qrPayload = payload;

  bool get isQr => qrPayload != null;

  @override
  List<Object?> get props => [text, bold, qrPayload];

  @override
  String toString() => isQr ? '[QR $qrPayload]' : (bold ? '**$text**' : text);
}
