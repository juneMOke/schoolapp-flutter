import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';

/// Ctrl+B (⌘+B) replie et déplie le menu latéral de la coquille de bureau,
/// comme dans un éditeur — où que soit le focus, tant qu'aucune modale n'est
/// ouverte par-dessus.
class SidebarToggleShortcut extends StatelessWidget {
  final Widget child;

  const SidebarToggleShortcut({super.key, required this.child});

  static const List<SingleActivator> activators = [
    SingleActivator(LogicalKeyboardKey.keyB, control: true),
    SingleActivator(LogicalKeyboardKey.keyB, meta: true),
  ];

  @override
  Widget build(BuildContext context) => RouteKeyShortcut(
    activators: activators,
    onPressed: () => context.read<NavigationBloc>().add(const SidebarToggled()),
    child: child,
  );
}
