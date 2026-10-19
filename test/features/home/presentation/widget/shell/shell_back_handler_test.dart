import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/navigation/screen_back_scope.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_back_handler.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Le retour Android dans la coquille : il ne quitte plus l'app depuis un
/// écran du menu — tiroir, puis Accueil, puis double appui.
void main() {
  late NavigationBloc bloc;
  late int systemPops;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  setUp(() => systemPops = 0);

  Future<void> pumpShell(
    WidgetTester tester, {
    Widget body = const Text('écran'),
  }) async {
    // Né DANS le test : créé dans `setUp`, hors de la zone de `testWidgets`,
    // ses écouteurs (la fenêtre de sortie) ne seraient jamais servis sous
    // `pump()`.
    bloc = NavigationBloc(
      AppLocalizationsFr(),
      permissions: Perm.values.map((p) => p.wire).toList(),
    );
    addTearDown(bloc.close);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') systemPops++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: ShellBackHandler(
            scaffoldKey: scaffoldKey,
            child: Scaffold(
              key: scaffoldKey,
              drawer: const Drawer(child: Text('menu')),
              body: body,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  void selectFacturation() => bloc.add(
    const SubMenuItemSelected(
      menuId: MenuConstants.financesMenuId,
      subMenuId: MenuConstants.facturationsId,
      title: 'Facturations',
    ),
  );

  testWidgets('le tiroir ouvert se referme, l\'écran reste', (tester) async {
    await pumpShell(tester);
    selectFacturation();
    await tester.pumpAndSettle();
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    await back(tester);

    expect(scaffoldKey.currentState!.isDrawerOpen, isFalse);
    expect(bloc.state.selectedSubMenuId, MenuConstants.facturationsId);
    expect(systemPops, 0);
  });

  testWidgets('un écran du menu ramène à l\'Accueil', (tester) async {
    await pumpShell(tester);
    selectFacturation();
    await tester.pumpAndSettle();

    await back(tester);

    expect(bloc.state.selectedSubMenuId, MenuConstants.accueilId);
    expect(systemPops, 0);
  });

  testWidgets('à l\'Accueil, le premier appui prévient, le second quitte', (
    tester,
  ) async {
    await pumpShell(tester);

    await back(tester);
    expect(find.text('Appuyez de nouveau sur Retour pour quitter'), findsOne);
    expect(systemPops, 0);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(systemPops, 1);
  });

  testWidgets('passé la fenêtre, il faut de nouveau deux appuis', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.binding.handlePopRoute();
    await tester.pump(AppMotion.exitConfirmWindow);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(systemPops, 0);
  });

  testWidgets('hors Android, l\'Accueil laisse le retour suivre son cours', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpShell(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;

    expect(systemPops, 1);
  });

  testWidgets('un écran à niveaux remonte d\'un niveau, sans quitter', (
    tester,
  ) async {
    var levelBacks = 0;
    await pumpShell(
      tester,
      body: ScreenBackScope(
        canPop: false,
        onBack: () => levelBacks++,
        child: const Text('détail'),
      ),
    );
    selectFacturation();
    await tester.pumpAndSettle();

    await back(tester);

    // Un seul des deux gardiens agit : le niveau, pas le retour à l'Accueil.
    expect(levelBacks, 1);
    expect(bloc.state.selectedSubMenuId, MenuConstants.facturationsId);
  });

  testWidgets('quitter l\'Accueil referme la fenêtre de sortie', (
    tester,
  ) async {
    await pumpShell(tester);
    await back(tester); // prévient
    selectFacturation();
    await tester.pumpAndSettle();
    await back(tester); // revient à l'Accueil

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(systemPops, 0);
  });
}
