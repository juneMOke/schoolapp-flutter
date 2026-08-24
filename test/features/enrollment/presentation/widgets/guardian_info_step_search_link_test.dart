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
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_info_step_body.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockSearchParentsUseCase extends Mock implements SearchParentsUseCase {}

const _existingParent = ParentSummary(
  id: 'parent-1',
  firstName: 'Jean',
  lastName: 'Dupont',
  surname: 'K',
  identificationNumber: 'ID-123',
  phoneNumber: '+243000000000',
  email: 'jean.dupont@example.com',
  relationshipType: RelationshipType.guardian,
);

const _foundParent = LocalParent(
  id: 'server-parent-42',
  firstName: 'Sarah',
  lastName: 'Moke',
  surname: 'Junior',
  phoneNumber: '+243555555555',
  email: 'sarah.moke@example.com',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOfflineBloc offlineBloc;
  late _MockSearchParentsUseCase searchUseCase;

  setUpAll(() {
    registerFallbackValue(
      const SaveDraftGuardiansRequested(studentId: 'x', parents: []),
    );
  });

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    when(
      () => offlineBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());

    searchUseCase = _MockSearchParentsUseCase();
    getIt.registerLazySingleton<IdGenerator>(() => const IdGenerator(Uuid()));
    getIt.registerFactory<ParentSearchBloc>(
      () => ParentSearchBloc(search: searchUseCase),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// Trouve un `EteeloTextInput` par son libellé EXACT (pas `widgetWithText` :
  /// le label peut porter un suffixe " *" si le champ est `required`, ce qui
  /// casserait un match sur le texte affiché).
  Finder eteeloInputLabeled(Finder ancestor, String label) => find.descendant(
    of: ancestor,
    matching: find.byWidgetPredicate(
      (w) => w is EteeloTextInput && w.label == label,
    ),
  );

  /// `EteeloTextInput` habille un `TextField` réel : `enterText` doit cibler
  /// ce dernier, pas le wrapper stylé.
  Finder textFieldLabeled(Finder ancestor, String label) => find.descendant(
    of: eteeloInputLabeled(ancestor, label),
    matching: find.byType(TextField),
  );

  /// La popin ouvre sur la recherche par numéro : les champs d'identité
  /// n'apparaissent qu'après la bascule, et il faut nom ET prénom pour armer
  /// la recherche.
  Future<void> chercherParIdentite(
    WidgetTester tester,
    Finder dialogFinder, {
    required String nom,
    required String prenom,
  }) async {
    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Par identité')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(textFieldLabeled(dialogFinder, 'Nom'), nom);
    await tester.enterText(textFieldLabeled(dialogFinder, 'Prénom'), prenom);
    await tester.pump();
    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.text('Rechercher')),
    );
    await tester.pumpAndSettle();
  }

  /// Les critères défilent avec les résultats : sur une petite surface, le
  /// premier résultat naît sous la fenêtre visible. On le rejoint comme
  /// l'utilisateur, en défilant.
  Future<void> choisirResultat(WidgetTester tester, Finder resultat) async {
    await tester.ensureVisible(resultat);
    await tester.pumpAndSettle();
    await tester.tap(resultat);
  }

  /// Le rattachement part du bandeau posé DANS la carte dépliée — plus de la
  /// loupe d'en-tête.
  Future<void> ouvrirRechercheDepuisLaCarte(WidgetTester tester) async {
    final bouton = find.text('Rechercher une fiche');
    await tester.ensureVisible(bouton);
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
  }

  Future<void> pumpGuardianStep(
    WidgetTester tester, {
    List<ParentSummary> parents = const [_existingParent],
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
              width: 360,
              child: GuardianInfoStep(
                parentDetails: parents,
                studentId: 'student-1',
                enrollmentId: 'enrollment-1',
                showInlineSaveButton: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sélection via recherche ajoute le tuteur avec identité verrouillée '
    'et relation éditable ; le draft envoyé porte isLinkedToExisting: true',
    (tester) async {
      when(
        () => searchUseCase(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => const Right([_foundParent]));

      await pumpGuardianStep(tester);

      await ouvrirRechercheDepuisLaCarte(tester);

      expect(find.text('Rechercher un parent existant'), findsOneWidget);
      // Le tuteur existant (déjà expandé sous le dialog) porte lui aussi un
      // champ "Nom" / "Rechercher" quelque part dans l'arbre : tout finder
      // de contenu du formulaire de recherche est donc scopé au Dialog.
      final dialogFinder = find.byType(Dialog);

      await chercherParIdentite(
        tester,
        dialogFinder,
        nom: 'Moke',
        prenom: 'Sarah',
      );

      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Sarah Junior Moke'),
        ),
        findsOneWidget,
      );
      await choisirResultat(
        tester,
        find.descendant(
          of: dialogFinder,
          matching: find.text('Sarah Junior Moke'),
        ),
      );
      // Pas de pumpAndSettle : la sauvegarde immédiate déclenchée à l'ajout
      // laisse un indicateur de chargement indéterminé actif (le mock bloc
      // n'émet pas d'état « sauvé »), l'arbre ne se stabilise donc jamais
      // complètement (même patron que guardian_info_step_delete_flow_test).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Dialog fermé, nouveau tuteur ajouté (id réel du parent trouvé).
      expect(find.text('Rechercher un parent existant'), findsNothing);
      final newItemKey = ValueKey<String>('parent-item-${_foundParent.id}');
      expect(find.byKey(newItemKey), findsOneWidget);

      // Champs identité verrouillés (readOnly) — le lien de parenté reste
      // piloté par isEditable uniquement (non vérifié ici, testé ailleurs).
      final firstNameField = tester.widget<EteeloTextInput>(
        eteeloInputLabeled(find.byKey(newItemKey), 'Prénom'),
      );
      expect(firstNameField.readOnly, isTrue);

      // Sauvegarde IMMÉDIATE (rattachement structurel, comme la suppression)
      // — pas besoin de cliquer "Enregistrer", qui resterait grisé (le
      // nouveau tuteur est valide mais pas "dirty" au sens d'une édition).
      final captured =
          verify(
                () => offlineBloc.add(
                  captureAny(that: isA<SaveDraftGuardiansRequested>()),
                ),
              ).captured.single
              as SaveDraftGuardiansRequested;
      final draft = captured.parents.firstWhere((p) => p.id == _foundParent.id);
      expect(draft.isLinkedToExisting, isTrue);
      expect(draft.phoneNumber, _foundParent.phoneNumber);
    },
  );

  testWidgets(
    'parent déjà ajouté à cette inscription → erreur, pas de doublon',
    (tester) async {
      when(
        () => searchUseCase(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer(
        (_) async => const Right([
          LocalParent(
            id: 'parent-1', // même id que le tuteur déjà présent
            firstName: 'Jean',
            lastName: 'Dupont',
            phoneNumber: '+243000000000',
          ),
        ]),
      );

      await pumpGuardianStep(tester);

      await ouvrirRechercheDepuisLaCarte(tester);

      final dialogFinder = find.byType(Dialog);

      await chercherParIdentite(
        tester,
        dialogFinder,
        nom: 'Dupont',
        prenom: 'Sarah',
      );

      await choisirResultat(
        tester,
        find.descendant(of: dialogFinder, matching: find.text('Jean Dupont')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ce parent est déjà ajouté à cette inscription.'),
        findsOneWidget,
      );
      // Toujours un seul tuteur dans la liste (pas de doublon).
      expect(
        find.byKey(const ValueKey<String>('parent-item-parent-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tuteur vide auto-créé (aucun tuteur au départ) n\'est PAS envoyé lors '
    'd\'un rattachement via recherche — évite de polluer `parents` avec une '
    'fiche vide ou de faire échouer le rattachement sur un faux conflit',
    (tester) async {
      when(
        () => searchUseCase(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => const Right([_foundParent]));

      // Liste initiale VIDE : GuardianInfoStepState auto-crée une ligne
      // blanche (phoneNumber: '') pour l'édition — comportement existant,
      // reproduit ici sans y toucher.
      await pumpGuardianStep(tester, parents: const []);

      await ouvrirRechercheDepuisLaCarte(tester);

      final dialogFinder = find.byType(Dialog);
      await chercherParIdentite(
        tester,
        dialogFinder,
        nom: 'Moke',
        prenom: 'Sarah',
      );
      await choisirResultat(
        tester,
        find.descendant(
          of: dialogFinder,
          matching: find.text('Sarah Junior Moke'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final captured =
          verify(
                () => offlineBloc.add(
                  captureAny(that: isA<SaveDraftGuardiansRequested>()),
                ),
              ).captured.single
              as SaveDraftGuardiansRequested;

      // Seul le tuteur trouvé est envoyé — la ligne vide auto-créée est
      // exclue (n'était jamais un vrai tuteur, juste un brouillon d'édition).
      expect(captured.parents, hasLength(1));
      expect(captured.parents.single.id, _foundParent.id);
    },
  );

  testWidgets(
    'conflit de téléphone après rattachement via recherche : le verrou de '
    'chargement (AbsorbPointer) se lève bien — régression du bug "UI figée" '
    '(setState manquant dans _onGuardianPhoneConflict)',
    (tester) async {
      when(
        () => searchUseCase(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => const Right([_foundParent]));

      final stateController =
          StreamController<EnrollmentOfflineState>.broadcast();
      addTearDown(stateController.close);
      when(() => offlineBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpGuardianStep(tester);

      await ouvrirRechercheDepuisLaCarte(tester);

      final dialogFinder = find.byType(Dialog);
      await chercherParIdentite(
        tester,
        dialogFinder,
        nom: 'Moke',
        prenom: 'Sarah',
      );
      await choisirResultat(
        tester,
        find.descendant(
          of: dialogFinder,
          matching: find.text('Sarah Junior Moke'),
        ),
      );
      await tester.pump();

      // Le verrou de GuardianInfoStepBody (racine de son build(), distinct de
      // tout AbsorbPointer interne à d'autres widgets comme les boutons).
      final bodyAbsorbPointer = find.descendant(
        of: find.byType(GuardianInfoStepBody),
        matching: find.byType(AbsorbPointer),
      );

      // Sauvegarde déclenchée immédiatement → verrou actif.
      expect(bodyAbsorbPointer, findsOneWidget);
      expect(tester.widget<AbsorbPointer>(bodyAbsorbPointer).absorbing, isTrue);

      // Le bloc répond par un conflit de téléphone (numéro déjà utilisé par
      // un autre tuteur — le cas que cette fonctionnalité existe pour
      // détecter).
      stateController.add(
        const EnrollmentDraftGuardianPhoneConflict(
          '+243555555555',
          'Un tuteur avec ce numéro existe déjà.',
        ),
      );
      await tester.pump();

      // Le verrou doit être levé : avant le correctif, il restait figé à
      // `true` indéfiniment (aucun setState() n'accompagnait la mutation de
      // _isBatchSaving dans _onGuardianPhoneConflict).
      expect(
        tester.widget<AbsorbPointer>(bodyAbsorbPointer).absorbing,
        isFalse,
        reason:
            'régression : sans setState() dans _onGuardianPhoneConflict, '
            'GuardianInfoStepState.build() n\'est jamais ré-invoqué après '
            'l\'erreur — l\'étape reste figée avec un spinner.',
      );
      expect(
        find.text('Un tuteur avec ce numéro existe déjà.'),
        findsOneWidget,
      );
    },
  );
}
