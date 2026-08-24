import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_parents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockSearchParentsUseCase extends Mock implements SearchParentsUseCase {}

const _conflictedPhone = '+243816939060';

/// Le tuteur en cours de saisie : c'est SON numéro que la garde d'unicité
/// refusera, et c'est SA carte que la fiche retenue doit remplacer.
const _editedParent = ParentSummary(
  id: 'draft-parent-1',
  firstName: 'Jean',
  lastName: 'Dupont',
  surname: 'K',
  identificationNumber: '',
  phoneNumber: _conflictedPhone,
  email: '',
  relationshipType: RelationshipType.father,
);

const _secondParent = ParentSummary(
  id: 'draft-parent-2',
  firstName: 'Marie',
  lastName: 'Kabila',
  surname: null,
  identificationNumber: '',
  phoneNumber: _conflictedPhone, // MÊME numéro : doublon interne au dossier
  email: '',
  relationshipType: RelationshipType.mother,
);

/// La fiche déjà en base qui porte ce numéro.
const _ownerParent = LocalParent(
  id: 'existing-parent-42',
  firstName: 'Sarah',
  lastName: 'Moke',
  surname: 'Junior',
  phoneNumber: _conflictedPhone,
  email: 'sarah.moke@example.com',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOfflineBloc offlineBloc;
  late _MockSearchParentsUseCase searchUseCase;
  late StreamController<EnrollmentOfflineState> states;

  setUpAll(() {
    registerFallbackValue(
      const SaveDraftGuardiansRequested(studentId: 'x', parents: []),
    );
  });

  setUp(() {
    states = StreamController<EnrollmentOfflineState>.broadcast();
    offlineBloc = _MockOfflineBloc();
    when(() => offlineBloc.stream).thenAnswer((_) => states.stream);
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());

    searchUseCase = _MockSearchParentsUseCase();
    when(
      () => searchUseCase(
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        surname: any(named: 'surname'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    ).thenAnswer((_) async => const Right([_ownerParent]));

    getIt.registerLazySingleton<IdGenerator>(() => const IdGenerator(Uuid()));
    getIt.registerFactory<ParentSearchBloc>(
      () => ParentSearchBloc(search: searchUseCase),
    );
  });

  tearDown(() async {
    await states.close();
    await getIt.reset();
  });

  Finder textFieldLabeled(Finder ancestor, String label) => find.descendant(
    of: find.descendant(
      of: ancestor,
      matching: find.byWidgetPredicate(
        (w) => w is EteeloTextInput && w.label == label,
      ),
    ),
    matching: find.byType(TextField),
  );

  Future<void> pumpStep(
    WidgetTester tester, {
    List<ParentSummary> parents = const [_editedParent],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<EnrollmentOfflineBloc>.value(
            value: offlineBloc,
            child: SizedBox(
              width: 380,
              child: GuardianInfoStep(
                parentDetails: parents,
                studentId: 'student-1',
                enrollmentId: 'enrollment-1',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Rejoue le parcours réel : l'utilisateur retouche la fiche, enregistre, et
  /// la garde d'unicité locale refuse le numéro.
  Future<void> enregistrerPuisRefuser(
    WidgetTester tester, {
    String phoneNumber = _conflictedPhone,
  }) async {
    final carte = find.byKey(
      ValueKey<String>('parent-item-${_editedParent.id}'),
    );
    await tester.enterText(textFieldLabeled(carte, 'Prénom'), 'Jean-Pierre');
    await tester.pumpAndSettle();

    final enregistrer = find.text('Enregistrer');
    await tester.ensureVisible(enregistrer);
    await tester.pumpAndSettle();
    await tester.tap(enregistrer);
    await tester.pump();

    states.add(
      EnrollmentDraftGuardianPhoneConflict(
        phoneNumber,
        'Un tuteur avec ce numéro existe déjà.',
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'le refus ouvre une popin qui propose la fiche portant ce numéro, '
    'sans rien redemander à l\'utilisateur',
    (tester) async {
      await pumpStep(tester);
      await enregistrerPuisRefuser(tester);

      expect(find.text('Ce numéro est déjà utilisé'), findsOneWidget);
      expect(find.text('Sarah Junior Moke'), findsOneWidget);
      // La recherche est armée sur le numéro refusé, pas sur une identité.
      final captured = verify(
        () => searchUseCase(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: captureAny(named: 'phoneNumber'),
        ),
      ).captured;
      expect(captured.single, _conflictedPhone);
    },
  );

  testWidgets(
    '« Utiliser cette fiche » remplace la carte fautive et réécrit le '
    'brouillon avec isLinkedToExisting: true',
    (tester) async {
      await pumpStep(tester);
      await enregistrerPuisRefuser(tester);

      await tester.tap(find.text('Utiliser cette fiche'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // La carte en cours d'édition a cédé la place à la fiche existante.
      expect(
        find.byKey(ValueKey<String>('parent-item-${_editedParent.id}')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey<String>('parent-item-${_ownerParent.id}')),
        findsOneWidget,
      );

      final events = verify(
        () => offlineBloc.add(
          captureAny(that: isA<SaveDraftGuardiansRequested>()),
        ),
      ).captured.cast<SaveDraftGuardiansRequested>();
      // 1ʳᵉ écriture : celle qui a été refusée. 2ᵈᵉ : le rattachement.
      expect(events, hasLength(2));
      final draft = events.last.parents.single;
      expect(draft.id, _ownerParent.id);
      expect(draft.isLinkedToExisting, isTrue);
      // Le lien de parenté reste celui choisi pour CET élève (père), pas
      // celui que porterait la fiche parent.
      expect(draft.relationshipType, 'FATHER');
    },
  );

  testWidgets(
    '« Corriger le numéro » n\'écrit rien : la carte fautive reste en place',
    (tester) async {
      await pumpStep(tester);
      await enregistrerPuisRefuser(tester);

      await tester.tap(find.text('Corriger le numéro'));
      await tester.pumpAndSettle();

      expect(find.text('Ce numéro est déjà utilisé'), findsNothing);
      expect(
        find.byKey(ValueKey<String>('parent-item-${_editedParent.id}')),
        findsOneWidget,
      );
      // Seule l'écriture refusée a eu lieu — aucune réécriture derrière.
      final events = verify(
        () => offlineBloc.add(
          captureAny(that: isA<SaveDraftGuardiansRequested>()),
        ),
      ).captured;
      expect(events, hasLength(1));
    },
  );

  testWidgets(
    'doublon INTERNE au dossier (deux cartes, même numéro) : message local, '
    'aucune popin — aucune fiche existante n\'est en cause',
    (tester) async {
      await pumpStep(tester, parents: const [_editedParent, _secondParent]);
      await enregistrerPuisRefuser(tester);

      expect(find.text('Ce numéro est déjà utilisé'), findsNothing);
      expect(
        find.text(
          'Ce numéro est déjà saisi pour un autre tuteur de ce '
          'dossier.',
        ),
        findsOneWidget,
      );
    },
  );
}
