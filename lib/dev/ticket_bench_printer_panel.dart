import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/dev/ticket_bench_printer_store.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';

/// Le pupitre matériel du banc : permission, choix de l'imprimante, envoi.
///
/// Séparé de la page pour une raison de fond : la page compose des octets, ce
/// panneau parle à une machine. Les deux échouent pour des raisons sans rapport,
/// et l'une doit rester utilisable quand l'autre ne l'est pas.
///
/// Fichier de développement (`kDebugMode`) : chaînes en dur, comme la galerie de
/// composants. Les messages de production, eux, passeront par `AppLocalizations`
/// au lot du câblage.
class TicketBenchPrinterPanel extends StatefulWidget {
  /// Le ticket, composé avec les réglages courants de la page.
  final Uint8List Function() buildTicket;

  /// La sonde : les cinq pages de code candidates, dans **un seul** flux.
  final Uint8List Function() buildProbe;

  const TicketBenchPrinterPanel({
    super.key,
    required this.buildTicket,
    required this.buildProbe,
  });

  @override
  State<TicketBenchPrinterPanel> createState() =>
      _TicketBenchPrinterPanelState();
}

class _TicketBenchPrinterPanelState extends State<TicketBenchPrinterPanel> {
  /// Largeur libre, hauteur au minimum tactile — voir la note du `Wrap`.
  static const Size _inlineButtonSize = Size(0, AppDimensions.minTouchTarget);

  List<ThermalPrinter> _printers = const [];
  String? _selected;
  String _message = 'Aucune imprimante chargée.';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreSelection();
  }

  Future<void> _restoreSelection() async {
    final mac = await getIt<TicketBenchPrinterStore>().read();
    if (!mounted || mac == null) return;
    setState(() => _selected = mac);
  }

  /// Charge la liste, en sollicitant la permission si elle manque.
  ///
  /// L'ordre compte : le port se contente de **constater** un refus, parce que
  /// demander une permission est un geste d'interface. C'est donc ici, et
  /// seulement ici, qu'on ouvre la boîte de dialogue système.
  Future<void> _loadPrinters() async {
    await _run(() async {
      final port = getIt<ThermalPrinterPort>();

      var result = await port.pairedPrinters();
      if (_problemOf(result) == ThermalPrinterProblem.permissionDenied) {
        final state = await getIt<ThermalPrinterPermission>().request();
        if (state == ThermalPrinterPermissionState.permanentlyDenied) {
          await getIt<ThermalPrinterPermission>().openSettings();
          return 'Permission refusée définitivement — réglages ouverts.';
        }
        if (state != ThermalPrinterPermissionState.granted) {
          return 'Permission refusée.';
        }
        result = await port.pairedPrinters();
      }

      return result.fold(_describe, (printers) {
        // Règle #8 : ce `fold` s'exécute après un à trois `await`.
        if (!mounted) return 'Panneau fermé.';
        setState(() {
          _printers = printers;
          // Une imprimante retenue qui n'est plus appairée doit être OUBLIÉE :
          // la garder ferait échouer chaque impression sans que rien ne le dise.
          if (!printers.any((p) => p.macAddress == _selected)) _selected = null;
        });
        return printers.isEmpty
            ? 'Aucun appareil appairé. Appairer d\'abord dans les réglages Android.'
            : '${printers.length} appareil(s) appairé(s).';
      });
    });
  }

  Future<void> _select(String mac) async {
    setState(() => _selected = mac);
    await getIt<TicketBenchPrinterStore>().write(mac);
  }

  Future<void> _send(Uint8List bytes, String what) => _run(() async {
    final mac = _selected;
    if (mac == null) return 'Choisir une imprimante d\'abord.';

    final result = await getIt<ThermalPrinterPort>().printBytes(
      bytes,
      macAddress: mac,
    );
    return result.fold(_describe, (_) => '$what envoyé (${bytes.length} o).');
  });

  /// Sérialise les gestes : deux envois concurrents se disputeraient la même
  /// liaison RFCOMM, et le canal natif ne garde qu'un flux à la fois.
  Future<void> _run(Future<String> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final message = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  static ThermalPrinterProblem? _problemOf(Object either) {
    final failure =
        (either as dynamic).fold((Failure f) => f, (_) => null) as Failure?;
    return failure is ThermalPrinterFailure ? failure.problem : null;
  }

  /// Chaque cause appelle un geste différent — c'est toute la raison d'être de
  /// [ThermalPrinterProblem].
  static String _describe(Failure failure) =>
      switch (failure is ThermalPrinterFailure ? failure.problem : null) {
        ThermalPrinterProblem.permissionDenied =>
          'Permission « Appareils à proximité » refusée.',
        ThermalPrinterProblem.bluetoothOff =>
          'Bluetooth éteint sur la tablette.',
        ThermalPrinterProblem.noPrinterSelected => 'Aucune imprimante choisie.',
        ThermalPrinterProblem.unreachable =>
          'Imprimante injoignable : éteinte, hors de portée, ou déjà connectée '
              'à un autre appareil.',
        _ => 'Échec inattendu : ${failure.message}',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⚠️ `minimumSize` explicite sur les trois : `AppTheme.light` impose
        // `Size(double.infinity, 56)` aux `FilledButton`/`OutlinedButton` — un
        // réglage pensé pour les CTA pleine largeur type « Se connecter ». Sans
        // override, chaque bouton s'étire à toute la largeur du `Wrap` (mesuré :
        // 1400 px sur une surface de 1400) et les trois s'empilent au lieu de
        // tenir sur une ligne. Convention du dépôt, cf. `classes_organisation_*`.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _loadPrinters,
              style: OutlinedButton.styleFrom(minimumSize: _inlineButtonSize),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Charger les appairées'),
            ),
            FilledButton.icon(
              onPressed: _busy || _selected == null
                  ? null
                  : () => _send(widget.buildTicket(), 'Ticket'),
              style: FilledButton.styleFrom(minimumSize: _inlineButtonSize),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Imprimer le ticket'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy || _selected == null
                  ? null
                  : () => _send(widget.buildProbe(), 'Sonde'),
              style: FilledButton.styleFrom(minimumSize: _inlineButtonSize),
              icon: const Icon(Icons.abc),
              label: const Text('Lancer la sonde'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // `ListTile` plutôt que `RadioListTile` : l'API `groupValue`/`onChanged`
        // de `Radio` est dépréciée au profit d'un ancêtre `RadioGroup`, et un
        // panneau de développement n'a pas à porter cette dette pour afficher
        // une coche.
        for (final printer in _printers)
          ListTile(
            dense: true,
            selected: printer.macAddress == _selected,
            leading: Icon(
              printer.macAddress == _selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: _busy ? null : () => _select(printer.macAddress),
            title: Text(printer.name.isEmpty ? '(sans nom)' : printer.name),
            subtitle: Text(printer.macAddress),
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Expanded(
              child: Text(
                _message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
