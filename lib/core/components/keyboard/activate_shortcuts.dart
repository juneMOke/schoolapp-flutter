import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Entrée, Entrée du pavé et Espace activent l'élément au focus — une fois
/// par appui. La répétition d'une touche MAINTENUE est absorbée : sans cela,
/// Entrée gardée enfoncée sur le bouton qui ouvre une confirmation l'ouvre
/// puis la valide d'elle-même, et un en-tête de tri bascule en rafale.
///
/// L'absorber, et pas seulement l'ignorer : ignorée ici, la répétition
/// remonterait aux raccourcis par défaut de l'application, qui l'acceptent.
///
/// Espace est explicite : sur le web, elle fait défiler la page par défaut.
const Map<ShortcutActivator, Intent> kActivateOncePerPress = {
  SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
      ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter, includeRepeats: false):
      ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
      ActivateIntent(),
  _KeyRepeat(LogicalKeyboardKey.enter): DoNothingAndStopPropagationIntent(),
  _KeyRepeat(LogicalKeyboardKey.numpadEnter):
      DoNothingAndStopPropagationIntent(),
  _KeyRepeat(LogicalKeyboardKey.space): DoNothingAndStopPropagationIntent(),
};

/// La seule répétition automatique de [key], quels que soient les modifieurs.
class _KeyRepeat extends ShortcutActivator {
  final LogicalKeyboardKey key;

  const _KeyRepeat(this.key);

  @override
  Iterable<LogicalKeyboardKey> get triggers => [key];

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      event is KeyRepeatEvent && event.logicalKey == key;

  @override
  String debugDescribeKeys() => 'repeat ${key.keyLabel}';
}
