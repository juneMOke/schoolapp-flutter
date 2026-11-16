import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_printer_settings.dart';

/// Les réglages d'impression de la tablette, en mémoire : rien de retenu au
/// départ, le premier ticket ouvre donc le sélecteur.
class MemoryTicketPrinterSettings implements TicketPrinterSettingsStore {
  ThermalPrinter? printer;
  int? copies;

  MemoryTicketPrinterSettings({this.printer, this.copies});

  @override
  Future<TicketPrinterSettings> read() async =>
      TicketPrinterSettings(printer: printer, copies: copies);

  @override
  Future<void> savePrinter(ThermalPrinter? printer) async =>
      this.printer = printer;

  @override
  Future<void> saveCopies(int? copies) async => this.copies = copies;
}
