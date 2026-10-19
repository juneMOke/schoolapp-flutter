import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell_location_sync.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le retour système (bouton ou geste Android) dans la coquille.
///
/// La coquille est UNE page : ses écrans changent d'adresse
/// (`/home/{sousMenu}`) sans s'empiler. Sans ce gardien, le retour la
/// dépilait — et quittait l'app — depuis n'importe quel écran. Dans l'ordre :
///
/// 1. le tiroir ouvert se referme ;
/// 2. un écran autre que l'Accueil ramène à l'Accueil ;
/// 3. à l'Accueil, sur Android, un premier appui prévient, le second dans la
///    fenêtre [AppMotion.exitConfirmWindow] quitte.
///
/// Ailleurs (iOS, bureau, web), l'Accueil laisse le retour suivre son cours :
/// il n'y a pas de bouton à confondre avec une sortie.
class ShellBackHandler extends StatefulWidget {
  /// Le `Scaffold` de la coquille, pour en refermer le tiroir.
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget child;

  const ShellBackHandler({
    super.key,
    required this.scaffoldKey,
    required this.child,
  });

  @override
  State<ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<ShellBackHandler> {
  Timer? _exitWindow;

  bool get _confirmsExit =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _exitWindow?.cancel();
    super.dispose();
  }

  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    final scaffold = widget.scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
      return;
    }
    final bloc = context.read<NavigationBloc>();
    if (bloc.state.selectedSubMenuId != MenuConstants.accueilId) {
      ShellLocationSync.select(bloc, null, AppLocalizations.of(context)!);
      return;
    }
    if (_exitWindow?.isActive ?? false) {
      SystemNavigator.pop();
      return;
    }
    _exitWindow = Timer(AppMotion.exitConfirmWindow, () {});
    AppSnackBar.showInfo(
      context,
      AppLocalizations.of(context)!.shellBackAgainToExit,
      duration: AppMotion.exitConfirmWindow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) =>
          previous.selectedSubMenuId != current.selectedSubMenuId,
      builder: (context, state) => PopScope(
        // Le tiroir, lui, se gère par son entrée d'historique locale — mais
        // un `PopScope` fermé la court-circuite : `_onBack` le referme.
        canPop:
            !_confirmsExit &&
            state.selectedSubMenuId == MenuConstants.accueilId,
        onPopInvokedWithResult: _onBack,
        child: widget.child,
      ),
    );
  }
}
