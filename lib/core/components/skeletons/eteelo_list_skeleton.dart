import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Squelette de chargement partage pour les listes/rosters : une carte qui
/// conserve l'anatomie des lignes reelles (avatar + identite sur deux lignes +
/// pilules d'etat) afin que l'utilisateur percoive la structure a venir.
///
/// - `aria-busy` : la carte est annoncee comme une region vivante portant un
///   libelle de chargement (`semanticsLabel`) ; les blocs visuels sont
///   purement decoratifs (exclus de la semantique).
/// - reduced-motion : delegue a [EteeloSkeletonBox] (aucun shimmer si l'option
///   d'accessibilite est active).
///
/// Brique commune des etats de chargement (cf. regle « Etats partages » dans
/// CLAUDE.md / AGENTS.md).
class EteeloListSkeleton extends StatelessWidget {
  /// Nombre de lignes fantomes (defaut : 8).
  final int rowCount;

  /// Nombre de pilules d'etat en fin de ligne (defaut : 2).
  final int pillCount;

  /// Affiche un medaillon avatar en debut de ligne (defaut : true).
  final bool showAvatar;

  /// Libelle d'accessibilite annonce pendant le chargement. Fourni par la
  /// feature via `AppLocalizations` (aucune chaine codee en dur cote core).
  final String? semanticsLabel;

  const EteeloListSkeleton({
    super.key,
    this.rowCount = 8,
    this.pillCount = 2,
    this.showAvatar = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < rowCount; index++) {
      rows.add(
        _SkeletonRosterRow(showAvatar: showAvatar, pillCount: pillCount),
      );
      if (index != rowCount - 1) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
        );
      }
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ),
    );
  }
}

class _SkeletonRosterRow extends StatelessWidget {
  final bool showAvatar;
  final int pillCount;

  const _SkeletonRosterRow({required this.showAvatar, required this.pillCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: SizedBox(
        height: AppDimensions.minTouchTarget,
        child: Row(
          children: [
            if (showAvatar) ...[
              EteeloSkeletonBox(
                width: 34,
                height: 34,
                borderRadius: BorderRadius.circular(17),
              ),
              const SizedBox(width: AppDimensions.spacingS),
            ],
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EteeloSkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: AppDimensions.spacingS),
                  EteeloSkeletonBox(width: 120, height: 10),
                ],
              ),
            ),
            for (var i = 0; i < pillCount; i++) ...[
              const SizedBox(width: AppDimensions.spacingS),
              const EteeloSkeletonBox(
                width: 56,
                height: 22,
                borderRadius: AppRadius.brPill,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
