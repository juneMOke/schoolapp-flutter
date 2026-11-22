import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_cubit.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_state.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/widgets/desktop_update_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Sur un poste de bureau, fournit [DesktopUpdateCubit] à toutes les routes et
/// ouvre la fenêtre de mise à jour — mais seulement sur l'accueil : jamais au
/// milieu d'une saisie (encaissement, notes, clôture, inscription), qui se
/// termine d'abord. Une mise à jour obligatoire attend de même.
///
/// Monté dans le `builder` de `MaterialApp.router`, au-dessus du `Navigator` :
/// la fenêtre est poussée sur celui du routeur.
class DesktopUpdateScope extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final GoRouter router;
  final DesktopUpdateCubit Function() createCubit;
  final void Function() onQuit;

  const DesktopUpdateScope({
    super.key,
    required this.child,
    required this.enabled,
    required this.router,
    required this.createCubit,
    required this.onQuit,
  });

  /// Les adresses où la fenêtre peut s'ouvrir.
  static bool isCalmLocation(String path) =>
      path == AppRoutesNames.homePath ||
      path.startsWith('${AppRoutesNames.homePath}/');

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return BlocProvider<DesktopUpdateCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(cubit.start());
        return cubit;
      },
      child: _DialogPresenter(router: router, onQuit: onQuit, child: child),
    );
  }
}

class _DialogPresenter extends StatefulWidget {
  final GoRouter router;
  final void Function() onQuit;
  final Widget child;

  const _DialogPresenter({
    required this.router,
    required this.onQuit,
    required this.child,
  });

  @override
  State<_DialogPresenter> createState() => _DialogPresenterState();
}

class _DialogPresenterState extends State<_DialogPresenter> {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_present);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_present);
    super.dispose();
  }

  bool get _calm => DesktopUpdateScope.isCalmLocation(
    widget.router.routerDelegate.currentConfiguration.uri.path,
  );

  /// Ouvre la fenêtre, ou annonce la version installée, quand l'adresse est
  /// calme. Appelé à chaque changement d'état et d'adresse.
  void _present() {
    if (!mounted) return;
    final navigatorContext =
        widget.router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    final cubit = context.read<DesktopUpdateCubit>();
    final state = cubit.state;
    if (!_calm && !state.requested) return;

    final justUpdated = state.justUpdatedTo;
    if (justUpdated != null && _calm) {
      final l10n = AppLocalizations.of(navigatorContext);
      if (l10n != null) {
        AppSnackBar.showSuccess(
          navigatorContext,
          l10n.desktopUpdateJustUpdated('$justUpdated'),
        );
        cubit.acknowledgeJustUpdated();
      }
    }

    if (_dialogOpen || !state.wantsDialog) return;
    _dialogOpen = true;
    unawaited(
      showEteeloAdaptiveDialog<void>(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: DesktopUpdateDialog(onQuit: widget.onQuit),
        ),
      ).whenComplete(() {
        _dialogOpen = false;
        // Une offre plus récente a pu arriver pendant que la fenêtre se
        // fermait.
        WidgetsBinding.instance.addPostFrameCallback((_) => _present());
      }),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<DesktopUpdateCubit, DesktopUpdateState>(
        listenWhen: (previous, current) =>
            previous.wantsDialog != current.wantsDialog ||
            previous.justUpdatedTo != current.justUpdatedTo ||
            previous.requested != current.requested,
        listener: (_, _) => _present(),
        child: widget.child,
      );
}

/// Le cubit de la mise à jour s'il est fourni (poste de bureau livré), sinon
/// `null` — la tablette, le web et les tests n'en ont pas.
DesktopUpdateCubit? maybeDesktopUpdateCubit(BuildContext context) {
  try {
    return BlocProvider.of<DesktopUpdateCubit>(context);
  } on FlutterError {
    return null;
  }
}
