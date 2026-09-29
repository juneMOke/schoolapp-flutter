import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux vides du fichier : aucun agent du tout, ou des filtres trop
/// étroits. Il remplace la zone de résultats seule : synthèse et filtres
/// restent au-dessus, ce sont eux qui expliquent le vide.
///
/// Créer passe par la garde des droits : un compte sans `hr.staff.write` ne se
/// voit jamais offrir un geste voué à l'échec.
class StaffEmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onResetFilters;

  /// Crée un agent — le premier, ou celui qu'on cherchait (prérempli avec les
  /// mots de la recherche) ; `null` quand il n'y a rien à proposer.
  final VoidCallback? onCreate;

  const StaffEmptyState({
    super.key,
    required this.filtered,
    required this.onResetFilters,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final create = onCreate;
    if (filtered) {
      return EteeloEmptyResult(
        label: l10n.staffEmptySearchTitle,
        description: l10n.staffEmptySearchMessage,
        medallionIcon: Icons.search_rounded,
        fullWidthCard: true,
        primaryAction: EteeloButton.primary(
          label: l10n.staffResetFilters,
          icon: Icons.restart_alt,
          onPressed: onResetFilters,
          fullWidth: false,
        ),
        secondaryAction: create == null
            ? null
            : PermissionGate.access(
                kStaffWriteAccess,
                child: EteeloButton.secondary(
                  label: l10n.staffActionCreateFromSearch,
                  icon: Icons.person_add_alt,
                  onPressed: create,
                  fullWidth: false,
                ),
              ),
      );
    }
    return EteeloEmptyResult(
      label: l10n.staffEmptyFileTitle,
      description: l10n.staffEmptyFileMessage,
      medallionIcon: Icons.groups_outlined,
      fullWidthCard: true,
      primaryAction: create == null
          ? null
          : PermissionGate.access(
              kStaffWriteAccess,
              child: EteeloButton.primary(
                label: l10n.staffActionAddFirst,
                icon: Icons.person_add_alt,
                onPressed: create,
                fullWidth: false,
              ),
            ),
    );
  }
}
