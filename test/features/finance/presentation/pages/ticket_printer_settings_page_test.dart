import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/ticket_printer/ticket_printer_settings_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/ticket_printer_settings_page.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/memory_ticket_printer_settings.dart';
import '../../../../test_helpers/reference_formats.dart';

const _netum = ThermalPrinter(name: 'NT-8003DD', macAddress: 'DC:0D:30:11');
const _pos = ThermalPrinter(name: 'POS-58', macAddress: 'AA:BB:CC:DD');

class _Port implements ThermalPrinterPort {
  List<ThermalPrinter> printers = const [_netum, _pos];
  ThermalPrinterProblem? readyProblem;
  Completer<void>? gate;
  final List<String> sentTo = [];

  @override
  Future<Either<Failure, Unit>> ensureReady() async {
    final problem = readyProblem;
    return problem == null
        ? const Right(unit)
        : Left(ThermalPrinterFailure(problem));
  }

  @override
  Future<Either<Failure, List<ThermalPrinter>>> pairedPrinters() async =>
      Right(printers);

  @override
  Future<Either<Failure, Unit>> printBytes(
    Uint8List bytes, {
    required String macAddress,
    int copies = 1,
  }) async {
    sentTo.add(macAddress);
    await gate?.future;
    return const Right(unit);
  }
}

class _Permission
    implements ThermalPrinterPermission, ThermalPrinterPermissionDetails {
  Set<NearbyPermission> absent = const {};
  ThermalPrinterPermissionState answer = ThermalPrinterPermissionState.granted;
  int settingsOpened = 0;

  @override
  Future<Set<NearbyPermission>> missing() async => absent;

  @override
  Future<bool> isGranted() async => absent.isEmpty;

  @override
  Future<ThermalPrinterPermissionState> request() async {
    if (answer == ThermalPrinterPermissionState.granted) absent = const {};
    return answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class _Schools implements SchoolRepository {
  @override
  Future<Either<Failure, School?>> loadCurrentSchool() async =>
      const Right(School(id: 'A', name: 'EP', ticketCopies: 2));

  @override
  Future<Either<Failure, SchoolLogo?>> loadCurrentSchoolLogo() async =>
      const Right(null);
}

/// Finances ▸ Imprimante de tickets.
void main() {
  late _Port port;
  late _Permission permission;
  late MemoryTicketPrinterSettings store;

  setUp(() {
    port = _Port();
    permission = _Permission();
    store = MemoryTicketPrinterSettings();
  });

  Future<void> open(WidgetTester tester, {bool thermal = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => TicketPrinterSettingsCubit(
              port,
              permission,
              permission,
              store,
              ResolveTicketCopiesUseCase(_Schools(), device: store),
              thermal: thermal,
            )..load(),
            child: const TicketPrinterSettingsView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testAtReferenceFormats('l écran tient sur tous les formats', (
    tester,
    _,
  ) async {
    // Le cas de l'école : la gestion de parc accorde SCAN, pas CONNECT.
    permission.absent = const {NearbyPermission.connect};
    await open(tester);

    expect(find.textContaining('BLUETOOTH_CONNECT'), findsOneWidget);
    expect(find.textContaining('BLUETOOTH_SCAN'), findsNothing);
    expect(find.text('Autoriser'), findsOneWidget);
  });

  testWidgets('refus définitif : seul le chemin des réglages reste', (
    tester,
  ) async {
    permission
      ..absent = const {NearbyPermission.connect, NearbyPermission.scan}
      ..answer = ThermalPrinterPermissionState.permanentlyDenied;
    await open(tester);

    await tester.tap(find.text('Autoriser'));
    await tester.pumpAndSettle();
    expect(find.text('Autoriser'), findsNothing);

    await tester.tap(find.text('Ouvrir les réglages Android'));
    expect(permission.settingsOpened, 1);
  });

  testWidgets('l imprimante choisie est retenue, et l essai y part', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('Choisissez l\'imprimante'), findsOneWidget);

    await tester.tap(find.text('POS-58'));
    await tester.pumpAndSettle();
    expect(store.printer, _pos);

    await tester.tap(find.text('Imprimer un ticket d\'essai'));
    await tester.pumpAndSettle();
    expect(port.sentTo, [_pos.macAddress]);
    expect(find.text('Ticket d\'essai envoyé sur POS-58.'), findsOneWidget);
  });

  testWidgets('l imprimante retenue désappairée se signale', (tester) async {
    store.printer = const ThermalPrinter(name: 'Vieille', macAddress: '00:00');
    await open(tester);

    expect(find.textContaining('Vieille'), findsOneWidget);
    expect(find.text('Imprimer un ticket d\'essai'), findsNothing);
  });

  testWidgets(
    'les exemplaires partent du réglage de l école, puis se règlent',
    (tester) async {
      await open(tester);
      expect(find.text('2'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Un exemplaire de plus'));
      await tester.tap(find.byTooltip('Un exemplaire de plus'));
      await tester.pumpAndSettle();
      expect(store.copies, 3);
    },
  );

  testWidgets('poste de bureau : seulement les exemplaires', (tester) async {
    await open(tester, thermal: false);

    expect(find.textContaining('imprimante du système'), findsOneWidget);
    expect(find.text('Autorisation Bluetooth'), findsNothing);
    expect(find.text('Exemplaires par défaut'), findsOneWidget);
  });

  testAtReferenceFormats('l état complet tient sur tous les formats', (
    tester,
    _,
  ) async {
    store
      ..printer = _netum
      ..copies = 3;
    await open(tester);

    expect(find.text('NT-8003DD'), findsOneWidget);
    expect(find.text('Imprimer un ticket d\'essai'), findsOneWidget);
    expect(find.text('Reprendre le réglage de l\'école'), findsOneWidget);
  });

  testWidgets('pendant un essai, l imprimante ne change pas', (tester) async {
    store.printer = _pos;
    port.gate = Completer<void>();
    await open(tester);

    await tester.tap(find.text('Imprimer un ticket d\'essai'));
    await tester.pump();
    await tester.tap(find.text('NT-8003DD'));
    await tester.pump();
    expect(store.printer, _pos);

    port.gate!.complete();
    await tester.pumpAndSettle();
    expect(port.sentTo, [_pos.macAddress]);
    expect(find.text('Ticket d\'essai envoyé sur POS-58.'), findsOneWidget);
  });

  testWidgets('les exemplaires reviennent au réglage de l école', (
    tester,
  ) async {
    store.copies = 4;
    await open(tester);
    expect(find.text('4'), findsOneWidget);

    await tester.ensureVisible(find.text('Reprendre le réglage de l\'école'));
    await tester.tap(find.text('Reprendre le réglage de l\'école'));
    await tester.pumpAndSettle();

    expect(store.copies, isNull);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Reprendre le réglage de l\'école'), findsNothing);
  });

  testWidgets('un refus vu par le canal natif se dit comme une permission', (
    tester,
  ) async {
    port.readyProblem = ThermalPrinterProblem.permissionDenied;
    await open(tester);

    expect(find.textContaining('BLUETOOTH_CONNECT'), findsOneWidget);
    expect(find.text('Autoriser'), findsOneWidget);
  });
}
