import 'dart:typed_data';

import 'package:school_app_flutter/features/documents/data/ticket/ticket_code_page.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

/// Ce que le massicot doit faire en fin de ticket.
enum TicketCutMode {
  /// Aucune commande de coupe — l'avance papier seule, pour une imprimante à
  /// barre de déchirure.
  ///
  /// **C'est le mode de la NT-8003DD**, qui n'a pas de massicot : on déchire à
  /// la main. L'avance ([EscPosTicketRenderer.defaultFeedLines]) porte alors
  /// seule la responsabilité de faire sortir la dernière ligne du mécanisme.
  none,

  /// `GS V 1` — coupe partielle (un point de papier reste attaché).
  partial,

  /// `GS V 0` — coupe complète.
  full,
}

/// Rend le reçu provisoire en **flux d'octets ESC/POS** — la sortie primaire de
/// RG-012-10, vers la thermique Bluetooth 80 mm.
///
/// ## Le même gabarit que le PDF, sans exception (AM-2)
///
/// Tout le contenu vient de [TicketTextLayout], exactement comme
/// `PdfTicketRenderer`. Ce renderer ne décide d'**aucune** mise en page : c'est
/// ce qui rend le critère d'acceptation de l'ADR — même contenu textuel entre
/// les deux sorties — vérifiable par une simple comparaison de chaînes, sans
/// imprimante.
///
/// **Aucun enrichissement typographique n'est appliqué**, et c'est un choix :
/// ni gras, ni double hauteur, ni centrage matériel.
///
/// * Le bandeau « PROVISOIRE » tire déjà sa visibilité du remplissage `*` que
///   le gabarit partagé lui donne — il est lisible sur les deux sorties, y
///   compris par quelqu'un qui lit peu le français, sans dépendre d'une graisse
///   que le PDF n'a pas.
/// * ⚠️ **Jamais de double largeur (`GS ! n`)** : elle diviserait par deux le
///   nombre de colonnes et reproduirait le défaut typographique déjà documenté
///   dans `PdfTicketRenderer` — un gabarit textuel parfaitement valide, et un
///   papier où « Montant reçu … 25 » se replie sur « 000,00 CDF ».
/// * ⚠️ **Jamais de centrage matériel (`ESC a 1`)** : le gabarit centre déjà
///   avec des espaces. Les deux cumulés décaleraient tout vers la droite. Le
///   flux force donc l'alignement à gauche.
///
/// ## Ce que l'initialisation protège
///
/// Une thermique **garde son état entre deux travaux**. Sans `ESC @` en tête,
/// un gras, une page de code ou un alignement laissés par l'impression
/// précédente — la nôtre ou celle d'une autre application — s'appliqueraient au
/// ticket suivant. L'initialisation n'est donc pas une politesse : c'est la
/// seule garantie qu'un ticket ne dépend pas de celui d'avant.
abstract final class EscPosTicketRenderer {
  /// Nombre de colonnes du gabarit — 48, la police A d'un rouleau de 80 mm.
  static const int columns = TicketTextLayout.defaultColumns;

  /// Lignes d'avance avant la déchirure.
  ///
  /// Non décoratif, et **porteur** sur une imprimante sans massicot comme la
  /// NT-8003DD : la tête d'impression est en retrait de la barre de déchirure,
  /// et sans cette avance les dernières lignes du ticket — dont la phrase de
  /// conservation — restent **dans le mécanisme**. Le parent repart avec un
  /// papier amputé.
  ///
  /// ✅ **Calée au papier le 2026-08-11 sur la NT-8003DD : 6 lignes** (~25 mm à
  /// 203 dpi et à l'interligne ESC/POS par défaut, où une ligne vaut ~4,2 mm).
  /// La valeur a été balayée sur 2/4/6/8/10 au banc `/dev/ticket-print`, en
  /// déchirant à chaque fois — c'est le seul protocole qui répond, l'estimation
  /// théorique donnait 4 et déchirait dans le texte.
  ///
  /// ⚠️ **À recaler si le modèle d'imprimante change** : la distance entre la
  /// tête et la barre de déchirure est propre au mécanisme, pas au format de
  /// papier. Trop court, on déchire dans « Conservez ce ticket… » ; trop long,
  /// on jette quelques centimètres de rouleau à **chaque** encaissement — une
  /// trentaine par jour dans une école.
  static const int defaultFeedLines = 6;

