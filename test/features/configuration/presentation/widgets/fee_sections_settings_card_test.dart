import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/fee_code_section_cache_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/fee_sections_settings_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockCache extends Mock implements FeeCodeSectionCacheRepository {}

/// Le catalogue d'une école qui n'a encore rien décidé : rangs `0, 1, 2`.
const _served = <FeeCodeOption>[
  FeeCodeOption(code: 'TUITION', label: 'Minerval', sortOrder: 0),
  FeeCodeOption(
    code: 'REGISTRATION',
    label: 'Frais d\'inscription',
    sortOrder: 1,
  ),
  FeeCodeOption(code: 'CANTEEN', label: 'Cantine', sortOrder: 2),
];

void main() {
  late _MockRepository repository;
  late _MockCache cache;

  setUpAll(() {
    registerFallbackValue(const <FeeCodeSectionEdit>[]);
    registerFallbackValue(const <FeeCodeOption>[]);
  });

  setUp(() {
    repository = _MockRepository();
    cache = _MockCache();
    when(
      () => cache.cacheFeeCodeSections(any()),
    ).thenAnswer((_) async => const Right(unit));
    getIt.registerFactory<FeeCodeSectionCacheRepository>(() => cache);
    when(
      () => repository.loadFeeCodes(
        forceRefresh: any(named: 'forceRefresh'),
        includeHidden: any(named: 'includeHidden'),
      ),
    ).thenAnswer((_) async => const Right(_served));
    when(
      () => repository.saveFeeCodeSections(any()),
    ).thenAnswer((_) async => const Right(_served));
    getIt.registerFactory<ProvisioningRepository>(() => repository);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(child: FeeSectionsSettingsCard()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Le lot réellement envoyé au serveur.
  List<FeeCodeSectionEdit> captureSaved() =>
      verify(() => repository.saveFeeCodeSections(captureAny())).captured.single
          as List<FeeCodeSectionEdit>;

  testWidgets('demande le catalogue COMPLET, masquées comprises', (
    tester,
  ) async {
    // Sans les masquées, les rétablir serait impossible : elles auraient disparu
    // de l'écran qui sert précisément à les gérer.
    await pump(tester);

    verify(() => repository.loadFeeCodes(includeHidden: true)).called(1);
  });

  testWidgets('montre le titre de chaque section et son code', (tester) async {
    await pump(tester);

    expect(find.text('Minerval'), findsOneWidget);
    // Le code reste affiché : c'est lui qui part sur le fil, et le seul repère
    // stable quand la direction renomme.
    expect(find.text('TUITION'), findsOneWidget);
  });

  testWidgets('n\'envoie RIEN tant que rien n\'a changé', (tester) async {
    // Le bouton désactivé n'est pas cosmétique : tout envoyer ferait naître
    // vingt-trois surcharges là où la direction n'a touché à rien.
    await pump(tester);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('un renommage n\'envoie QUE le titre de la section renommée', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'Frais scolaires annuels',
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final sent = captureSaved();
    expect(sent, hasLength(1));
    expect(sent.single.code, 'TUITION');
    expect(sent.single.label, 'Frais scolaires annuels');
    // Ni rang ni visibilité : renommer n'est pas classer, et un rang écrit ici
    // figerait un ordre que personne n'a choisi.
    expect(sent.single.sortOrder, isNull);
    expect(sent.single.active, isNull);
  });

  testWidgets('masquer une section n\'envoie que sa visibilité', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final sent = captureSaved();
    expect(sent, hasLength(1));
    expect(sent.single.code, 'TUITION');
    expect(sent.single.active, isFalse);
    expect(sent.single.label, isNull);
  });

  testWidgets('un renommage réussi met À JOUR le cache local des titres', (
    tester,
  ) async {
    // Sans cette écriture, la Facturation afficherait l'ancien titre jusqu'au
    // prochain cycle de pull — un délai que rien à l'écran n'explique, alors
    // que la direction vient de renommer sous ses yeux.
    await pump(tester);

    await tester.enterText(find.byType(TextField).first, 'Frais annuels');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(() => cache.cacheFeeCodeSections(_served)).called(1);
  });

  testWidgets('un refus du serveur n\'écrit RIEN dans le cache local', (
    tester,
  ) async {
    when(
      () => repository.saveFeeCodeSections(any()),
    ).thenAnswer((_) async => const Left(ValidationFailure('refus')));

    await pump(tester);
    await tester.enterText(find.byType(TextField).first, 'Frais annuels');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verifyNever(() => cache.cacheFeeCodeSections(any()));
  });

  testWidgets('le refus du serveur est montré tel qu\'il est venu', (
    tester,
  ) async {
    // Lui seul nomme les deux sections qui se disputent un titre ; une phrase
    // générique laisserait la direction chercher laquelle corriger.
    when(() => repository.saveFeeCodeSections(any())).thenAnswer(
      (_) async => const Left(
        ValidationFailure(
          '« Minerval » désignerait à la fois TUITION et REGISTRATION.',
        ),
      ),
    );

    await pump(tester);
    await tester.enterText(find.byType(TextField).at(1), 'Minerval');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.textContaining('désignerait à la fois'), findsOneWidget);
  });
}
