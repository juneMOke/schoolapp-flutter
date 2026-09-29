import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux vides du registre : aucun agent (renvoi vers le fichier du
/// personnel), ou des filtres trop étroits (« Tout afficher »).
class StaffRegisterEmpty extends StatelessWidget {
  final bool filtered;

  /// Le statut filtré, pour dire « Tout le monde est pointé » sur « À pointer ».
  final StaffAttendanceStatus? status;

  /// Retire les filtres ; requis quand [filtered].
  final VoidCallback? onShowAll;

  const StaffRegisterEmpty({
    super.key,
    required this.filtered,
    this.onShowAll,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!filtered) {
      return EteeloEmptyResult(
        label: l10n.staffAttendanceEmptyTitle,
        description: l10n.staffAttendanceEmptyMessage,
        medallionIcon: Icons.groups_outlined,
        fullWidthCard: true,
        // Dans la coquille, comme un choix du menu : une route seule
        // afficherait la page nue, sans barre ni retour.
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
    return EteeloEmptyResult(
      label: status == StaffAttendanceStatus.none
          ? l10n.staffAttendanceAllMarked
          : l10n.staffAttendanceEmptyFilterTitle,
      medallionIcon: status == StaffAttendanceStatus.none
          ? Icons.task_alt
          : Icons.search_rounded,
      fullWidthCard: true,
      primaryAction: EteeloButton.primary(
        label: l10n.staffAttendanceShowAll,
        icon: Icons.restart_alt,
        onPressed: onShowAll,
        fullWidth: false,
      ),
    );
  }
}
