import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_contract_form_page.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff_builders.dart';
import 'staff_agent_harness.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

const _contract = StaffContract(
  id: 'c-1',
  staffMemberId: 'm-1',
  kind: StaffContractKind.permanent,
  effectiveFrom: '2025-09-01',
  recordedAt: '2025-09-01T08:00:00Z',
  syncState: RecordSyncState.synced,
  amount: Money(32000, 'USD'),
);

void main() {
  final getIt = GetIt.instance;
  late StaffAgentHarness h;
  final agent = member(
    'm-1',
    contracts: [period(StaffContractKind.permanent, from: '2025-09-01')],
  );

  setUpAll(StaffAgentHarness.registerFallbacks);
  setUp(() {
    (h = StaffAgentHarness()).register(getIt);
    when(
      () => h.loadContracts('m-1'),
    ).thenAnswer((_) async => const Right([_contract]));
    when(() => h.loadDossier('m-1')).thenAnswer(
      (_) async => Right(
        StaffDossierSnapshot(
          types: documentTypes,
          documents: [document('m-1', 'ID')],
        ),
      ),
    );
  });
  tearDown(() async => getIt.reset());

  Future<void> contractsOf(WidgetTester tester, List<String> perms) async {
    await h.pump(tester, member: agent, permissions: perms);
    await StaffAgentHarness.openStep(tester, 'Poste & contrat');
  }

  Future<void> documentsOf(WidgetTester tester, List<String> perms) async {
    await h.pump(tester, member: agent, permissions: perms);
    await StaffAgentHarness.openStep(tester, 'Diplômes & pièces');
  }

  group('contrats', () {
    testWidgets('sans hr.pay.read : la frise, jamais un montant', (
      tester,
    ) async {
      await contractsOf(tester, const ['hr.staff.read', 'hr.pay.write']);

      expect(find.text('Depuis le 01/09/2025'), findsOneWidget);
      expect(find.textContaining('Salaire'), findsNothing);
      expect(find.text('Nouveau contrat'), findsOneWidget);
      // Corriger exige de voir ce qu'on corrige.
      expect(find.text('Corriger'), findsNothing);
    });

    testWidgets('sans hr.pay.write : lecture seule', (tester) async {
      await contractsOf(tester, const ['hr.staff.read', 'hr.pay.read']);

      expect(find.textContaining('Salaire'), findsOneWidget);
      expect(find.text('Nouveau contrat'), findsNothing);
      expect(find.text('Corriger'), findsNothing);
    });

    testWidgets('lecture et écriture : poser et corriger', (tester) async {
      await contractsOf(tester, const [
        'hr.staff.read',
        'hr.pay.read',
        'hr.pay.write',
      ]);

      expect(find.text('Nouveau contrat'), findsOneWidget);
      expect(find.text('Corriger'), findsOneWidget);
    });
  });

  group('pièces', () {
    testWidgets('sans hr.document.read : verser, jamais voir', (tester) async {
      await documentsOf(tester, const ['hr.staff.read', 'hr.document.write']);

      expect(find.text('Remplacer'), findsOneWidget);
      expect(find.text('Voir'), findsNothing);
    });

    testWidgets('sans hr.document.write : voir, jamais verser', (tester) async {
      await documentsOf(tester, const ['hr.staff.read', 'hr.document.read']);

      expect(find.text('Voir'), findsOneWidget);
      expect(find.text('Verser'), findsNothing);
      expect(find.text('Remplacer'), findsNothing);
    });

    testWidgets('ni l un ni l autre : aucun bloc de pièces', (tester) async {
      await documentsOf(tester, const ['hr.staff.read']);

      expect(find.text('Pièces du dossier'), findsNothing);
    });
  });

  group('correction', () {
    Future<StaffContractFormResult?> openCorrection(
      WidgetTester tester, {
      Size size = const Size(1280, 900),
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      StaffContractFormResult? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await StaffContractFormPage.open(
                context,
                initial: const StaffContractDraft(
                  kind: StaffContractKind.vacataire,
                  payMode: StaffPayMode.hourly,
                  effectiveFrom: '2025-09-01',
                  amount: '5',
                  reason: 'Doublon',
                ),
                correcting: true,
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('à 360 dp, les deux boutons tiennent', (tester) async {
      await openCorrection(tester, size: const Size(360, 640));

      expect(tester.takeException(), isNull);
      expect(find.text('Annuler seulement'), findsOneWidget);
      expect(find.text('Remplacer la période'), findsOneWidget);
    });

    testWidgets('re-toucher le statut choisi garde le mode de paiement', (
      tester,
    ) async {
      await openCorrection(tester);

      await tester.tap(find.text('Vacataire').first);
      await tester.pump();
      await tester.tap(find.text('Remplacer la période'));
      await tester.pumpAndSettle();

      expect(find.text('Champ requis'), findsNothing);
      expect(find.byType(StaffContractFormPage), findsNothing);
    });

    testWidgets('annuler seulement se confirme', (tester) async {
      await openCorrection(tester);

      await tester.tap(find.text('Annuler seulement'));
      await tester.pumpAndSettle();
      expect(find.text('Annuler cette période ?'), findsOneWidget);

      await tester.tap(find.text('Revenir'));
      await tester.pumpAndSettle();
      expect(find.byType(StaffContractFormPage), findsOneWidget);
    });
  });
}
