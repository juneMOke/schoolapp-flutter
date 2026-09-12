import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre de l'écran nominatif ouvert HORS de la coquille — c'est-à-dire
/// poussé par le tableau de bord : l'œil d'un niveau, ou « Voir le contrôle ».
///
/// Sa flèche dépile : le tableau de bord se retrouve tel qu'on l'a quitté,
/// frais retenus et cycle déplié compris. Revenir par le menu l'aurait rechargé
/// à neuf.
class RecouvrementControlTopBar extends StatelessWidget
    implements PreferredSizeWidget {
  const RecouvrementControlTopBar({super.key});

  @override
  Size get preferredSize => ModuleTopBar.barSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OffShellTopBar(
      eyebrow: l10n.menuRecouvrement,
      title: l10n.subMenuFeeControl,
      backTooltip: l10n.recouvrementControlBack,
      shellSubMenuId: MenuConstants.recouvrementDashboardId,
    );
  }
}
