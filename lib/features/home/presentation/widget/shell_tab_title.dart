import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/web/browser_tab_title.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le titre de l'onglet du navigateur (et de la fenêtre du poste) suit
/// l'écran ouvert dans la coquille : « Facturation · ETEELO CONNECT ». Dix
/// onglets de l'application ne se distinguent plus par leur seul nom.
///
/// En quittant la coquille (déconnexion), le titre redevient le nom de
/// l'application ; une fiche poussée par-dessus prend l'onglet le temps d'être
/// ouverte (`BrowserTabTitle`).
class ShellTabTitle extends StatelessWidget {
  final Widget child;

  const ShellTabTitle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocSelector<NavigationBloc, NavigationState, String>(
      selector: (state) => state.currentTitle,
      builder: (context, page) => BrowserTabTitle(
        title: page.isEmpty ? l10n.schoolApp : l10n.browserTabTitle(page),
        fallback: l10n.schoolApp,
        child: child,
      ),
    );
  }
}
