import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_printer_settings.dart';

/// Les réglages d'impression de la tablette, dans le stockage sécurisé : le
/// seul magasin clé/valeur du dépôt (rien de secret dans une adresse MAC).
class SecureTicketPrinterSettingsStore implements TicketPrinterSettingsStore {
  static const _macKey = 'printing.ticket_printer.mac';
  static const _nameKey = 'printing.ticket_printer.name';
  static const _copiesKey = 'printing.ticket_copies';

  final FlutterSecureStorage _storage;

  const SecureTicketPrinterSettingsStore(this._storage);

  @override
  Future<TicketPrinterSettings> read() async {
    try {
      final mac = (await _storage.read(key: _macKey))?.trim();
      final name = (await _storage.read(key: _nameKey))?.trim() ?? '';
      final copies = int.tryParse(await _storage.read(key: _copiesKey) ?? '');
      return TicketPrinterSettings(
        printer: mac == null || mac.isEmpty
            ? null
            : ThermalPrinter(name: name, macAddress: mac),
        copies: copies == null ? null : TicketCopies.clamp(copies),
      );
    } catch (_) {
      // Keystore réinitialisé après une restauration : on repart du choix
      // manuel, le pire cas acceptable.
      return const TicketPrinterSettings();
    }
  }

  @override
  Future<void> savePrinter(ThermalPrinter? printer) async {
    try {
      if (printer == null) {
        await _storage.delete(key: _macKey);
        await _storage.delete(key: _nameKey);
        return;
      }
      await _storage.write(key: _macKey, value: printer.macAddress);
      await _storage.write(key: _nameKey, value: printer.name);
    } catch (_) {
      // Le choix vaut pour cette impression ; il sera à refaire.
    }
  }

  @override
  Future<void> saveCopies(int? copies) async {
    try {
      if (copies == null) {
        await _storage.delete(key: _copiesKey);
      } else {
        await _storage.write(
          key: _copiesKey,
          value: '${TicketCopies.clamp(copies)}',
        );
      }
    } catch (_) {}
  }
}
