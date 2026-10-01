import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_file_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/grid/staff_agent_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/list/staff_agent_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff_builders.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

class _MockSource extends Mock implements StaffSnapshotSource {}

void main() {
  late _MockSource source;

  setUp(() {
    source = _MockSource();
    when(() => source.watch(any())).thenReturn(() {});
    when(() => source.pull()).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    StaffFileSnapshot snapshot, {
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => source.read()).thenAnswer((_) async => Right(snapshot));
    final cubit = StaffFileCubit(
      source: source,
      now: () => DateTime(2026, 9, 29),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit..load(),
            child: const StaffFileScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  final file = StaffFileSnapshot(
    members: [
      member(
        'm-1',
        lastName: 'Kalala',
        firstName: 'Jean',
        contracts: [period(StaffContractKind.permanent)],
      ),
      member(
        'm-2',
        lastName: 'Mbuyi',
        firstName: 'Élodie',
        staffNumber: null,
        syncState: RecordSyncState.pending,
      ),
    ],
    documentsByMember: {
      'm-1': [
        document('m-1', 'ID'),
        document('m-1', 'DP'),
        document('m-1', 'LD'),
      ],
    },
    documentTypes: documentTypes,
    hasEverSynced: true,
  );

  testWidgets('les agents en cartes, leur contrat, leur dossier et le pied', (
    tester,
  ) async {
    await pumpScreen(tester, file);

    expect(find.byType(StaffAgentCard), findsNWidgets(2));
    expect(find.text('Kalala Mutombo Jean'), findsOneWidget);
    expect(find.text('Matricule en attente'), findsOneWidget);
    expect(find.text('Dossier complet'), findsOneWidget);
    expect(find.text('0/2 pièces'), findsOneWidget);
    expect(find.text('2 agents au fichier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la bascule Liste montre le tableau', (tester) async {
    await pumpScreen(tester, file);

    await tester.tap(find.text('Liste'));
    await tester.pump();

    expect(find.byType(StaffAgentTable), findsOneWidget);
    expect(find.text('AGENT'), findsOneWidget);
    expect(find.text('Sur la tablette'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un filtre trop étroit propose de réinitialiser', (tester) async {
    await pumpScreen(tester, file);

    await tester.enterText(find.byType(EditableText).first, 'introuvable');
    await tester.pump();

    expect(find.text('Aucun agent trouvé'), findsOneWidget);
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pump();
    expect(find.byType(StaffAgentCard), findsNWidgets(2));
  });

  testWidgets('un fichier vide le dit', (tester) async {
    await pumpScreen(
      tester,
      const StaffFileSnapshot(
        members: [],
        documentsByMember: {},
        documentTypes: [],
        hasEverSynced: true,
      ),
    );

    expect(find.text('Aucun agent dans le fichier'), findsOneWidget);
  });

  testWidgets('jamais reçu et hors ligne : on travaille quand même', (
    tester,
  ) async {
    await pumpScreen(tester, StaffFileSnapshot.empty);

    expect(find.textContaining("n'a pas encore été reçu"), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('Aucun agent dans le fichier'), findsOneWidget);
  });

  testWidgets('jamais reçu : les agents créés ici se listent sous le bandeau', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      StaffFileSnapshot(
        members: [member('m-1', syncState: RecordSyncState.pending)],
        documentsByMember: const {},
        documentTypes: const [],
        hasEverSynced: false,
      ),
    );

    expect(find.textContaining("n'a pas encore été reçu"), findsOneWidget);
    expect(find.byType(StaffAgentCard), findsOneWidget);
    expect(find.text('Nouvel agent'), findsOneWidget);
  });

  testWidgets('à 360 dp, ni la grille ni le tableau ne débordent', (
    tester,
  ) async {
    await pumpScreen(tester, file, size: const Size(360, 800));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Liste'));
    await tester.pump();
    expect(find.byType(StaffAgentTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
