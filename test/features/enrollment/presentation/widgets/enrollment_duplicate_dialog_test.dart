import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

EnrollmentDuplicateCandidate _candidate({
  String studentId = 's1',
  String lastName = 'Mukendi',
  String firstName = 'Jean',
  String surname = 'Kabeya',
  String dateOfBirth = '2015-03-04',
  EnrollmentDuplicateSource source =
      EnrollmentDuplicateSource.currentYearDossier,
}) => EnrollmentDuplicateCandidate(
  studentId: studentId,
  source: source,
  level: EnrollmentDuplicateLevel.certain,
  identity: EnrollmentIdentity(
    lastName: lastName,
    firstName: firstName,
    surname: surname,
    dateOfBirth: dateOfBirth,
  ),
);

void main() {
  late AppLocalizations l10n;

  /// Hauteur mangée par le clavier, injectée dans le `MediaQuery` du harnais.
  double keyboardInset = 0;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  /// Monte un écran d'où la popin s'ouvre, et rapporte ce qu'elle a rendu à
  /// sa fermeture.
  Future<void> pumpAndOpen(
    WidgetTester tester,
    List<EnrollmentDuplicateCandidate> candidates,
    void Function(bool) onClosed,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final passed = await EnrollmentDuplicateDialog.show(
                  context,
                  candidates: candidates,
                );
                onClosed(passed);
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('nomme l\'élève retrouvé et d\'où il vient', (tester) async {
    await pumpAndOpen(tester, [_candidate()], (_) {});

    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
    expect(
      find.text('Mukendi Kabeya Jean · né(e) le 04/03/2015'),
      findsOneWidget,
    );
    expect(
      find.text(l10n.enrollmentDuplicateSourceCurrentYear),
      findsOneWidget,
    );
  });

  testWidgets('un candidat N-1 renvoie vers la Réinscription', (tester) async {
    await pumpAndOpen(tester, [
      _candidate(source: EnrollmentDuplicateSource.previousYearCohort),
    ], (_) {});

    expect(
      find.text(l10n.enrollmentDuplicateSourcePreviousYear),
      findsOneWidget,
    );
  });

  testWidgets('« Continuer quand même » laisse passer', (tester) async {
    bool? passed;
    await pumpAndOpen(tester, [_candidate()], (value) => passed = value);

    await tester.tap(find.text(l10n.enrollmentDuplicateContinueAction));
    await tester.pumpAndSettle();

    expect(passed, isTrue);
  });

  testWidgets('« Corriger la saisie » ne laisse pas passer', (tester) async {
    bool? passed;
    await pumpAndOpen(tester, [_candidate()], (value) => passed = value);

    await tester.tap(find.text(l10n.enrollmentDuplicateFixAction));
    await tester.pumpAndSettle();

    expect(passed, isFalse);
  });

  testWidgets('la croix vaut « corriger », jamais « continuer »', (
    tester,
  ) async {
    bool? passed;
    await pumpAndOpen(tester, [_candidate()], (value) => passed = value);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(passed, isFalse);
  });

  testWidgets('un abandon sans réponse vaut « corriger »', (tester) async {
    // Tap sur la barrière : la popin se ferme sans rien rendre. Ce chemin-là
    // ne passe par aucun bouton — c'est le `?? false` de `show` qui décide,
    // et rien d'autre ne l'exerce.
    bool? passed;
    await pumpAndOpen(tester, [_candidate()], (value) => passed = value);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
    expect(passed, isFalse);
  });

  testWidgets('trois élèves au plus sont nommés, le reste est compté', (
    tester,
  ) async {
    await pumpAndOpen(tester, [
      _candidate(studentId: 's1', firstName: 'Jean'),
      _candidate(studentId: 's2', firstName: 'Pierre'),
      _candidate(studentId: 's3', firstName: 'Paul'),
      _candidate(studentId: 's4', firstName: 'Marc'),
      _candidate(studentId: 's5', firstName: 'Luc'),
    ], (_) {});

    expect(find.textContaining('Jean'), findsOneWidget);
    expect(find.textContaining('Paul'), findsOneWidget);
    expect(find.textContaining('Marc'), findsNothing);
    expect(find.text(l10n.enrollmentDuplicateOthers(2)), findsOneWidget);
  });

  testWidgets('trois élèves exactement : rien à compter', (tester) async {
    await pumpAndOpen(tester, [
      _candidate(studentId: 's1', firstName: 'Jean'),
      _candidate(studentId: 's2', firstName: 'Pierre'),
      _candidate(studentId: 's3', firstName: 'Paul'),
    ], (_) {});

    expect(find.textContaining('Paul'), findsOneWidget);
    expect(
      find.textContaining(l10n.enrollmentDuplicateOthers(1)),
      findsNothing,
    );
    expect(find.textContaining('autre'), findsNothing);
  });

  testWidgets('elle tient en paysage clavier ouvert, sans déborder', (
    tester,
  ) async {
    // Règle des modales : une popin se vérifie en PAYSAGE, et c'est le clavier
    // qui décide. `Dialog` ajoute les `viewInsets` à son `insetPadding` : sur
    // un téléphone couché, clavier levé depuis l'étape restée dessous, il ne
    // reste qu'une centaine de dp — moins que l'en-tête et le pied réunis.
    // `EteeloDialogBody` doit alors tout envoyer au défilement au lieu de
    // laisser déborder, et c'est `minPinnedHeight` qui l'y oblige.
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    keyboardInset = 180;
    addTearDown(() => keyboardInset = 0);

    await pumpAndOpen(tester, [
      _candidate(studentId: 's1', firstName: 'Jean'),
      _candidate(studentId: 's2', firstName: 'Pierre'),
      _candidate(studentId: 's3', firstName: 'Paul'),
      _candidate(studentId: 's4', firstName: 'Marc'),
    ], (_) {});

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
    expect(find.text(l10n.enrollmentDuplicateFixAction), findsOneWidget);
  });

  testWidgets('liste vide : aucune popin, et le parcours continue', (
    tester,
  ) async {
    bool? passed;
    await pumpAndOpen(tester, const [], (value) => passed = value);

    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
    expect(passed, isTrue);
  });

  group('anglais', () {
    late AppLocalizations en;

    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    /// Une clé absente d'`app_en.arb` retombe silencieusement sur le français :
    /// l'écran reste lisible, et personne ne voit qu'il n'est pas traduit.
    test('les libellés de la popin sont bien traduits', () {
      expect(
        en.enrollmentDuplicateDialogTitle,
        isNot(l10n.enrollmentDuplicateDialogTitle),
      );
      expect(
        en.enrollmentDuplicateDialogMessage,
        isNot(l10n.enrollmentDuplicateDialogMessage),
      );
      expect(
        en.enrollmentDuplicateFixAction,
        isNot(l10n.enrollmentDuplicateFixAction),
      );
      expect(
        en.enrollmentDuplicateContinueAction,
        isNot(l10n.enrollmentDuplicateContinueAction),
      );
      expect(
        en.enrollmentDuplicateSourceCurrentYear,
        isNot(l10n.enrollmentDuplicateSourceCurrentYear),
      );
      expect(
        en.enrollmentDuplicateSourcePreviousYear,
        isNot(l10n.enrollmentDuplicateSourcePreviousYear),
      );
    });

    test('le pluriel s\'accorde dans les deux langues', () {
      expect(en.enrollmentDuplicateOthers(1), contains('pupil'));
      expect(en.enrollmentDuplicateOthers(2), contains('pupils'));
      expect(l10n.enrollmentDuplicateOthers(1), contains('autre élève'));
      expect(l10n.enrollmentDuplicateOthers(2), contains('autres élèves'));
    });

    test('la ligne d\'identité place le nom et la date', () {
      final line = en.enrollmentDuplicateIdentityLine(
        'Mukendi Jean',
        '04/03/2015',
      );
      expect(line, contains('Mukendi Jean'));
      expect(line, contains('04/03/2015'));
      expect(line, isNot(contains('né(e)')));
    });
  });
}
