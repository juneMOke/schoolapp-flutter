import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/navigation/screen_back_registry.dart';

/// Le retour système d'un écran à niveaux : tant que [canPop] est faux, le
/// retour appelle [onBack] (remonter d'un niveau) au lieu de quitter l'écran.
///
/// Sous une coquille qui tient un [ScreenBackRegistry], l'écran s'y inscrit ;
/// ailleurs (page poussée), c'est un simple `PopScope`.
class ScreenBackScope extends StatefulWidget {
  /// `true` : l'écran est à son premier niveau, le retour ne le concerne pas.
  final bool canPop;
  final VoidCallback onBack;
  final Widget child;

  const ScreenBackScope({
    super.key,
    required this.canPop,
    required this.onBack,
    required this.child,
  });

  @override
  State<ScreenBackScope> createState() => _ScreenBackScopeState();
}

class _ScreenBackScopeState extends State<ScreenBackScope>
    implements ScreenBackHandler {
  ScreenBackRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = ScreenBackRegistry.maybeOf(context);
    if (identical(registry, _registry)) return;
    _registry?.remove(this);
    _registry = registry?..add(this);
  }

  @override
  void dispose() {
    _registry?.remove(this);
    super.dispose();
  }

  @override
  bool handleBack() {
    if (widget.canPop) return false;
    widget.onBack();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_registry != null) return widget.child;
    return PopScope(
      canPop: widget.canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: widget.child,
    );
  }
}
