import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
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

  setUp(() {
    systemPops = 0;
    bloc = NavigationBloc(
      AppLocalizationsFr(),
      permissions: Perm.values.map((p) => p.wire).toList(),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pumpShell(WidgetTester tester) async {
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
              body: const Text('écran'),
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
}
