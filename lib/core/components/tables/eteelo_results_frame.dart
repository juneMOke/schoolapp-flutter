import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Le cadre des résultats d'une collection en cartes : le bord de la table
/// teintée ([DataTableTone.frame]), posé sur sa zébrure. Les cartes blanches
/// s'y détachent du fond de page, et passer des lignes aux cartes ne change
/// que le contenu, jamais le contenant.
class EteeloResultsFrame extends StatelessWidget {
  final DataTableTone tone;
  final Widget child;

  const EteeloResultsFrame({
    super.key,
    required this.tone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: tone.frame.copyWith(color: tone.zebra),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}
