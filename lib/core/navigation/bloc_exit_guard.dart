import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/discard_changes_confirmation.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';

/// Une [RouteExitGuard] dont la saisie se lit dans l'état d'un bloc [B].
///
/// La garde ne se reconstruit que quand [hasUnsavedWork] ou [isBusy]
/// basculent : c'est là que l'avertissement de fermeture de l'onglet
/// (`beforeunload`) s'arme ou se lève, sans reconstruire la page à chaque
/// frappe.
class BlocExitGuard<B extends StateStreamable<S>, S> extends StatelessWidget {
  final bool Function(S state) hasUnsavedWork;
  final bool Function(S state) isBusy;

  /// Ce qui serait perdu, dans la question posée avant de partir.
  final String? discardMessage;
  final Widget child;

  const BlocExitGuard({
    super.key,
    required this.hasUnsavedWork,
    this.isBusy = _never,
    this.discardMessage,
    required this.child,
  });

  static bool _never(Object? _) => false;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<B, S, ({bool dirty, bool busy})>(
        selector: (state) =>
            (dirty: hasUnsavedWork(state), busy: isBusy(state)),
        builder: (context, guard) => RouteExitGuard(
          hasUnsavedWork: () => guard.dirty,
          isBusy: () => guard.busy,
          confirmExit: () =>
              confirmDiscardChanges(context, message: discardMessage),
          child: child,
        ),
      );
}
