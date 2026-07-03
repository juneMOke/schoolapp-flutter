import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_search_mode.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État vide différencié classe / élève (spec §11), via l'anatomie partagée
/// [EteeloEmptyResult]. En mode élève, une action secondaire « Ajuster la
/// recherche » ramène l'attention sur la carte de recherche.
class ResultatsResultsEmptyState extends StatelessWidget {
  final ResultatsSearchMode mode;
  final VoidCallback? onAdjust;

  const ResultatsResultsEmptyState({
    super.key,
    required this.mode,
    this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (mode == ResultatsSearchMode.classe) {
      return EteeloEmptyResult(
        medallionIcon: Icons.groups_outlined,
        label: l10n.resultatsEmptyClasseTitle,
        description: l10n.resultatsEmptyClasse,
        fullWidthCard: true,
      );
    }

    return EteeloEmptyResult(
      medallionIcon: Icons.person_search_outlined,
      label: l10n.resultatsEmptyEleveTitle,
      description: l10n.resultatsEmptyEleveDescription,
      secondaryAction: onAdjust == null
          ? null
          : EteeloButton.secondary(
              label: l10n.resultatsEmptyAdjustAction,
              icon: Icons.tune_rounded,
              onPressed: onAdjust!,
              fullWidth: false,
            ),
      fullWidthCard: true,
    );
  }
}
