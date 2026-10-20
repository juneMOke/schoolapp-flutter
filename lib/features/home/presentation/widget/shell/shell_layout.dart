import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/shortcuts_help.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_back_handler.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_content_frame.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_drawer.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_navigation_mode.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_pull_to_sync.dart';
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
              final content = ShellPullToSync(
                child: ShellContentFrame(
                  state: state,
                  isCompact: mode.isDrawer,
                  child: KeyedSubtree(
                    key: _screenKey,
                    child: ShellChrome(
                      child: ShellScreen(
                        subMenuId: state.selectedSubMenuId,
                        title: state.currentTitle,
                      ),
                    ),
                  ),
                ),
              );
              if (mode == ShellNavigationMode.drawer) {
                return _drawerScaffold(content);
              }
              // Raccourcis (aide « ? », Ctrl+B) dès que le menu tient à
              // l'écran : une fenêtre de navigateur de 900 a un clavier.
              // En rail, Ctrl+B ouvre le menu complet. Même arbre dans les
              // deux formes : passer de l'une à l'autre ne remonte pas
              // l'écran.
              final rail = mode == ShellNavigationMode.rail;
              return ShortcutsHelpShortcut(
                child: SidebarToggleShortcut(
                  onToggle: rail ? _toggleDrawer : null,
                  child: _sidebarScaffold(content, rail: rail),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _drawerScaffold(Widget content) {
    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: _drawerScrim,
      appBar: const TopBar(isCompact: true),
      drawer: const ShellDrawer(),
      body: content,
    );
  }

  /// [rail] : barre fixée en 84 dp, dont l'écusson ouvre le menu complet en
  /// tiroir — le repli choisi au bureau n'y change rien.
  Widget _sidebarScaffold(Widget content, {required bool rail}) {
    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: _drawerScrim,
      drawer: rail ? const ShellDrawer() : null,
      body: Row(
        children: [
          Sidebar(
            forceCollapsed: rail,
            onExpandRequested: rail ? _openDrawer : null,
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(isCompact: false),
                // La barre d'en-tête a consommé la marge du haut, la barre
                // latérale celle de gauche : l'écran ne les compte pas une
                // seconde fois. Lu SOUS le `Scaffold` (`Builder`), qui a déjà
                // retiré le clavier : relu au-dessus, il était retiré deux
                // fois et la page s'écrasait dès qu'un champ prenait le focus.
                Expanded(
                  child: Builder(
                    builder: (context) => MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      removeLeft: true,
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  /// Ctrl+B en rail : ouvre le menu complet, ou le referme — une bascule,
  /// comme le repli de la barre.
  void _toggleDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold == null) return;
    scaffold.isDrawerOpen ? scaffold.closeDrawer() : scaffold.openDrawer();
  }

  static final _drawerScrim = AppColors.bleuProfond.withValues(alpha: 0.4);
}
