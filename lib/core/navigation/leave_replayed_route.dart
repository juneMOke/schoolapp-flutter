import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Une page que l'historique du navigateur rejoue alors qu'elle n'a plus
/// lieu d'être (un encaissement déjà écrit, rouvert par Précédent ou
/// Suivant ; ou rouvert après F5 sans ce qu'il encaissait) : elle s'efface
/// aussitôt, vers la page d'en dessous, ou vers [fallbackLocation] quand
/// rien n'est dessous.
///
/// La redirection de la route ne suffit pas : go_router ne la rejoue pas
/// pour une page empilée qu'il restaure.
class LeaveReplayedRoute extends StatefulWidget {
  final String fallbackLocation;

  const LeaveReplayedRoute({super.key, required this.fallbackLocation});

  @override
  State<LeaveReplayedRoute> createState() => _LeaveReplayedRouteState();
}

class _LeaveReplayedRouteState extends State<LeaveReplayedRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(widget.fallbackLocation);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
