import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/dev/ticket_bench_fixtures.dart';
import 'package:school_app_flutter/dev/ticket_bench_printer_panel.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/ticket_code_page.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

/// Banc de calage de l'impression thermique (`/dev/ticket-print`, `kDebugMode`).
///
/// Il sert deux choses que la production ne sait pas faire :
///
/// 1. **Voir le gabarit à sa vraie largeur** sans écrire un versement dans la
///    base. Le texte est posé en chasse fixe, dans une colonne réglée au
///    caractère près : une ligne qui déborde se voit immédiatement.
/// 2. **Préparer la sonde de page de code.** La NT-8003DD démarre probablement
///    en CP437, où l'octet `0xE9` n'est pas `é`. La seule façon honnête de
///    savoir ce qu'elle supporte est d'envoyer les **mêmes** octets Latin-1 sous
///    plusieurs sélecteurs `ESC t n` et de lire lequel sort juste — c'est le
///    papier qui répond, pas la fiche technique.
///
/// 3. **Envoyer pour de vrai.** Le canal Bluetooth SPP existe désormais : le
///    pupitre (`TicketBenchPrinterPanel`) charge les imprimantes appairées,
///    retient celle de la tablette, et envoie ticket ou sonde.
///
/// On y accède depuis le bas de la page d'accueil, sous `kDebugMode`
/// (`DevToolsEntry`) — sans cette porte la route reste orpheline, et
/// `--route=` ne la sauve pas : le redirect d'authentification la mange.
class TicketPrintBenchPage extends StatefulWidget {
  const TicketPrintBenchPage({super.key});

  @override
  State<TicketPrintBenchPage> createState() => _TicketPrintBenchPageState();
}

class _TicketPrintBenchPageState extends State<TicketPrintBenchPage> {
  static const List<int> _widths = [32, 42, 48];

  /// Sélecteurs `ESC t n` candidats, du plus probable au moins probable.
  static const List<(int, String)> _candidates = [
    (16, 'WPC1252 — l\'hypothèse : identité avec le Latin-1'),
    (0, 'CP437 — le défaut d\'usine de la plupart des thermiques'),
    (2, 'CP850 — multilingue latin, accents à d\'autres octets'),
    (19, 'CP858 — CP850 + symbole euro'),
    (6, 'ISO-8859-1 sur certains firmwares'),
  ];

  /// Avances candidates, à balayer au papier.
  ///
  /// La NT-8003DD n'a **pas de massicot** (constaté par l'utilisateur le
  /// 2026-08-11) : on déchire à la main, et l'avance devient le seul mécanisme
  /// qui fait sortir la dernière ligne du mécanisme. C'est un arbitrage, pas un
  /// réglage — trop court, on déchire dans « Conservez ce ticket… » ; trop long,
  /// on jette quelques centimètres de rouleau à **chaque** encaissement.
  static const List<int> _feeds = [2, 4, 6, 8, 10];

  int _columns = 48;
  bool _minimal = false;
  int _feedLines = EscPosTicketRenderer.defaultFeedLines;

  TicketReceiptModel get _model =>
      _minimal ? TicketBenchFixtures.minimal : TicketBenchFixtures.torture;

  Uint8List _buildTicket() => EscPosTicketRenderer.render(
    _model,
    columns: _columns,
    feedLines: _feedLines,
  );

  /// Les cinq candidates dans **un seul** flux, donc un seul envoi et un seul
  /// morceau de papier.
  ///
  /// Chaque bloc rouvre par `ESC @` puis pose sa propre `ESC t n` : les
  /// concaténer ne les fait donc pas se contaminer. Les envoyer séparément
  /// coûterait cinq connexions RFCOMM — et cinq occasions que l'une échoue au
  /// milieu de la comparaison, ce qui la rendrait illisible.
  Uint8List _buildProbe() {
    final out = BytesBuilder();
    for (final (selector, note) in _candidates) {
      out.add(
        EscPosTicketRenderer.renderLines(
          ['ESC t $selector  ($note)', TicketBenchFixtures.codePageProbeLine],
          codePage: TicketCodePage.probe(selector),
          feedLines: 1,
        ),
      );
    }
    // Avance de fin, pour dégager la barre de déchirure comme un vrai ticket.
    out.add(EscPosTicketRenderer.renderLines(const [], feedLines: _feedLines));
    return out.takeBytes();
  }

