import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Tirer l'écran vers le bas relance la synchronisation, comme le geste de la
/// feuille de synchro — le seul que connaît la main d'un utilisateur de
/// téléphone. L'écran suit ensuite ce qui descend, comme après tout cycle.
///
/// Réservé au tactile natif : à la souris, rien ne se « tire », et la version
/// web n'a pas de base locale à resynchroniser.
class ShellPullToSync extends StatelessWidget {
  final Widget child;

  const ShellPullToSync({super.key, required this.child});

  static bool get _isTouchApp =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    if (!_isTouchApp) return child;
    return RefreshIndicator(
      color: AppColors.bleuArdoise,
      // Le défilement de la page (celui d'`AppPageBackground`) est le premier
      // sous la coquille : profondeur 0, le prédicat par défaut le voit. Une
      // liste imbriquée dans la page, elle, ne déclenche rien.
      onRefresh: () => context.read<SyncStatusCubit>().syncNow(),
      child: child,
    );
  }
}
