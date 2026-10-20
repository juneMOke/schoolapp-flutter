import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';

/// Peut-on quitter l'écran de la coquille pour [targetSubMenuId] ?
///
/// L'écran quitté disparaît dès la sélection, avant que l'adresse ne change :
/// sa saisie en cours pose la question ici (`RouteExitGuard.mayLeave`).
/// Choisir l'écran où l'on est déjà ne quitte rien — aucune question.
FutureOr<bool> mayLeaveScreenFor(BuildContext context, String targetSubMenuId) {
  final current = context.read<NavigationBloc>().state.selectedSubMenuId;
  if (current == targetSubMenuId) return true;
  return RouteExitGuard.mayLeave(context);
}
