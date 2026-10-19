import 'package:flutter/widgets.dart';

/// Un retour système qu'un écran sait traiter lui-même.
abstract interface class ScreenBackHandler {
  /// `true` si l'écran a consommé le retour (il est remonté d'un niveau).
  bool handleBack();
}

/// Les écrans à niveaux (liste → détail) montés sous une coquille qui garde
/// le retour système pour elle.
///
/// ⚠️ Deux `PopScope` fermés sur la même route sont TOUS deux appelés : celui
/// de la coquille ramenait à l'Accueil pendant que celui de l'écran remontait
/// d'un niveau. La coquille consulte donc ce registre d'abord, et l'écran ne
/// pose pas de `PopScope` (cf. `ScreenBackScope`).
class ScreenBackRegistry {
  final _handlers = <ScreenBackHandler>[];

  void add(ScreenBackHandler handler) => _handlers.add(handler);

  void remove(ScreenBackHandler handler) => _handlers.remove(handler);

  /// Le plus récent d'abord : un niveau ouvert dans un écran passe avant lui.
  bool handleBack() {
    for (final handler in _handlers.reversed) {
      if (handler.handleBack()) return true;
    }
    return false;
  }

  static ScreenBackRegistry? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ScreenBackRegistryScope>()
      ?.registry;
}

/// Fournit un [ScreenBackRegistry] aux écrans de la coquille.
class ScreenBackRegistryScope extends InheritedWidget {
  final ScreenBackRegistry registry;

  const ScreenBackRegistryScope({
    super.key,
    required this.registry,
    required super.child,
  });

  @override
  bool updateShouldNotify(ScreenBackRegistryScope oldWidget) =>
      registry != oldWidget.registry;
}