  @override
  Widget build(BuildContext context) {
    final lines = TicketTextLayout.render(_model, columns: _columns);
    final stream = _buildTicket();

    return Scaffold(
      appBar: AppBar(title: const Text('Banc — impression thermique')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _Header('Imprimante'),
          TicketBenchPrinterPanel(
            buildTicket: _buildTicket,
            buildProbe: _buildProbe,
          ),
          const SizedBox(height: AppSpacing.lg),

          const _Header('Modèle'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Torture')),
              ButtonSegment(value: true, label: Text('Tout absent')),
            ],
            selected: {_minimal},
            onSelectionChanged: (s) => setState(() => _minimal = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _Header('Largeur (colonnes)'),
          SegmentedButton<int>(
            segments: [
              for (final w in _widths)
                ButtonSegment(value: w, label: Text('$w')),
            ],
            selected: {_columns},
            onSelectionChanged: (s) => setState(() => _columns = s.first),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '80 mm en police A = 48. 58 mm = 32. Police B sur 80 mm = 64.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          const _Header('Avance papier (lignes)'),
          SegmentedButton<int>(
            segments: [
              for (final f in _feeds)
                ButtonSegment(value: f, label: Text('$f')),
            ],
            selected: {_feedLines},
            onSelectionChanged: (s) => setState(() => _feedLines = s.first),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pas de massicot : on déchire à la main, donc l\'avance doit sortir '
            'la dernière ligne du mécanisme. Environ ${_feedLines * 42 ~/ 10} mm '
            'à 203 dpi et à l\'interligne par défaut — à confirmer en déchirant. '
            'Trop court, on coupe dans « Conservez ce ticket… » ; trop long, on '
            'jette du rouleau à chaque encaissement.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          _Header('Gabarit — ${lines.length} lignes'),
          _MonospaceBlock(lines: lines, columns: _columns),
          const SizedBox(height: AppSpacing.lg),

          _Header('Flux ESC/POS — ${stream.length} octets'),
          Text(
            'En-tête ESC @ · ESC t 16 · ESC a 0, puis une ligne par LF, puis '
            'ESC d $_feedLines. Aucune commande de coupe : l\'imprimante n\'a '
            'pas de massicot.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          _HexBlock(bytes: stream),
          const SizedBox(height: AppSpacing.lg),

          const _Header('Sonde de page de code'),
          Text(
            'Même ligne accentuée, sous chaque sélecteur. À imprimer d\'un seul '
            'tenant dès que le canal Bluetooth existera : la bonne page est '
            'celle dont les accents sortent justes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (selector, note) in _candidates)
            _ProbeRow(selector: selector, note: note),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Une ligne de la sonde : le sélecteur, ce qu'on en attend, et la taille du
/// flux qui partira.
class _ProbeRow extends StatelessWidget {
  final int selector;
  final String note;

  const _ProbeRow({required this.selector, required this.note});

  @override
  Widget build(BuildContext context) {
    final bytes = EscPosTicketRenderer.renderLines(
      ['ESC t $selector', TicketBenchFixtures.codePageProbeLine, ''],
      codePage: TicketCodePage.probe(selector),
      feedLines: 1,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              'ESC t $selector',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          Expanded(child: Text(note)),
          Text(
            '${bytes.length} o',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Le gabarit en chasse fixe, dans une colonne large d'exactement [columns]
/// caractères — la règle qui rend un débordement visible à l'œil.
class _MonospaceBlock extends StatelessWidget {
  final List<String> lines;
  final int columns;

  const _MonospaceBlock({required this.lines, required this.columns});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.35,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Règle de contrôle : si une ligne du ticket la dépasse, le gabarit
            // est faux — et ça se lit sans compter les caractères.
            Text('.' * columns, style: style.copyWith(color: AppColors.border)),
            for (final line in lines)
              Text(line.isEmpty ? ' ' : line, style: style),
          ],
        ),
      ),
    );
  }
}

/// Les 64 premiers octets du flux, en hexadécimal — de quoi vérifier l'en-tête
/// à l'œil sans brancher quoi que ce soit.
class _HexBlock extends StatelessWidget {
  final Uint8List bytes;

  const _HexBlock({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final head = bytes.take(64).map(_hex).join(' ');
    final tail = bytes.length > 64
        ? '\n…\n${bytes.skip(bytes.length - 8).map(_hex).join(' ')}'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$head$tail',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }

  static String _hex(int b) =>
      b.toRadixString(16).padLeft(2, '0').toUpperCase();
}

class _Header extends StatelessWidget {
  final String title;

  const _Header(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
    ),
  );
}
