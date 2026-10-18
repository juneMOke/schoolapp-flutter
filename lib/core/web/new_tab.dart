import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvrir un écran dans un **nouvel onglet**, comme sur tout site : Ctrl+clic
/// (⌘+clic sur Mac) ou clic molette. Web seulement — sur un poste ou une
/// tablette, il n'y a pas d'onglet.
///
/// Ne sert qu'aux écrans qui ont une adresse (`/home/{sousMenu}`) : un onglet
/// ouvert sur une page sans adresse retomberait sur l'Accueil.
class NewTab {
  const NewTab._();

  /// Faux hors du web. Ouvert aux tests.
  @visibleForTesting
  static bool enabled = kIsWeb;

  /// L'ouverture elle-même. Remplacée par les tests.
  @visibleForTesting
  static Future<void> Function(Uri uri) launch = _launch;

  static Future<void> _launch(Uri uri) async {
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  /// Le clic en cours vise-t-il un nouvel onglet ?
  static bool get requestedByModifier {
    if (!enabled) return false;
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  static Future<void> open(String path) => launch(Uri.base.resolve(path));
}

/// Le clic molette sur [child] ouvre [path] dans un nouvel onglet ; Ctrl+clic
/// se lit dans le `onTap` de l'appelant via [NewTab.requestedByModifier].
class MiddleClickOpensTab extends StatelessWidget {
  final String path;
  final Widget child;

  const MiddleClickOpensTab({
    super.key,
    required this.path,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!NewTab.enabled) return child;
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kMiddleMouseButton) {
          NewTab.open(path);
        }
      },
      child: child,
    );
  }
}
