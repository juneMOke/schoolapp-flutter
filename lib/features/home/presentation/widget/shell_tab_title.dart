import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le titre de l'onglet du navigateur (et de la fenêtre du poste) suit
/// l'écran ouvert dans la coquille : « Facturation · ETEELO CONNECT ». Dix
/// onglets de l'application ne se distinguent plus par leur seul nom.
///
/// En quittant la coquille (déconnexion), le titre redevient le nom de
/// l'application : un `Title` ne restaure rien en disparaissant, et celui de
/// la racine ne se reconstruit pas — l'écran de connexion garderait sinon
/// « Facturation ».
class ShellTabTitle extends StatefulWidget {
  final Widget child;

  const ShellTabTitle({super.key, required this.child});

  @override
  State<ShellTabTitle> createState() => _ShellTabTitleState();
}

class _ShellTabTitleState extends State<ShellTabTitle> {
  late String _appName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appName = AppLocalizations.of(context)!.schoolApp;
  }

  @override
  void dispose() {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: _appName,
        primaryColor: AppColors.bleuArdoise.toARGB32(),
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocSelector<NavigationBloc, NavigationState, String>(
      selector: (state) => state.currentTitle,
      builder: (context, page) => Title(
        title: page.isEmpty ? _appName : l10n.browserTabTitle(page),
        color: AppColors.bleuArdoise,
        child: widget.child,
      ),
    );
  }
}
