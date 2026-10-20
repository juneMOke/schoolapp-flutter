import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Le titre de l'onglet du navigateur (et de la fenêtre du poste) pendant que
/// [child] est affiché.
///
/// Les titres s'empilent comme les pages : une fiche poussée au-dessus de la
/// coquille prend l'onglet (« Grâce Tshala · ETEELO CONNECT »), et le rend à
/// la coquille en se refermant — un `Title` seul ne restaure rien en
/// disparaissant. Plus aucun titre monté (déconnexion) : [fallback].
class BrowserTabTitle extends StatefulWidget {
  final String title;

  /// Le titre quand plus aucun écran n'en pose (le nom de l'application).
  final String fallback;
  final Widget child;

  const BrowserTabTitle({
    super.key,
    required this.title,
    required this.fallback,
    required this.child,
  });

  @override
  State<BrowserTabTitle> createState() => _BrowserTabTitleState();
}

class _BrowserTabTitleState extends State<BrowserTabTitle> {
  /// Les titres montés, le plus récent en dernier : c'est lui qui s'affiche.
  static final List<_BrowserTabTitleState> _stack = [];

  @override
  void initState() {
    super.initState();
    _stack.add(this);
  }

  @override
  void dispose() {
    _stack.remove(this);
    final top = _stack.lastOrNull;
    _apply(top?.widget.title ?? widget.fallback);
    super.dispose();
  }

  static void _apply(String label) =>
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: label,
          primaryColor: AppColors.bleuArdoise.toARGB32(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (identical(_stack.lastOrNull, this)) _apply(widget.title);
    return widget.child;
  }
}
