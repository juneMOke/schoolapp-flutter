import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_group_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le détail par classe d'un niveau déplié.
///
/// Décalé et sans titre : c'est la même mesure, d'un cran plus fin. Un en-tête
/// de section en ferait un second tableau.
class FeeControlDashboardClassRows extends StatelessWidget {
  final EnrollmentLoadStatus status;
  final List<FeeControlClassRow> classes;
  final bool classroomsMissing;

  /// Ouvre l'écran nominatif sur une classe — `null` pour les non-répartis, qui
  /// ne forment pas une classe à transmettre.
  /// `null` quand le niveau lui-même n'est pas transmissible : aucune de ses
  /// classes ne l'est alors non plus.
  final void Function(FeeControlClassRow row)? onOpenControl;

  const FeeControlDashboardClassRows({
    super.key,
    required this.status,
    required this.classes,
    required this.classroomsMissing,
    required this.onOpenControl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingL,
        bottom: AppDimensions.spacingS,
      ),
      child: switch (status) {
        // Le seul retour qu'un lecteur d'écran reçoive du dépliage : sans
        // libellé ni région vive, taper un niveau ne dit RIEN jusqu'à ce que
        // les classes arrivent — et une barre de progression muette ne se lit
        // pas.
        EnrollmentLoadStatus.loading => Semantics(
          label: l10n.feeControlDashboardClassesLoading,
          liveRegion: true,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ),
        EnrollmentLoadStatus.failure => _Note(
          l10n.feeControlDashboardClassesFailed,
        ),
        EnrollmentLoadStatus.success when classroomsMissing => _Note(
          // Deux causes derrière « aucune classe », et une seule se résoudra
          // par une synchronisation. Sans `classroom.read`, le roster n'est
          // jamais tiré : dire « pas encore descendue » enverrait chercher
          // côté synchro un manque qui est côté droits.
          permissionHolding(context, const [Perm.classroomRead]) ==
                  PermissionHolding.missing
              ? l10n.feeControlDashboardClassroomsWithheld
              : l10n.feeControlDashboardClassroomsMissing,
        ),
        EnrollmentLoadStatus.success => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in classes)
              FeeControlDashboardGroupRow(
                key: ValueKey(row.classroomId ?? '__non-repartis__'),
                label: row.name ?? l10n.feeControlDashboardUnassigned,
                breakdown: row.breakdown,
                dense: true,
                // Les non-répartis n'ont pas de classe à transmettre : ouvrir
                // le niveau entier à leur place montrerait d'autres élèves que
                // ceux de la ligne tapée.
                onOpenControl: row.isUnassigned || onOpenControl == null
                    ? null
                    : () => onOpenControl!(row),
              ),
          ],
        ),
        EnrollmentLoadStatus.initial => const SizedBox.shrink(),
      },
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      // Région vive : ces trois phrases sont la RÉPONSE à la tape qui vient
      // d'ouvrir le niveau. Muettes, elles laisseraient croire que le geste
      // n'a rien fait.
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
