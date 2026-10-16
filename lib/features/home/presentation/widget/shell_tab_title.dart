import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le titre de l'onglet du navigateur (et de la fenêtre du poste) suit
/// l'écran ouvert dans la coquille : « Facturation · ETEELO CONNECT ». Dix
/// onglets de l'application ne se distinguent plus par leur seul nom.
class ShellTabTitle extends StatelessWidget {
  final Widget child;

  const ShellTabTitle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocSelector<NavigationBloc, NavigationState, String>(
      selector: (state) => state.currentTitle,
      builder: (context, page) => Title(
        title: page.isEmpty ? l10n.schoolApp : l10n.browserTabTitle(page),
        color: AppColors.bleuArdoise,
        child: child,
      ),
    );
  }
}
