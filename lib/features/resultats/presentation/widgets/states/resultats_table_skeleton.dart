import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de chargement de la table de résultats (spec §11) : réutilise
/// [EteeloListSkeleton] (respecte reduced-motion) et préserve la mise en page.
/// [columnCount] = nombre de colonnes % (sous-périodes + moyenne) → nb de pilules.
class ResultatsTableSkeleton extends StatelessWidget {
  final int columnCount;

  const ResultatsTableSkeleton({super.key, this.columnCount = 3});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloListSkeleton(
      rowCount: 7,
      pillCount: columnCount.clamp(1, 4),
      semanticsLabel: l10n.resultatsLoadingSemantics,
    );
  }
}
