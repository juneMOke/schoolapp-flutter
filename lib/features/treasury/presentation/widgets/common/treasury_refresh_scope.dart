import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';

/// Relire un écran de la trésorerie : F5 ou Ctrl+R sur un poste. Les écrans
/// lisent en ligne — rien ne se met à jour tout seul pendant la journée.
class TreasuryRefreshScope extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const TreasuryRefreshScope({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => PageActionShortcut(
    action: PageAction.refresh,
    onInvoke: onRefresh,
    child: child,
  );
}
