import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar.dart';

/// Le menu de la coquille en tiroir : barre toujours dépliée (le repli en
/// rail du bureau n'a pas de sens dans un tiroir), refermée dès qu'un écran
/// est choisi.
class ShellDrawer extends StatelessWidget {
  const ShellDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      width: AppTheme.sidebarWidth,
      elevation: 12,
      child: Sidebar(closeDrawerOnSubMenuSelection: true, forceExpanded: true),
    );
  }
}
