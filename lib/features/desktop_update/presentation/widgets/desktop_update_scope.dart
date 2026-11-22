import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
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

  /// Les adresses où la fenêtre peut s'ouvrir : l'accueil et les tableaux de
  /// bord, qui ne font que montrer. Jamais un écran de saisie (notes,
  /// clôture, inscription, vente…), même rangé sous `/home/…`, ni une page
  /// qui a une saisie en cours ([RouteExitGuard.anyUnsavedWork]).
  ///
  /// Une mise à jour [mandatory] s'ouvre aussi sur la connexion : un poste
  /// refusé par le serveur doit pouvoir se mettre à jour sans session.
  static bool isCalmLocation(String path, {required bool mandatory}) {
    if (RouteExitGuard.anyUnsavedWork) return false;
    if (mandatory &&
        (path == _loginPath || path.startsWith(_forgotPasswordPrefix))) {
      return true;
    }
    final segments = Uri(path: path).pathSegments;
    if ('/${segments.firstOrNull}' != AppRoutesNames.homePath) return false;
    if (segments.length == 1) return true;
    if (segments.length != 2) return false;
    final screen = segments.last;
    return screen == MenuConstants.accueilId ||
        screen == MenuConstants.treasuryDashboardId ||
        screen.endsWith('dashboard') ||
        screen.endsWith('tableau-de-bord');
  }

  static const _loginPath = '/login';
  static const _forgotPasswordPrefix = '/forgot-password';

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
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  /// Le routeur annonce la nouvelle adresse AVANT que le `Navigator` ait ses
  /// nouvelles pages : la fenêtre poussée tout de suite s'accrocherait à la
  /// page qui sort, disparaîtrait avec elle, puis reviendrait. Une image plus
  /// tard, les pages sont en place.
  void _onRouteChanged() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _present());

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  bool _calm(DesktopUpdateState state) => DesktopUpdateScope.isCalmLocation(
    widget.router.routerDelegate.currentConfiguration.uri.path,
    mandatory: state.mandatory,
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
    final calm = _calm(state);
    if (!calm && !state.requested) return;

    final justUpdated = state.justUpdatedTo;
    if (justUpdated != null && calm) {
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
        // La demande du menu est servie : fermée (ou emportée par un
        // changement de page), la fenêtre ne revient pas d'elle-même hors de
        // l'accueil.
        if (!cubit.isClosed) cubit.dialogClosed();
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
            // Devenue obligatoire : elle peut s'ouvrir là où la facultative
            // attendait (la connexion).
            previous.mandatory != current.mandatory ||
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
