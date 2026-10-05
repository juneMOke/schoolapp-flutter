import 'package:flutter/widgets.dart';

/// Rend la caméra au système quand l'application est cachée, et la reprend
/// au retour — le paquet `camera` laisse ce soin à l'application.
///
/// Seuls « caché » et « en pause » comptent : sur poste, une fenêtre qui perd
/// le focus est « inactive », et couper la webcam à chaque clic ailleurs
/// rendrait la séance inutilisable.
class CameraLifecycleGuard extends StatefulWidget {
  final VoidCallback onSuspend;
  final VoidCallback onResume;
  final Widget child;

  const CameraLifecycleGuard({
    super.key,
    required this.onSuspend,
    required this.onResume,
    required this.child,
  });

  @override
  State<CameraLifecycleGuard> createState() => _CameraLifecycleGuardState();
}

class _CameraLifecycleGuardState extends State<CameraLifecycleGuard>
    with WidgetsBindingObserver {
  bool _suspended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (_suspended) return;
        _suspended = true;
        widget.onSuspend();
      case AppLifecycleState.resumed:
        if (!_suspended) return;
        _suspended = false;
        widget.onResume();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
