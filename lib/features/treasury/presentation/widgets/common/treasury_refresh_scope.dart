import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Relire un écran de la trésorerie. Les écrans lisent en ligne — rien ne se
/// met à jour tout seul pendant la journée :
///
/// - sur un poste, F5 ou Ctrl+R ([keyboard]) ;
/// - sur une tablette ou un téléphone, tirer la page vers le bas ([pull]),
///   le geste que connaît la main. Il relit l'écran ET relance la
///   synchronisation, comme partout ailleurs dans l'application ;
/// - la file d'envoi vidée ([refreshOnSynced]).
///
/// [pull] se pose AU-DESSUS du défilement de la page (`AppPageBackground`) ;
/// le geste de la coquille, plus haut, ne se déclenche alors pas en double.
class TreasuryRefreshScope extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final bool keyboard;
  final bool pull;

  /// Relire aussi quand la synchronisation se termine. La Clôture attend que
  /// les encaissements de la tablette soient partis : la file vidée, le
  /// compteur « pas encore envoyés » tombe, l'écran relit. La page tirée
  /// synchronise alors d'abord, puis relit une seule fois.
  final bool refreshOnSynced;
  final Widget child;

  const TreasuryRefreshScope({
    super.key,
    required this.onRefresh,
    this.keyboard = true,
    this.pull = true,
    this.refreshOnSynced = false,
    required this.child,
  });

  /// Où la page se tire : la tablette et le téléphone, natifs ou dans un
  /// navigateur. Le navigateur d'un ordinateur garde F5 et le bouton
  /// « Actualiser » : à la souris, rien ne se « tire ».
  static bool get pullsToRefresh => kIsWeb
      ? !expectsPhysicalKeyboard
      : defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;

  /// La relecture de l'écran qui englobe [context], pour un bouton
  /// « Actualiser » ; `null` hors d'un [TreasuryRefreshScope].
  static Future<void> Function()? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_TreasuryRefreshInherited>()
      ?.onRefresh;

  @override
  State<TreasuryRefreshScope> createState() => _TreasuryRefreshScopeState();
}

class _TreasuryRefreshScopeState extends State<TreasuryRefreshScope> {
  /// La page tirée relit elle-même après la synchronisation : la fin de
  /// celle-ci ne relance pas une deuxième lecture.
  var _pulling = false;

  /// Le cubit global de synchronisation, absent dans les tests d'écran.
  SyncStatusCubit? _sync() {
    try {
      return context.read<SyncStatusCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _pulled() async {
    // Le web n'a pas de base locale à resynchroniser : il relit seulement.
    final sync = kIsWeb ? null : _sync();
    if (sync == null || !widget.refreshOnSynced) {
      await Future.wait([widget.onRefresh(), ?sync?.syncNow()]);
      return;
    }
    _pulling = true;
    try {
      await sync.syncNow();
      if (mounted) await widget.onRefresh();
    } finally {
      _pulling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screen = widget.child;
    if (widget.pull && TreasuryRefreshScope.pullsToRefresh) {
      screen = NotificationListener<ScrollNotification>(
        // Le défilement de la page s'arrête ici : la coquille ne relance
        // pas une deuxième fois la synchronisation.
        onNotification: (notification) => notification.depth == 0,
        child: RefreshIndicator(
          color: AppColors.bleuArdoise,
          onRefresh: _pulled,
          child: screen,
        ),
      );
    }
    final sync = widget.refreshOnSynced ? _sync() : null;
    if (sync != null) {
      screen = BlocListener<SyncStatusCubit, SyncStatusState>(
        bloc: sync,
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == SyncStatus.synced,
        listener: (_, _) {
          if (!_pulling) widget.onRefresh();
        },
        child: screen,
      );
    }
    screen = _TreasuryRefreshInherited(
      onRefresh: widget.onRefresh,
      child: screen,
    );
    if (!widget.keyboard) return screen;
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: widget.onRefresh,
      child: screen,
    );
  }
}

class _TreasuryRefreshInherited extends InheritedWidget {
  final Future<void> Function() onRefresh;

  const _TreasuryRefreshInherited({
    required this.onRefresh,
    required super.child,
  });

  @override
  bool updateShouldNotify(_TreasuryRefreshInherited oldWidget) =>
      onRefresh != oldWidget.onRefresh;
}
