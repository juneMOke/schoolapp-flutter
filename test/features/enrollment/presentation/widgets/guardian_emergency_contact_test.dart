import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

/// Étape Tuteurs — désignation du contact d'urgence.
///
/// Ce qui se joue ici tient en une phrase : **le serveur refuse en 422 un
/// agrégat qui désigne deux tuteurs, et ce refus est TERMINAL**. Il est
/// prononcé avant toute écriture, donc le rejeu échoue à l'identique : une
/// inscription partie avec deux désignations resterait bloquée dans la file
/// d'écritures. La garde ne peut donc pas vivre au retour du serveur — elle
/// doit rendre la saisie contradictoire impossible.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOfflineBloc offlineBloc;

  setUpAll(() {
    registerFallbackValue(
      const SaveDraftGuardiansRequested(studentId: 'x', parents: []),
    );
  });

  const mother = ParentSummary(
    id: 'parent-1',
    firstName: 'Marie',
    lastName: 'Martin',
    surname: 'L',
    identificationNumber: 'ID-1',
    phoneNumber: '+243111111111',
    email: 'marie@example.com',
    relationshipType: RelationshipType.mother,
  );

  const father = ParentSummary(
    id: 'parent-2',
    firstName: 'Jean',
    lastName: 'Dupont',
    surname: 'K',
    identificationNumber: 'ID-2',
    phoneNumber: '+243222222222',
    email: 'jean@example.com',
    relationshipType: RelationshipType.father,
  );

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    when(
      () => offlineBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());
  });

  /// La carte dépliée dépasse la surface par défaut (800x600) : sans cette
  /// fenêtre plus haute, les cases sont hors écran et `tap()` refuse de les
  /// atteindre — un échec de harnais qu'on lirait à tort comme un défaut.
  Future<void> pumpStep(
    WidgetTester tester, {
    List<ParentSummary> parents = const [mother, father],
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
              showInlineSaveButton: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Les cases « contact d'urgence » vivent dans la carte DÉPLIÉE ; une seule
  /// carte l'est à la fois. On lit donc la valeur portée par la carte visible.
  Finder emergencyCheckbox(WidgetTester tester, AppLocalizations l10n) {
    return find.ancestor(
      of: find.text(l10n.guardianEmergencyContactHint),
      matching: find.byType(Row),
    );
  }

  List<ConfirmParentDraft> lastPushedParents() {
    final captured = verify(() => offlineBloc.add(captureAny())).captured;
    return (captured.last as SaveDraftGuardiansRequested).parents;
  }

  testWidgets('tant que l\'écran n\'y touche pas, l\'agrégat n\'en dit RIEN', (
    tester,
  ) async {
    await pumpStep(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    // Une modification SANS rapport rend le formulaire enregistrable : c'est
    // exactement le cas qui compte — corriger un e-mail ne doit pas emporter
    // une désignation posée depuis un autre poste.
    await tester.enterText(
      find.byType(TextField).at(4),
      'marie.martin@example.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.guardianSaveAction));
    // `pump`, jamais `pumpAndSettle` : le bloc est un mock qui n'émet rien.
    await tester.pump();

    // `null`, pas `false` : le serveur lit l'absence comme « ne touche pas à
    // la désignation en place ». Un `false` projeté partout retirerait un
    // contact d'urgence désigné depuis un autre poste.
    expect(
      lastPushedParents().map((p) => p.emergencyContact),
      everyElement(isNull),
    );
  });

  testWidgets('désigner un tuteur : lui seul part à `true`', (tester) async {
    await pumpStep(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    // La première carte est dépliée par défaut.
    await tester.tap(
      find.descendant(
        of: emergencyCheckbox(tester, l10n),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.guardianSaveAction));
    // `pump`, jamais `pumpAndSettle` : le bloc est un mock qui n'émet rien,
    // l'écran reste donc en « enregistrement en cours » indéfiniment.
    await tester.pump();

    final parents = lastPushedParents();
    expect(
      parents.firstWhere((p) => p.id == 'parent-1').emergencyContact,
      isTrue,
    );
    // Une fois l'écran passé par là, il dit TOUT : le `false` explicite est ce
    // qui rend le retrait exprimable.
    expect(
      parents.firstWhere((p) => p.id == 'parent-2').emergencyContact,
      isFalse,
    );
  });

  /// L'exclusivité ne tient pas à une garde qu'on pourrait oublier d'écrire :
  /// l'état EST un id unique, désigner B remplace A dans le même geste. Un
  /// agrégat à deux désignations est donc inconstructible depuis cet écran.
  testWidgets('deux désignations sont impossibles à construire', (
    tester,
  ) async {
    await pumpStep(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    // Désigne la mère (carte 1, dépliée).
    await tester.tap(
      find.descendant(
        of: emergencyCheckbox(tester, l10n),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    // Ouvre la carte du père et le désigne à son tour. On vise la carte par sa
    // clé plutôt qu'un nom recomposé à la main : l'en-tête assemble
    // « prénom nom postnom », et le test se casserait au premier changement
    // de mise en forme sans que rien de réel ait bougé.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey<String>('parent-item-parent-2')),
        matching: find.byIcon(Icons.expand_more_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: emergencyCheckbox(tester, l10n),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.guardianSaveAction));
    // `pump`, jamais `pumpAndSettle` : le bloc est un mock qui n'émet rien,
    // l'écran reste donc en « enregistrement en cours » indéfiniment.
    await tester.pump();

    final parents = lastPushedParents();
    expect(
      parents.where((p) => p.emergencyContact == true),
      hasLength(1),
      reason: 'jamais deux désignations dans un même agrégat',
    );
    expect(
      parents.firstWhere((p) => p.id == 'parent-2').emergencyContact,
      isTrue,
    );
    expect(
      parents.firstWhere((p) => p.id == 'parent-1').emergencyContact,
      isFalse,
    );
  });

  /// Le retrait part d'un dossier qui PORTAIT une désignation — sinon il n'y a
  /// rien à retirer, et l'écran a raison de ne rien envoyer.
  testWidgets('décocher retire la désignation sans en poser d\'autre', (
    tester,
  ) async {
    await pumpStep(
      tester,
      parents: const [
        ParentSummary(
          id: 'parent-1',
          firstName: 'Marie',
          lastName: 'Martin',
          surname: 'L',
          identificationNumber: 'ID-1',
          phoneNumber: '+243111111111',
          email: 'marie@example.com',
          relationshipType: RelationshipType.mother,
          emergencyContact: true,
        ),
        father,
      ],
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await tester.tap(
      find.descendant(
        of: emergencyCheckbox(tester, l10n),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.guardianSaveAction));
    // `pump`, jamais `pumpAndSettle` : le bloc est un mock qui n'émet rien,
    // l'écran reste donc en « enregistrement en cours » indéfiniment.
    await tester.pump();

    // « Aucun contact désigné » est un état légitime, et il se DIT : `false`
    // partout, pas l'omission — sans quoi le retrait ne partirait jamais.
    expect(
      lastPushedParents().map((p) => p.emergencyContact),
      everyElement(isFalse),
    );
  });

  /// Cocher puis décocher revient à l'état de départ : rien n'a changé, donc
  /// rien ne doit partir. C'est la contre-épreuve du test ci-dessus — sans
  /// elle, « le retrait se dit » pourrait dégénérer en « l'écran écrit à
  /// chaque passage ».
  testWidgets('cocher puis décocher ne déclenche aucune écriture', (
    tester,
  ) async {
    await pumpStep(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    final checkbox = find.descendant(
      of: emergencyCheckbox(tester, l10n),
      matching: find.byType(Checkbox),
    );
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    verifyNever(() => offlineBloc.add(any()));
  });

  /// La désignation vient du dossier, jamais d'un défaut : contrairement au
  /// tuteur principal, aucune carte n'est cochée d'office. Inventer un contact
  /// d'urgence est pire que n'en avoir aucun le jour où il faut appeler.
  testWidgets('aucune carte n\'est désignée d\'office', (tester) async {
    await pumpStep(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    final checkbox = tester.widget<Checkbox>(
      find
          .descendant(
            of: emergencyCheckbox(tester, l10n),
            matching: find.byType(Checkbox),
          )
          .first,
    );
    expect(checkbox.value, isFalse);
  });

  testWidgets('la désignation du dossier est relue', (tester) async {
    await pumpStep(
      tester,
      parents: const [
        ParentSummary(
          id: 'parent-1',
          firstName: 'Marie',
          lastName: 'Martin',
          surname: 'L',
          identificationNumber: 'ID-1',
          phoneNumber: '+243111111111',
          email: 'marie@example.com',
          relationshipType: RelationshipType.mother,
          emergencyContact: true,
        ),
        father,
      ],
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    expect(
      tester
          .widget<Checkbox>(
            find
                .descendant(
                  of: emergencyCheckbox(tester, l10n),
                  matching: find.byType(Checkbox),
                )
                .first,
          )
          .value,
      isTrue,
    );
    // Et la pastille se lit carte repliée — personne n'ouvrira trois cartes
    // le jour d'un accident.
    expect(find.text(l10n.guardianEmergencyContactBadge), findsWidgets);
  });
}
