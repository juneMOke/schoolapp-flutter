import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_form_fields.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _options = [
  SearchLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l1',
    label: 'Primaire - 1ère',
  ),
  SearchLevelOption(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'l2',
    label: 'Primaire - 2ème',
  ),
];

const _tariffs = [
  LocalFeeTariff(
    id: 't1',
    feeCode: 'TUITION',
    label: 'Frais scolaire',
    amountInCents: 150000,
    currency: 'USD',
  ),
];

/// Deux lignes de grille sous la MÊME nature — ce qu'une école qui étale son
/// minerval envoie. Le front ne sait pas encore poser un code au paramétrage :
/// cette grille-là vient d'ailleurs, et c'est justement le cas que le sélecteur
/// ne doit pas travestir.
const _tranchedTariffs = [
  LocalFeeTariff(
    id: 't1',
    feeCode: 'TUITION',
    code: 'T1',
    label: 'Minerval — 1/2',
    amountInCents: 75000,
    currency: 'USD',
  ),
  LocalFeeTariff(
    id: 't2',
    feeCode: 'TUITION',
    code: 'T2',
    label: 'Minerval — 2/2',
    amountInCents: 75000,
    currency: 'USD',
  ),
];

const _classrooms = [
  OfflineClassroom(
    id: 'cls-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'l1',
    name: '1ère A',
    totalCount: 0,
    femaleCount: 0,
    maleCount: 0,
  ),
];

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Ce que la session détient. `null` = ensemble jamais communiqué ; l'absence
/// d'instance = aucun `AuthBloc` dans l'arbre. Les deux valent « inconnu ».
class _Session {
  const _Session(this.permissions);
  const _Session.unknown() : permissions = null;

  final List<String>? permissions;
}

const _sansClasse = _Session(['finance.charge.read', 'enrollment.read']);
const _avecClasse = _Session([
  'finance.charge.read',
  'enrollment.read',
  'classroom.read',
]);

/// Profil sans `finance.grid.read`. Le référentiel descend bien (il tient à
/// `school.read`), mais le serveur en ampute la portion tarifaire : c'est le
/// SEUL des trois cas de ce lot qu'un gabarit de rôle serveur produise
/// réellement. `classroom.read` y figure pour que le sélecteur de classe reste
/// muet et n'introduise pas un second message dans l'écran.
const _sansGrille = _Session([
  'finance.charge.read',
  'enrollment.read',
  'classroom.read',
]);
const _avecGrille = _Session([
  'finance.charge.read',
  'enrollment.read',
  'classroom.read',
  'finance.grid.read',
]);

/// [session] omise = pas d'`AuthBloc` du tout, comme dans tous les tests
/// historiques de ce fichier.
Future<void> _pumpForm(
  WidgetTester tester, {
  List<LocalFeeTariff> tariffs = const <LocalFeeTariff>[],
  List<OfflineClassroom> classrooms = const <OfflineClassroom>[],
  bool feeGridMissing = false,
  bool tariffsFailed = false,
  void Function(String, String)? onLevelSelected,
  ValueChanged<FeeControlSearchRequest>? onSearch,
  _Session? session,
}) async {
  Widget child = AppPageBackground(
    child: FeeControlSearchForm(
      options: _options,
      tariffs: tariffs,
      classrooms: classrooms,
      isTariffsLoading: false,
      isClassroomsLoading: false,
      feeGridMissing: feeGridMissing,
      tariffsFailed: tariffsFailed,
      isLoading: false,
      onLevelSelected: onLevelSelected ?? (_, _) {},
      onSearch: onSearch ?? (_) {},
      onClear: () {},
    ),
  );

  if (session != null) {
    final authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: session.permissions,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );
    child = BlocProvider<AuthBloc>.value(value: authBloc, child: child);
  }

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

