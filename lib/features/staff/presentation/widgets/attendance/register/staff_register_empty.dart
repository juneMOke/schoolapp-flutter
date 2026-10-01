import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Aucun agent sur la tablette : renvoi vers le fichier du personnel.
class StaffRegisterEmpty extends StatelessWidget {
  const StaffRegisterEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.staffAttendanceEmptyTitle,
      description: l10n.staffAttendanceEmptyMessage,
      medallionIcon: Icons.groups_outlined,
      fullWidthCard: true,
      // Dans la coquille, comme un choix du menu : une route seule afficherait
      // la page nue, sans barre ni retour.
      primaryAction: PermissionGate(
        requires: const [Perm.hrStaffRead],
        child: EteeloButton.primary(
          label: l10n.staffAttendanceOpenStaffFile,
          icon: Icons.badge_outlined,
          onPressed: () => context.read<NavigationBloc>().add(
            SubMenuItemSelected(
              menuId: MenuConstants.hrMenuId,
              subMenuId: MenuConstants.hrStaffFileId,
              title: l10n.subMenuStaffFile,
            ),
          ),
          fullWidth: false,
        ),
      ),
    );
  }
}
