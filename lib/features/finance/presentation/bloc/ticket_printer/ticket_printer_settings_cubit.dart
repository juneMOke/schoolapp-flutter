import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_printer_settings.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/ticket_printer/ticket_printer_settings_state.dart';

export 'ticket_printer_settings_state.dart';

/// Finances ▸ Imprimante de tickets : l'autorisation Bluetooth, l'imprimante
/// de la tablette et ses exemplaires par défaut.
///
/// [thermal] est faux sur le poste et le navigateur : les tickets y passent
/// par l'imprimante du système, seuls les exemplaires se règlent.
class TicketPrinterSettingsCubit extends Cubit<TicketPrinterSettingsState> {
  final ThermalPrinterPort _port;
  final ThermalPrinterPermission _permission;
  final ThermalPrinterPermissionDetails _details;
  final TicketPrinterSettingsStore _store;
  final ResolveTicketCopiesUseCase _copies;
  final bool thermal;

  TicketPrinterSettingsCubit(
    this._port,
    this._permission,
    this._details,
    this._store,
    this._copies, {
    required this.thermal,
  }) : super(const TicketPrinterSettingsState());

  /// Relit tout : à l'ouverture, et au retour des réglages Android.
  Future<void> load() async {
    final settings = await _store.read();
    final copies = await _copies();
    if (isClosed) return;
    var next = state.copyWith(
      loading: false,
      selected: () => settings.printer,
      copies: copies,
      copiesFromDevice: settings.copies != null,
    );
    if (!thermal) return emit(next);

    final missing = await _details.missing();
    if (isClosed) return;
    next = next.copyWith(missing: missing, problem: () => null);
    if (missing.isNotEmpty) return emit(next.copyWith(printers: const []));

    final ready = await _port.ensureReady();
    final problem = ready.fold(
      (failure) => failure is ThermalPrinterFailure
          ? failure.problem
          : ThermalPrinterProblem.unreachable,
      (_) => null,
    );
    // Le canal natif constate un refus que le détail n'a pas vu : c'est
    // CONNECT, la seule qu'il sache lire. L'écran le dit au même endroit.
    if (problem == ThermalPrinterProblem.permissionDenied) {
      if (!isClosed) {
        emit(
          next.copyWith(
            missing: const {NearbyPermission.connect},
            printers: const [],
          ),
        );
      }
      return;
    }
    if (problem != null) {
      if (!isClosed) {
        emit(next.copyWith(problem: () => problem, printers: const []));
      }
      return;
    }
    final listed = await _port.pairedPrinters();
    if (isClosed) return;
    emit(
      listed.fold(
        (_) => next.copyWith(
          problem: () => ThermalPrinterProblem.unreachable,
          printers: const [],
        ),
        (printers) => next.copyWith(
          printers: printers,
          problem: () =>
              printers.isEmpty ? ThermalPrinterProblem.noPrinterSelected : null,
        ),
      ),
    );
  }

  /// La boîte de dialogue d'Android, quand elle peut encore s'ouvrir.
  Future<void> requestPermission() async {
    final answer = await _permission.request();
    if (isClosed) return;
    emit(
      state.copyWith(
        blocked: answer == ThermalPrinterPermissionState.permanentlyDenied,
      ),
    );
    await load();
  }

  Future<void> openSystemSettings() => _permission.openSettings();

  Future<void> select(ThermalPrinter printer) async {
    // Pendant un essai, la liaison est à lui : changer d'imprimante lancerait
    // un second envoi qui couperait le premier.
    if (state.test == TicketPrinterTest.sending) return;
    await _store.savePrinter(printer);
    if (!isClosed) {
      emit(
        state.copyWith(
          selected: () => printer,
          test: TicketPrinterTest.idle,
          testProblem: () => null,
        ),
      );
    }
  }

  Future<void> copiesChanged(int copies) async {
    final value = TicketCopies.clamp(copies);
    emit(state.copyWith(copies: value, copiesFromDevice: true));
    await _store.saveCopies(value);
  }

  /// La tablette rend la main au réglage de l'école, qui suivra ses
  /// changements.
  Future<void> useSchoolCopies() async {
    await _store.saveCopies(null);
    final copies = await _copies();
    if (!isClosed) {
      emit(state.copyWith(copies: copies, copiesFromDevice: false));
    }
  }

  /// Un ticket d'essai, un exemplaire, sur l'imprimante retenue.
  Future<void> testPrint(List<String> lines) async {
    final printer = state.selected;
    if (printer == null || state.test == TicketPrinterTest.sending) return;
    emit(
      state.copyWith(
        test: TicketPrinterTest.sending,
        testPrinter: () => printer,
        testProblem: () => null,
      ),
    );
    final sent = await _port.printBytes(
      EscPosTicketRenderer.renderLines(lines),
      macAddress: printer.macAddress,
    );
    if (isClosed) return;
    emit(
      sent.fold(
        (failure) => state.copyWith(
          test: TicketPrinterTest.failed,
          testProblem: () => failure is ThermalPrinterFailure
              ? failure.problem
              : ThermalPrinterProblem.unreachable,
        ),
        (_) => state.copyWith(test: TicketPrinterTest.sent),
      ),
    );
  }
}
