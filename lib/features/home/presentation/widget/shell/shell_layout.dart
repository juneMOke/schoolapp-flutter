import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/shortcuts_help.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_back_handler.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_content_frame.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_drawer.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_navigation_mode.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_screen.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_toggle_shortcut.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar.dart';

/// La coquille : menu (tiroir ou barre latérale), barre d'en-tête et écran
/// choisi.
///
/// ⚠️ Franchir le seuil tiroir ↔ barre (rotation d'une 10", écran partagé)
/// change la forme de l'arbre. L'écran est porté par une [GlobalKey] : il est
/// DÉPLACÉ, jamais remonté — brouillon de notes, panier, appel en cours,
/// filtres et défilement survivent, et les `FeatureScope` ne relancent pas
/// leurs pulls. Le `Scaffold` a la sienne pour la même raison (et pour que
/// le retour système referme le tiroir).
class ShellLayout extends StatefulWidget {
  const ShellLayout({super.key});

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  final _screenKey = GlobalKey(debugLabel: 'shell-screen');
  final _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'shell-scaffold');

  @override
  Widget build(BuildContext context) {
    return ShellBackHandler(
      scaffoldKey: _scaffoldKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mode = ShellNavigationMode.forWidth(constraints.maxWidth);
          return BlocBuilder<NavigationBloc, NavigationState>(
            buildWhen: (previous, current) =>
                previous.currentTitle != current.currentTitle ||
                previous.selectedMenuId != current.selectedMenuId ||
                previous.selectedSubMenuId != current.selectedSubMenuId,
            builder: (context, state) {
              final content = ShellContentFrame(
                state: state,
                isCompact: mode.isDrawer,
                child: KeyedSubtree(
                  key: _screenKey,
                  child: ShellScreen(
                    subMenuId: state.selectedSubMenuId,
                    title: state.currentTitle,
                  ),
                ),
              );
              return mode.isDrawer
                  ? _drawerScaffold(content)
                  : _sidebarScaffold(content);
            },
          );
        },
      ),
    );
  }

  Widget _drawerScaffold(Widget content) {
    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: AppColors.bleuProfond.withValues(alpha: 0.4),
      appBar: const TopBar(isCompact: true),
      drawer: const ShellDrawer(),
      body: content,
    );
  }

  /// Raccourcis (aide « ? », repli de la barre) au clavier physique : seuls
  /// les grands écrans en ont un ; sur un téléphone, ils n'écoutent rien.
  Widget _sidebarScaffold(Widget content) {
    return ShortcutsHelpShortcut(
      child: SidebarToggleShortcut(
        child: Scaffold(
          key: _scaffoldKey,
          body: Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    const TopBar(isCompact: false),
                    // La barre d'en-tête a consommé la marge du haut, la
                    // barre latérale celle de gauche : l'écran ne les
                    // compte pas une seconde fois.
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        removeLeft: true,
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
