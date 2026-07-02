import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de la zone de saisie (spec §13) : barre de mode grise + 7 lignes
/// d'élève. Conserve la mise en page (jamais un spinner centré).
class SaisieSkeleton extends StatelessWidget {
  const SaisieSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.evalSaisieLoadingA11y,
      liveRegion: true,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EteeloSkeletonBox(
                width: 220,
                height: 40,
                borderRadius: AppRadius.brMd,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          EteeloListSkeleton(rowCount: 7, pillCount: 1),
        ],
      ),
    );
  }
}
