import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Depuis la convergence offline-first (étape c), la suppression d'un tuteur est
/// LOCALE (retrait immédiat de la liste) puis ré-écriture du brouillon via
/// `EnrollmentOfflineBloc` — plus d'unlink online via ParentBloc.
class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOfflineBloc offlineBloc;

  setUpAll(() {
    registerFallbackValue(
      const SaveDraftGuardiansRequested(studentId: 'x', parents: []),
    );
  });

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

  const testParent2 = ParentSummary(
    id: 'parent-2',
    firstName: 'Marie',
    lastName: 'Martin',
    surname: 'L',
    identificationNumber: 'ID-456',
    phoneNumber: '+243111111111',
    email: 'marie.martin@example.com',
    relationshipType: RelationshipType.mother,
  );

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    when(
      () => offlineBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());
  });

  Future<void> pumpGuardianStep(
    WidgetTester tester, {
    List<ParentSummary> parents = const [testParent, testParent2],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<EnrollmentOfflineBloc>.value(
            value: offlineBloc,
            child: GuardianInfoStep(
              parentDetails: parents,
              studentId: 'student-1',
              enrollmentId: 'enrollment-1',
              showInlineSaveButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('clic supprimer puis annuler conserve le tuteur dans la liste', (
    tester,
  ) async {
    await pumpGuardianStep(tester);

    const parentItemKey = ValueKey<String>('parent-item-parent-1');
    expect(find.byKey(parentItemKey), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
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
    // Aucune écriture de brouillon (annulation).
    verifyNever(() => offlineBloc.add(any()));
  });

  testWidgets('clic supprimer puis confirmer retire le tuteur en LOCAL + '
      'ré-écrit le brouillon', (tester) async {
    await pumpGuardianStep(tester);

    const parentItemKey = ValueKey<String>('parent-item-parent-1');
    expect(find.byKey(parentItemKey), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la suppression'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    // pump (pas pumpAndSettle) : la ré-écriture du brouillon laisse un
    // indicateur de sauvegarde actif (le mock n'émet pas d'état « sauvé »),
    // donc l'arbre ne se stabilise jamais complètement.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Retrait immédiat (local) — plus d'attente d'un ACK serveur.
    expect(find.byKey(parentItemKey), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('parent-item-parent-2')),
      findsOneWidget,
    );
    // La liste restante (non vide) est ré-écrite dans le brouillon local.
    verify(
      () => offlineBloc.add(any(that: isA<SaveDraftGuardiansRequested>())),
    ).called(1);
  });

  testWidgets('dismiss de la popup sans confirmer conserve le tuteur', (
    tester,
  ) async {
    await pumpGuardianStep(tester);

    const parentItemKey = ValueKey<String>('parent-item-parent-1');
    expect(find.byKey(parentItemKey), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la suppression'), findsOneWidget);

    // Tap sur la barrière modale (hors dialog) pour fermer sans confirmer.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la suppression'), findsNothing);
    expect(find.byKey(parentItemKey), findsOneWidget);
    expect(find.text('Aucune information de tuteur disponible'), findsNothing);
  });

  testWidgets('un seul tuteur : la corbeille est masquée', (tester) async {
    await pumpGuardianStep(tester, parents: const [testParent]);

    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });
}
