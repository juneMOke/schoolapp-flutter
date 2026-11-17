import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';

/// Un ticket **en cours de composition** : ses lignes de texte, celles qui
/// s'impriment en gras, et la place de son QR.
///
/// Partagé par les gabarits qui sortent de la même imprimante — la perception
/// et la vente boutique — pour que leurs blocs communs (`TicketSections`)
/// écrivent au même endroit, de la même façon.
///
/// [lines] reste une liste ordinaire, exposée telle quelle : les gabarits y
/// ajoutent leurs blocs propres avec les primitives habituelles, et seuls le
/// gras et le QR passent par ici.
class TicketSheet {
  /// Nombre de caractères par ligne — jamais moins de 24, en deçà desquels
  /// aucune paire libellé/montant ne tient.
  final int width;

  final List<String> lines = <String>[];

  // Les indices des lignes grasses. Un ensemble plutôt qu'une liste parallèle :
  // la seconde devrait rester alignée sur la première à chaque `addAll`, ce qui
  // est exactement le genre d'invariant qui se casse en silence.
  final Set<int> _bold = <int>{};

  int? _qrAt;
  String? _qrPayload;

  TicketSheet(int columns) : width = columns < 24 ? 24 : columns;

  /// Marque en gras TOUT ce que [build] ajoute — une ligne ou dix.
  ///
  /// Aucun calcul d'indice au point d'appel : les cas multi-lignes — un titre
  /// replié, un montant en deux devises — sont couverts sans y penser.
  void emphasised(void Function() build) {
    final from = lines.length;
    build();
    for (var i = from; i < lines.length; i++) {
      _bold.add(i);
    }
  }

  /// Réserve la ligne du QR. Elle vaut `''` dans le pivot textuel ; les
  /// renderers dessinent le code à cette place.
  void placeQr(String payload) {
    _qrAt = lines.length;
    _qrPayload = payload;
    lines.add('');
  }

  /// Les lignes attribuées, telles que les renderers les consomment.
  List<TicketLine> build() => [
    for (var i = 0; i < lines.length; i++)
      if (i == _qrAt)
        TicketLine.qr(_qrPayload!)
      else
        TicketLine(lines[i], bold: _bold.contains(i)),
  ];
}
