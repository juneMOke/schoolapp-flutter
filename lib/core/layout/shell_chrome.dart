import 'package:flutter/widgets.dart';

/// Marque un écran rendu DANS la coquille : la barre d'en-tête y nomme déjà
/// le module et l'écran, et le menu y mène ailleurs.
///
/// Un écran servi aussi hors coquille (route propre, onglet) y pose sa
/// propre barre ; dans la coquille, elle s'empilait sous la première — deux
/// barres de titre, ~140 dp, sur une tablette en paysage de 600 dp.
class ShellChrome extends InheritedWidget {
  const ShellChrome({super.key, required super.child});

  /// `true` sous la coquille.
  static bool wraps(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellChrome>() != null;

  @override
  bool updateShouldNotify(ShellChrome oldWidget) => false;
}