/// Le bouton primaire « Rechercher » du formulaire.
Finder get _searchButton => find.ancestor(
  of: find.text('Rechercher'),
  matching: find.byType(ElevatedButton),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rendu étroit sans erreur de layout', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
    expect(find.byType(EteeloTextInput), findsNWidgets(3));
    // Cycle, Niveau, Classe, Frais + le statut (typé à part).
    expect(find.byType(EteeloSelectInput<String>), findsNWidgets(4));
    expect(
      find.byType(EteeloSelectInput<FeeControlPaymentFilter>),
      findsOneWidget,
    );
  });

  testWidgets('rendu large sans erreur de layout', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester, tariffs: _tariffs);

    expect(tester.takeException(), isNull);
    expect(find.byType(BiToneSectionCard), findsOneWidget);
  });

  testWidgets('Rechercher est éteint tant qu\'aucun frais n\'est choisi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester, tariffs: _tariffs);

    final button = tester.widget<ElevatedButton>(_searchButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('choisir un cycle puis un niveau demande la grille du niveau', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final selected = <String>[];
    await _pumpForm(
      tester,
      onLevelSelected: (groupId, levelId) => selected.add('$groupId::$levelId'),
    );

    await _selectCycle(tester, 'g1');
    expect(selected, isEmpty, reason: 'un cycle seul ne charge pas la grille');

    await _selectLevel(tester, 'g1::l1');
    expect(selected, ['g1::l1']);
  });

  testWidgets('un frais choisi arme Rechercher et remonte le code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    FeeControlSearchRequest? emitted;
    await _pumpForm(
      tester,
      tariffs: _tariffs,
      onSearch: (request) => emitted = request,
    );

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    await _selectFee(tester, 'TUITION');

    expect(tester.widget<ElevatedButton>(_searchButton).onPressed, isNotNull);

    await tester.tap(_searchButton);
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.schoolLevelId, 'l1');
    expect(emitted!.schoolLevelGroupId, 'g1');
    expect(emitted!.feeCode, 'TUITION');
    expect(emitted!.statusFilter, FeeControlPaymentFilter.all);
  });

  testWidgets('la classe choisie descend dans les critères', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    FeeControlSearchRequest? emitted;
    await _pumpForm(
      tester,
      tariffs: _tariffs,
      classrooms: _classrooms,
      onSearch: (request) => emitted = request,
    );

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    await _selectFee(tester, 'TUITION');

    // Défaut : toutes les classes du niveau.
    await tester.tap(_searchButton);
    await tester.pumpAndSettle();
    expect(emitted!.classroomId, isNull);

    await _selectClassroom(tester, 'cls-1');
    await tester.tap(_searchButton);
    await tester.pumpAndSettle();
    expect(emitted!.classroomId, 'cls-1');

    // La sentinelle « toutes les classes » revient bien à null.
    await _selectClassroom(tester, FeeControlClassroomField.allClassroomsValue);
    await tester.tap(_searchButton);
    await tester.pumpAndSettle();
    expect(emitted!.classroomId, isNull);
  });

  testWidgets('changer de niveau désarme le frais déjà choisi', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester, tariffs: _tariffs);

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');
    await _selectFee(tester, 'TUITION');
    expect(tester.widget<ElevatedButton>(_searchButton).onPressed, isNotNull);

    await _selectLevel(tester, 'g1::l2');

    expect(
      tester.widget<ElevatedButton>(_searchButton).onPressed,
      isNull,
      reason: 'la grille du nouveau niveau n\'est pas encore connue',
    );
  });

  testWidgets(
    'grille absente de l\'appareil : message distinct de « aucun frais »',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, feeGridMissing: true);

      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(
        find.textContaining('grille tarifaire n\'est pas encore descendue'),
        findsOneWidget,
      );
      expect(find.textContaining('Aucun frais n\'est défini'), findsNothing);
    },
  );

  testWidgets('niveau sans frais : message d\'information', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpForm(tester);

    await _selectCycle(tester, 'g1');
    await _selectLevel(tester, 'g1::l1');

    expect(find.textContaining('Aucun frais n\'est défini'), findsOneWidget);
  });

  // M-4 — la TROISIÈME cause d'un sélecteur de frais vide. `tariffsStatus:
  // failure` était stocké et lu par personne : une base SQLCipher verrouillée
  // annonçait « aucun frais défini pour ce niveau », c'est-à-dire une
  // affirmation sur l'école alors que seule la lecture de l'appareil avait
  // échoué. Le frais étant obligatoire ici, l'écran restait fermé sans
  // explication ni issue.
  group('lecture de la grille en échec (M-4)', () {
    const echec = 'n\'a pas pu être lue';
    const vide = 'Aucun frais n\'est défini';

    testWidgets('dit l\'échec, et surtout PAS « aucun frais »', (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, tariffsFailed: true);

      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(echec), findsOneWidget);
      expect(find.textContaining(vide), findsNothing);
    });

    testWidgets('offre une reprise qui rejoue la lecture du MÊME niveau', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final demandes = <(String, String)>[];
      await _pumpForm(
        tester,
        tariffsFailed: true,
        onLevelSelected: (groupId, levelId) => demandes.add((groupId, levelId)),
      );

      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');
      expect(demandes, [('g1', 'l1')]);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(
        demandes,
        [('g1', 'l1'), ('g1', 'l1')],
        reason:
            'sans ce geste l\'opérateur reste devant un formulaire qu\'il '
            'ne peut pas armer : le frais est obligatoire',
      );
    });

    testWidgets('CONTRE-ÉPREUVE : pas de reprise quand rien n\'a échoué', (
      tester,
    ) async {
      // Ni « ce niveau n'a pas de frais » ni « la grille n'est pas descendue »
      // ne se réparent en réessayant : offrir le bouton y promettrait une issue
      // qui n'existe pas.
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, feeGridMissing: true);

      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.text('Réessayer'), findsNothing);
    });
  });

  // ADR-015 F1c — une liste de classes vide a deux causes, et une seule des
  // deux se résoudra. Sans `classroom.read`, le roster n'est jamais tiré :
  // « aucune classe n'est composée » affirme alors quelque chose sur l'école
  // dont on ne sait rien, et fait chercher côté organisation des classes un
  // manque qui est côté droits.
  group('classe : liste vide, deux causes', () {
    const withheld =
        'Les classes relèvent d\'un module auquel ce profil n\'a '
        'pas accès';
    const empty = 'Aucune classe n\'est composée pour ce niveau';

    testWidgets('sans classroom.read → dit le droit', (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, session: _sansClasse);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(withheld), findsOneWidget);
      expect(find.textContaining(empty), findsNothing);
    });

    testWidgets('avec classroom.read → dit l\'école', (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, session: _avecClasse);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(empty), findsOneWidget);
      expect(find.textContaining(withheld), findsNothing);
    });

    // LE PIÈGE : un parc de sessions ouvertes avant la migration des
    // permissions est entièrement en `null`. Ces comptes ont TOUS les droits et
    // leurs classes descendent normalement — leur dire « ce profil n'a pas
    // accès » remplacerait un message discutable par un message faux.
    testWidgets(
      'droits inconnus (null) → l\'ancien message, pas l\'accusation',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpForm(tester, session: const _Session.unknown());
        await _selectCycle(tester, 'g1');
        await _selectLevel(tester, 'g1::l1');

        expect(find.textContaining(empty), findsOneWidget);
        expect(find.textContaining(withheld), findsNothing);
      },
    );

    testWidgets('sans AuthBloc dans l\'arbre → l\'ancien message aussi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(empty), findsOneWidget);
      expect(find.textContaining(withheld), findsNothing);
    });

    // Le message ne porte que sur la liste vide : des classes connues sans le
    // droit (roster déjà descendu, droit retiré depuis) n'ont rien à expliquer.
    testWidgets('des classes connues → aucun message, même sans le droit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, classrooms: _classrooms, session: _sansClasse);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(withheld), findsNothing);
      expect(find.textContaining(empty), findsNothing);
    });
  });

  // ADR-015 F1c — la grille absente a elle aussi deux causes, et celle-ci est
  // la seule des trois du lot qu'un gabarit de rôle serveur produise vraiment :
  // le référentiel descend sur `school.read`, mais le serveur en ampute la
  // portion tarifaire quand la session n'a pas `finance.grid.read`.
  // « Synchronisez » promet alors une mise à jour déjà faite, et qui reviendra
  // tout aussi caviardée.
  group('frais : grille absente, deux causes', () {
    const withheld = 'elle ne descendra pas sur cet appareil';
    const missing = 'n\'est pas encore descendue sur cet appareil';

    testWidgets('sans finance.grid.read → dit le droit, sans promesse vaine', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, feeGridMissing: true, session: _sansGrille);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(withheld), findsOneWidget);
      expect(find.textContaining(missing), findsNothing);
      // Le geste promis est le cœur du défaut : une synchronisation de plus ne
      // ramènera jamais une grille que le serveur ampute à chaque envoi.
      expect(find.textContaining('Synchronisez'), findsNothing);
    });

    testWidgets('avec finance.grid.read → le vrai « pas encore descendue »', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, feeGridMissing: true, session: _avecGrille);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(missing), findsOneWidget);
      expect(find.textContaining('Synchronisez'), findsOneWidget);
      expect(find.textContaining(withheld), findsNothing);
    });

    // LE PIÈGE : le parc de sessions ouvertes avant la migration des
    // permissions est ENTIÈREMENT en `null`. Ces comptes ont tous les droits et
    // leur grille descend normalement — les accuser serait pire que le défaut
    // d'origine, qui se contentait de promettre une synchronisation inutile.
    testWidgets(
      'droits inconnus (null) → l\'ancien message, pas l\'accusation',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpForm(
          tester,
          feeGridMissing: true,
          session: const _Session.unknown(),
        );
        await _selectCycle(tester, 'g1');
        await _selectLevel(tester, 'g1::l1');

        expect(find.textContaining(missing), findsOneWidget);
        expect(find.textContaining(withheld), findsNothing);
      },
    );

    testWidgets('sans AuthBloc dans l\'arbre → l\'ancien message aussi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, feeGridMissing: true);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(missing), findsOneWidget);
      expect(find.textContaining(withheld), findsNothing);
    });

    // Le message ne porte que sur la grille absente : une grille présente n'a
    // rien à expliquer, même sans le droit.
    testWidgets('une grille présente → aucun des deux messages', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, tariffs: _tariffs, session: _sansGrille);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      expect(find.textContaining(withheld), findsNothing);
      expect(find.textContaining(missing), findsNothing);
    });
  });

  /// Le sélecteur affichait la NATURE localisée (« Frais de scolarité ») là où
  /// l'école a écrit « Frais scolaire ». L'opérateur cherchait dans la liste un
  /// intitulé qui n'y figurait pas, et le reste de Finance — détail
  /// Facturation, encaissement — nommait déjà le même frais autrement.
  group('nommage du frais', () {
    testWidgets('une ligne unique est nommée par la grille, code compris', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, tariffs: _tariffs);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      final labels = _stringSelects(
        tester,
      )[3].items.map((item) => item.label).toList();
      expect(labels.single, startsWith('Frais scolaire'));
      expect(labels.single, contains('500,00'));
    });

    /// Le contrôle agrège les deux tranches (`SUM` sur `fee_code`). Emprunter
    /// le libellé de la première annoncerait un contrôle sur « 1/2 » seul, et
    /// afficherait la moitié de l'attendu.
    testWidgets('plusieurs tranches → la nature, le compte et le total', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpForm(tester, tariffs: _tranchedTariffs);
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');

      final items = _stringSelects(tester)[3].items;
      // Une seule entrée : deux entrées de même valeur casseraient le
      // sélecteur, et mèneraient de toute façon au même tableau.
      expect(items.single.value, 'TUITION');
      expect(items.single.label, isNot(contains('1/2')));
      expect(items.single.label, contains('2 tranches'));
      expect(items.single.label, contains('500,00'));
    });

    testWidgets(
      'la désignation descend dans la requête, pas seulement à l\'écran',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        FeeControlSearchRequest? emitted;
        await _pumpForm(
          tester,
          tariffs: _tariffs,
          onSearch: (request) => emitted = request,
        );
        await _selectCycle(tester, 'g1');
        await _selectLevel(tester, 'g1::l1');
        await _selectFee(tester, 'TUITION');
        await tester.tap(_searchButton);
        await tester.pumpAndSettle();

        expect(emitted!.feeCode, 'TUITION');
        expect(emitted!.feeLabel, 'Frais scolaire');
      },
    );

    /// Ce que la puce de critère affichera. Un libellé emprunté à la première
    /// tranche y rappellerait « Minerval — 1/2 » pour un contrôle qui porte sur
    /// les deux.
    testWidgets('à plusieurs tranches, la requête ne porte aucun libellé', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      FeeControlSearchRequest? emitted;
      await _pumpForm(
        tester,
        tariffs: _tranchedTariffs,
        onSearch: (request) => emitted = request,
      );
      await _selectCycle(tester, 'g1');
      await _selectLevel(tester, 'g1::l1');
      await _selectFee(tester, 'TUITION');
      await tester.tap(_searchButton);
      await tester.pumpAndSettle();

      expect(emitted!.feeCode, 'TUITION');
      expect(emitted!.feeLabel, isEmpty);
      expect(emitted!.feeTariffCode, isNull);
    });
  });
}

// ─── Pilotage des sélecteurs ──────────────────────────────────────────────────
//
// Les listes déroulantes du DS ouvrent un panneau en overlay : le test invoque
// directement leur `onChanged` plutôt que de simuler l'ouverture, ce qui teste
// la logique du formulaire sans dépendre du rendu du panneau.

List<EteeloSelectInput<String>> _stringSelects(WidgetTester tester) => tester
    .widgetList<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>),
    )
    .toList(growable: false);

Future<void> _selectCycle(WidgetTester tester, String groupId) async {
  _stringSelects(tester)[0].onChanged(groupId);
  await tester.pumpAndSettle();
}

Future<void> _selectLevel(WidgetTester tester, String levelKey) async {
  _stringSelects(tester)[1].onChanged(levelKey);
  await tester.pumpAndSettle();
}

Future<void> _selectClassroom(WidgetTester tester, String value) async {
  _stringSelects(tester)[2].onChanged(value);
  await tester.pumpAndSettle();
}

Future<void> _selectFee(WidgetTester tester, String feeCode) async {
  _stringSelects(tester)[3].onChanged(feeCode);
  await tester.pumpAndSettle();
}