  // ── Commandes ESC/POS ──────────────────────────────────────────────────────
  static const int _esc = 0x1B;
  static const int _gs = 0x1D;
  static const int _lf = 0x0A;

  /// Marque du caractère refusé. Identique à `TicketCharset.replacement` : la
  /// même donnée illisible doit produire le même signe sur les deux sorties.
  static const int _replacement = 0x3F; // '?'

  /// Rend [model] prêt à écrire sur le socket de l'imprimante.
  static Uint8List render(
    TicketReceiptModel model, {
    int columns = TicketTextLayout.defaultColumns,
    TicketCodePage codePage = TicketCodePage.cp1252,
    TicketCutMode cut = TicketCutMode.none,
    int feedLines = defaultFeedLines,
  }) => renderLines(
    TicketTextLayout.render(model, columns: columns),
    codePage: codePage,
    cut: cut,
    feedLines: feedLines,
  );

  /// Même flux, à partir de lignes déjà composées.
  ///
  /// Exposé pour la **sonde de page de code** : déterminer ce que le matériel
  /// supporte demande d'imprimer une ligne accentuée sous plusieurs sélecteurs,
  /// pas un ticket complet.
  static Uint8List renderLines(
    List<String> lines, {
    TicketCodePage codePage = TicketCodePage.cp1252,
    TicketCutMode cut = TicketCutMode.none,
    int feedLines = defaultFeedLines,
  }) {
    final out = BytesBuilder();

    // `ESC @` — remise à zéro complète, cf. la note de classe.
    out.add(<int>[_esc, 0x40]);
    // `ESC t n` — la page de code sous laquelle les octets qui suivent seront lus.
    out.add(<int>[_esc, 0x74, codePage.selector]);
    // `ESC a 0` — alignement à gauche : le gabarit centre déjà avec des espaces.
    out.add(<int>[_esc, 0x61, 0x00]);

    for (final line in lines) {
      out.add(encodeLine(line, codePage));
      out.addByte(_lf);
    }

    // `ESC d n` — avance de n lignes, pour dégager le mécanisme.
    if (feedLines > 0) out.add(<int>[_esc, 0x64, feedLines]);

    final cutCommand = switch (cut) {
      TicketCutMode.none => null,
      TicketCutMode.partial => const <int>[_gs, 0x56, 0x01],
      TicketCutMode.full => const <int>[_gs, 0x56, 0x00],
    };
    if (cutCommand != null) out.add(cutCommand);

    return out.takeBytes();
  }

  /// Encode une ligne en octets, sous [codePage].
  ///
  /// ## La garde qui compte vraiment
  ///
  /// `TicketCharset` garantit l'imprimabilité au sens **Unicode** : chaque
  /// caractère tient sur un octet. Ça ne suffit pas ici. Sur le fil ESC/POS, un
  /// octet inférieur à `0x20` n'est pas un caractère, c'est une **commande** :
  /// un `0x1B` venu du nom d'une école injecterait une séquence d'échappement
  /// dans le flux, et un `0x0A` casserait l'invariant de largeur sur lequel
  /// repose tout le gabarit — la ligne suivante partirait décalée, montants
  /// compris.
  ///
  /// Les domaines de commande (`0x00–0x1F`, `0x7F–0x9F`) sont donc remplacés
  /// par `?`, **visiblement**. C'est la même règle que `TicketCharset` applique
  /// à l'étage au-dessus, pour la même raison : un caractère manquant se
  /// corrige, un ticket corrompu se croit juste.
  static Uint8List encodeLine(String line, TicketCodePage codePage) {
    // `printable` est idempotent : l'appliquer ici coûte un balayage et couvre
    // les appelants de `renderLines`, qui apportent leurs propres lignes.
    final source = TicketCharset.printable(line);
    final bytes = Uint8List(source.runes.length);

    var i = 0;
    for (final rune in source.runes) {
      bytes[i++] = _isPrintableByte(rune)
          ? codePage.encode(rune)
          : _replacement;
    }
    return bytes;
  }

  /// Vrai si [rune] désigne un caractère que l'imprimante posera sur le papier
  /// — par opposition à un domaine de commande ou à un point de code que
  /// `TicketCharset` n'a pas su ramener sur un octet.
  static bool _isPrintableByte(int rune) {
    if (rune > 0xFF) return false; // hors Latin-1 : ne devrait pas arriver.
    if (rune < 0x20) return false; // C0 — commandes.
    if (rune >= 0x7F && rune <= 0x9F) return false; // DEL + C1.
    return true;
  }
}
