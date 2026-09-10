import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/presentation/widget/school_brand_mark.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../school_logo_fixture.dart';

void main() {
  const size = 36.0;

  Widget host(SchoolLogo? logo) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(
        child: SchoolBrandMark(logo: logo, size: size),
      ),
    );
  }

  /// Laisse le décodeur de la plateforme rendre son verdict sur des octets.
  ///
  /// Un décodage RÉUSSI ne rend pas la main sous l'horloge simulée de
  /// `testWidgets` : sans ce détour, l'arbre montre un widget `Image` sans
  /// pixels, et un sceau affiché ne s'y distingue pas d'un sceau en attente.
  Future<void> decode(WidgetTester tester, Uint8List bytes) async {
    await tester.runAsync(
      () => precacheImage(
        MemoryImage(bytes),
        tester.element(find.byType(SchoolBrandMark)),
        onError: (_, _) {},
      ),
    );
    await tester.pump();
  }

  // Un PNG décodé reste dans le cache d'images du processus : le test suivant
  // le trouverait déjà prêt, et ne vérifierait plus rien du décodage.
  setUp(() {
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  testWidgets('sans sceau, le symbole ETEELO fond foncé, à la même taille', (
    tester,
  ) async {
    await tester.pumpWidget(host(null));

    final mark = tester.widget<EteeloLogo>(find.byType(EteeloLogo));
    // Les surfaces de marque sont Bleu Profond : la variante fond clair y
    // poserait un symbole sombre sur du sombre.
    expect(mark.variant, EteeloLogoVariant.symbolOnDark);
    expect(mark.size, size);
    expect(find.byType(Image), findsNothing);
  });

  group('avec sceau', () {
    testWidgets('des octets décodables s\'affichent réellement', (
      tester,
    ) async {
      // Le seul test qui constate les PIXELS du sceau : les tests d'écran
      // (bannière, barre latérale) ne voient que le widget `Image`.
      final logo = fakeSchoolLogo();
      await tester.pumpWidget(host(logo));
      await decode(tester, logo.bytes);

      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(find.byType(EteeloLogo), findsNothing);
    });

    testWidgets('des octets indécodables retombent sur le symbole ETEELO', (
      tester,
    ) async {
      // Une base abîmée, un format que la plateforme refuse : jamais un trou
      // ni une icône de rupture dans la vignette.
      final logo = SchoolLogo(
        sha256: 'sceau-abime',
        bytes: Uint8List.fromList(const [1, 2, 3, 4]),
      );
      await tester.pumpWidget(host(logo));
      await decode(tester, logo.bytes);

      final mark = tester.widget<EteeloLogo>(find.byType(EteeloLogo));
      expect(mark.variant, EteeloLogoVariant.symbolOnDark);
      expect(mark.size, size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un sceau remplacé ne laisse pas de trou le temps du décodage', (
      tester,
    ) async {
      final first = fakeSchoolLogo();
      await tester.pumpWidget(host(first));
      await decode(tester, first.bytes);

      // Mêmes pixels, autre instance : le cache d'images ne la connaît pas, le
      // codec doit repasser — et il ne répond pas avant la frame suivante.
      final second = SchoolLogo(
        sha256: 'sceau-2',
        bytes: Uint8List.fromList(schoolLogoPngBytes),
      );
      await tester.pumpWidget(host(second));

      expect(
        tester.widget<RawImage>(find.byType(RawImage)).image,
        isNotNull,
        reason: 'l\'ancien sceau doit tenir la vignette jusqu\'au nouveau',
      );
    });

    testWidgets('le sceau se nomme pour les lecteurs d\'écran', (tester) async {
      // Libérée DANS le test : `addTearDown` passerait après la vérification
      // de fin de test, qui refuse une poignée encore active.
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(host(fakeSchoolLogo()));

      expect(find.bySemanticsLabel('Logo de l\'école'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('fond de la vignette', () {
    final idle = AppColors.textOnDark.withValues(alpha: 0.08);

    test('pastille pleine sous un sceau', () {
      // Un logo aux traits foncés disparaîtrait sur le Bleu Profond.
      expect(
        SchoolBrandMark.plateColor(fakeSchoolLogo(), idle: idle),
        AppColors.blancCasse,
      );
    });

    test('sous le symbole ETEELO, la surface garde son fond', () {
      expect(SchoolBrandMark.plateColor(null, idle: idle), idle);
    });
  });
}
