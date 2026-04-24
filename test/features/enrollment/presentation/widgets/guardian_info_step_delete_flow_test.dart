import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/parent_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockParentBloc extends MockBloc<ParentEvent, ParentState>
    implements ParentBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockParentBloc mockParentBloc;

  const testParent = ParentSummary(
    id: 'parent-1',
    firstName: 'Jean',
    lastName: 'Dupont',
    surname: 'K',
    identificationNumber: 'ID-123',
    phoneNumber: '+243000000000',
    email: 'jean.dupont@example.com',
    relationshipType: RelationshipType.guardian,
  );

  Future<void> pumpGuardianStep(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GuardianInfoStep(
            parentDetails: [testParent],
            studentId: 'student-1',
            enrollmentId: 'enrollment-1',
            showInlineSaveButton: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await getIt.reset();

    mockParentBloc = MockParentBloc();
    when(() => mockParentBloc.state).thenReturn(const ParentState.initial());
    whenListen(
      mockParentBloc,
      const Stream<ParentState>.empty(),
      initialState: const ParentState.initial(),
    );

    getIt.registerFactory<ParentBloc>(() => mockParentBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('clic supprimer puis annuler conserve le tuteur dans la liste', (
    tester,
  ) async {
    await pumpGuardianStep(tester);

    const parentItemKey = ValueKey<String>('parent-item-parent-1');
    expect(find.byKey(parentItemKey), findsOneWidget);

    await tester.tap(find.text('Supprimer ce tuteur').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la suppression'), findsOneWidget);
    expect(
      find.text(
        'Voulez-vous vraiment supprimer ce tuteur ? Cette action est irréversible.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.byKey(parentItemKey), findsOneWidget);
    expect(find.text('Confirmer la suppression'), findsNothing);
  });

  testWidgets('clic supprimer puis confirmer retire le tuteur', (tester) async {
    // Prépare un StreamController pour simuler la réponse API du bloc.
    final controller = StreamController<ParentState>();

    final unlinkBloc = MockParentBloc();
    when(() => unlinkBloc.state).thenReturn(const ParentState.initial());
    whenListen(unlinkBloc, controller.stream,
        initialState: const ParentState.initial());

    // Redirige l'injection vers ce bloc.
    await getIt.reset();
    getIt.registerFactory<ParentBloc>(() => unlinkBloc);

    await pumpGuardianStep(tester);

    const parentItemKey = ValueKey<String>('parent-item-parent-1');
    expect(find.byKey(parentItemKey), findsOneWidget);

    await tester.tap(find.text('Supprimer ce tuteur').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la suppression'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    // Simule la réponse succès de l'API.
    controller.add(
      const ParentState.initial()
          .copyWith(status: ParentUpdateStatus.unlinkSuccess),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(parentItemKey), findsNothing);
    expect(
      find.text('Aucune information de tuteur disponible'),
      findsOneWidget,
    );

    await controller.close();
  });

  testWidgets(
    'dismiss de la popup sans confirmer conserve le tuteur',
    (tester) async {
      await pumpGuardianStep(tester);

      const parentItemKey = ValueKey<String>('parent-item-parent-1');
      expect(find.byKey(parentItemKey), findsOneWidget);

      await tester.tap(find.text('Supprimer ce tuteur').first);
      await tester.pumpAndSettle();

      expect(find.text('Confirmer la suppression'), findsOneWidget);

      // Tap sur la barrière modale (hors dialog) pour fermer sans confirmer.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Confirmer la suppression'), findsNothing);
      expect(find.byKey(parentItemKey), findsOneWidget);
      expect(find.text('Aucune information de tuteur disponible'), findsNothing);
    },
  );
}