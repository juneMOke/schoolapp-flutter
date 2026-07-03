import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Squelette de chargement du corps de la vue focus (l'en-tête reste rendu à
/// partir de l'identité passée en argument). Respecte reduced-motion.
class ResultatFocusSkeleton extends StatelessWidget {
  const ResultatFocusSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloSkeletonBox(
          width: double.infinity,
          height: 120,
          borderRadius: AppRadius.brLg,
        ),
        SizedBox(height: AppSpacing.md),
        EteeloSkeletonBox(
          width: double.infinity,
          height: 92,
          borderRadius: AppRadius.brLg,
        ),
        SizedBox(height: AppSpacing.md),
        EteeloSkeletonBox(
          width: double.infinity,
          height: 240,
          borderRadius: AppRadius.brLg,
        ),
      ],
    );
  }
}
