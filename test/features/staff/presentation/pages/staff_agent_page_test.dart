import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../staff_builders.dart';

class _MockSave extends Mock implements SaveStaffMemberUseCase {}

class _MockLoad extends Mock implements LoadStaffMemberUseCase {}

void main() {
  final getIt = GetIt.instance;
  late _MockSave save;

  setUpAll(() => registerFallbackValue(const StaffMemberDraft(id: 'x')));

  setUp(() {
    save = _MockSave();
    getIt
      ..registerSingleton<SaveStaffMemberUseCase>(save)
      ..registerSingleton<LoadStaffMemberUseCase>(_MockLoad())
      ..registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
  });
  tearDown(() async => getIt.reset());

  Future<void> pumpPage(
    WidgetTester tester, {
    StaffMember? member,
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StaffAgentPage(
          member: member,
          kind: member == null ? null : StaffContractKind.permanent,
          others: const [],
          today: '2026-09-29',
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('création : pas d erreur au premier regard, puis après Suivant', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Nouvel agent'), findsOneWidget);
    expect(find.text('NOUVEL AGENT · ÉTAPE 1 SUR 4'), findsOneWidget);
    expect(find.text('Champ requis'), findsNothing);

    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('5 champs à corriger'), findsOneWidget);
    expect(find.text('Champ requis'), findsWidgets);
    expect(tester.takeException(), isNull);
    verifyNever(() => save(any()));
  });

  testWidgets('consultation : lecture seule, et Modifier le profil', (
    tester,
  ) async {
    await pumpPage(tester, member: member('m-1', firstName: 'Jean'));

    expect(find.text('Jean Kalala'), findsOneWidget);
    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);
    expect(find.text('CF-AG-0001'), findsOneWidget);

    await tester.tap(find.text('Modifier le profil'));
    await tester.pump();

    expect(find.text('MODIFICATION DU PROFIL'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en modification, les étapes sont libres', (tester) async {
    await pumpPage(tester, member: member('m-1'));

    await tester.tap(find.text('Poste & contrat'));
    await tester.pump();

    expect(find.text('Poste'), findsOneWidget);
    expect(find.text('Enseignant titulaire'), findsWidgets);
  });

  testWidgets('abandonner une modification demande confirmation', (
    tester,
  ) async {
    await pumpPage(tester, member: member('m-1', firstName: 'Jean'));
    await tester.tap(find.text('Modifier le profil'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText).at(2), 'Paul');
    await tester.pump();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Abandonner les modifications ?'), findsOneWidget);
    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Jean Kalala'), findsOneWidget);
  });

  testWidgets('téléphone en paysage : rien ne déborde', (tester) async {
    await pumpPage(tester, size: const Size(640, 360));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
