import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre de la Facturation ouverte HORS de la coquille — poussée par le
/// contrôle nominatif du Recouvrement (« Facturer »), ou rejointe par une fiche
/// qui n'avait rien à dépiler.
///
/// Sa flèche dépile vers l'écran d'où l'on vient ; sans rien sous elle, elle
/// rejoint la Facturation DANS la coquille.
class FacturationTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FacturationTopBar({super.key});

  @override
  Size get preferredSize => ModuleTopBar.barSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OffShellTopBar(
      eyebrow: l10n.menuFinances,
      title: l10n.subMenuBilling,
      backTooltip: l10n.facturationOffShellBack,
      shellSubMenuId: MenuConstants.facturationsId,
    );
  }
}
