import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_header_collapsed.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_header_expanded.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../school/school_logo_fixture.dart';

class _MockSchoolRepository extends Mock implements SchoolRepository {}

void main() {
  SchoolIdentityCubit cubitWith(SchoolLogo? logo) {
    final cubit = SchoolIdentityCubit(repository: _MockSchoolRepository());
    cubit.emit(SchoolIdentityState(logo: logo));
    return cubit;
  }

  Widget host(Widget child, {SchoolIdentityCubit? cubit}) {
    return MaterialApp(
      locale: const Locale('fr'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        // La barre latérale est Bleu Profond : c'est sur ce fond que la
        // question de la lisibilité du sceau se pose.
        backgroundColor: AppTheme.sidebarColor,
        body: cubit == null
            ? child
            : BlocProvider<SchoolIdentityCubit>.value(
                value: cubit,
                child: child,
              ),
      ),
    );
  }

  /// La couleur de la vignette qui porte la marque.
  Color? vignetteColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    return (box.decoration as BoxDecoration).color;
  }

  group('tête repliée', () {
    testWidgets('sans sceau, le symbole ETEELO tient la place', (tester) async {
      final cubit = cubitWith(null);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        host(const SidebarHeaderCollapsed(), cubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EteeloLogo), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(vignetteColor(tester), isNot(AppColors.blancCasse));
    });

    testWidgets(
      'le sceau de l\'école remplace le symbole, sur pastille pleine',
      (tester) async {
        final cubit = cubitWith(fakeSchoolLogo());
        addTearDown(cubit.close);

        await tester.pumpWidget(
          host(const SidebarHeaderCollapsed(), cubit: cubit),
        );
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(EteeloLogo), findsNothing);
        expect(vignetteColor(tester), AppColors.blancCasse);
      },
    );
  });

  group('tête dépliée', () {
    testWidgets('sans sceau, aucune pastille sous le symbole ETEELO', (
      tester,
    ) async {
      // Une pastille pleine sous le symbole, dessiné pour le Bleu Profond, se
      // lirait comme un cerne.
      final cubit = cubitWith(null);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        host(const SidebarHeaderExpanded(), cubit: cubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EteeloLogo), findsOneWidget);
      expect(vignetteColor(tester), Colors.transparent);
    });

    testWidgets(
      'le sceau de l\'école arrive sur sa pastille, un cran plus petit',
      (tester) async {
        final cubit = cubitWith(fakeSchoolLogo());
        addTearDown(cubit.close);

        await tester.pumpWidget(
          host(const SidebarHeaderExpanded(), cubit: cubit),
        );
        await tester.pump();

        expect(vignetteColor(tester), AppColors.blancCasse);
        // Sans cette marge, un logo à fond blanc toucherait sa pastille bord à
        // bord et s'y confondrait.
        final image = tester.widget<Image>(find.byType(Image));
        expect(
          image.width,
          HomeNavigationUiTokens.sidebarBrandExpandedSchoolLogoSize,
        );
        expect(
          image.width,
          lessThan(HomeNavigationUiTokens.sidebarBrandExpandedSize),
        );
      },
    );
  });

  testWidgets('cubit absent de l\'arbre : la tête tient quand même', (
    tester,
  ) async {
    // Montage isolé (test de layout) : aucun bloc de session au-dessus.
    await tester.pumpWidget(host(const SidebarHeaderCollapsed()));
    await tester.pumpAndSettle();

    expect(find.byType(EteeloLogo), findsOneWidget);
  });
}
