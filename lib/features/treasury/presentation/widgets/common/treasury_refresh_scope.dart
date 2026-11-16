import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Relire un écran de la trésorerie. Les écrans lisent en ligne — rien ne se
/// met à jour tout seul pendant la journée :
///
/// - sur un poste, F5 ou Ctrl+R ([keyboard]) ;
/// - sur une tablette ou un téléphone, tirer la page vers le bas ([pull]),
///   le geste que connaît la main. Il relit l'écran ET relance la
///   synchronisation, comme partout ailleurs dans l'application : la
///   clôture attend que les encaissements de la tablette soient partis.
///
/// [pull] se pose AU-DESSUS du défilement de la page (`AppPageBackground`) ;
/// le geste de la coquille, plus haut, ne se déclenche alors pas en double.
class TreasuryRefreshScope extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool keyboard;
  final bool pull;
  final Widget child;

  const TreasuryRefreshScope({
    super.key,
    required this.onRefresh,
    this.keyboard = true,
    this.pull = true,
    required this.child,
  });

  /// Le tactile natif : à la souris, rien ne se « tire ».
  static bool get isTouchApp =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _pulled(BuildContext context) async {
    SyncStatusCubit? sync;
    try {
      sync = context.read<SyncStatusCubit>();
    } on ProviderNotFoundException {
      sync = null;
    }
    await Future.wait([onRefresh(), ?sync?.syncNow()]);
  }

  @override
  Widget build(BuildContext context) {
    var screen = child;
    if (pull && isTouchApp) {
      screen = NotificationListener<ScrollNotification>(
        // Le défilement de la page s'arrête ici : la coquille ne relance
        // pas une deuxième fois la synchronisation.
        onNotification: (notification) => notification.depth == 0,
        child: RefreshIndicator(
          color: AppColors.bleuArdoise,
          onRefresh: () => _pulled(context),
          child: screen,
        ),
      );
    }
    if (!keyboard) return screen;
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: onRefresh,
      child: screen,
    );
  }
}
