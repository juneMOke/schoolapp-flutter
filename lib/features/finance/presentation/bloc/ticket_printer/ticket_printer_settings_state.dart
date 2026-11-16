import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';

enum TicketPrinterTest { idle, sending, sent, failed }

class TicketPrinterSettingsState extends Equatable {
  final bool loading;

  /// Les permissions « Appareils à proximité » qui manquent.
  final Set<NearbyPermission> missing;

  /// Android ne la redemandera plus (refus définitif, ou gestion de parc) :
  /// seuls les réglages, ou la console d'administration, la débloquent.
  final bool blocked;

  /// Pourquoi la liste des imprimantes n'a pas pu se lire (Bluetooth éteint…).
  final ThermalPrinterProblem? problem;
  final List<ThermalPrinter> printers;
  final ThermalPrinter? selected;
  final int copies;

  /// Les exemplaires viennent de la tablette, pas du réglage de l'école.
  final bool copiesFromDevice;
  final TicketPrinterTest test;

  /// L'imprimante où l'essai est parti — pas forcément la retenue à l'écran.
  final ThermalPrinter? testPrinter;
  final ThermalPrinterProblem? testProblem;

  const TicketPrinterSettingsState({
    this.loading = true,
    this.missing = const {},
    this.blocked = false,
    this.problem,
    this.printers = const [],
    this.selected,
    this.copies = TicketCopies.fallback,
    this.copiesFromDevice = false,
    this.test = TicketPrinterTest.idle,
    this.testPrinter,
    this.testProblem,
  });

  /// L'imprimante retenue n'est plus parmi les appairées.
  bool get selectedGone =>
      selected != null &&
      printers.isNotEmpty &&
      printers.every((p) => p.macAddress != selected!.macAddress);

  TicketPrinterSettingsState copyWith({
    bool? loading,
    Set<NearbyPermission>? missing,
    bool? blocked,
    ThermalPrinterProblem? Function()? problem,
    List<ThermalPrinter>? printers,
    ThermalPrinter? Function()? selected,
    int? copies,
    bool? copiesFromDevice,
    TicketPrinterTest? test,
    ThermalPrinter? Function()? testPrinter,
    ThermalPrinterProblem? Function()? testProblem,
  }) => TicketPrinterSettingsState(
    loading: loading ?? this.loading,
    missing: missing ?? this.missing,
    blocked: blocked ?? this.blocked,
    problem: problem == null ? this.problem : problem(),
    printers: printers ?? this.printers,
    selected: selected == null ? this.selected : selected(),
    copies: copies ?? this.copies,
    copiesFromDevice: copiesFromDevice ?? this.copiesFromDevice,
    test: test ?? this.test,
    testPrinter: testPrinter == null ? this.testPrinter : testPrinter(),
    testProblem: testProblem == null ? this.testProblem : testProblem(),
  );

  @override
  List<Object?> get props => [
    loading,
    missing,
    blocked,
    problem,
    printers,
    selected,
    copies,
    copiesFromDevice,
    test,
    testPrinter,
    testProblem,
  ];
}
