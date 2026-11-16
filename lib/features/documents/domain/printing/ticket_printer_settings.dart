import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';

/// Les réglages d'impression des tickets de **cette tablette** (Finances ▸
/// Imprimante de tickets) : l'imprimante où partent les tickets, et combien
/// d'exemplaires sortent par défaut.
///
/// Propres à l'appareil, jamais synchronisés : chaque guichet a son
/// imprimante. `null` : rien n'a encore été réglé ici.
class TicketPrinterSettings extends Equatable {
  /// L'imprimante retenue. Sans elle, le choix se fait à la première
  /// impression, puis il est retenu.
  final ThermalPrinter? printer;

  /// Les exemplaires de ce poste ; sans eux, le réglage de l'école.
  final int? copies;

  const TicketPrinterSettings({this.printer, this.copies});

  @override
  List<Object?> get props => [printer, copies];
}

/// Où ces réglages se gardent.
abstract interface class TicketPrinterSettingsStore {
  /// Ne lève jamais : un magasin illisible se lit « rien de réglé ».
  Future<TicketPrinterSettings> read();

  /// `null` oublie l'imprimante.
  Future<void> savePrinter(ThermalPrinter? printer);

  /// `null` rend la main au réglage de l'école.
  Future<void> saveCopies(int? copies);
}
