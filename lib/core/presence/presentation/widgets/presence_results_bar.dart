import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_results_bar.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_bulk_mark_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre de résultats d'un registre : combien la liste montre, combien
/// restent à pointer, et le pointage en masse de ces derniers.
class PresenceResultsBar extends StatelessWidget {
  /// « 24 agents », « 31 élèves » — les lignes affichées.
  final String countLabel;

  /// Les « à pointer » affichés.
  final int unmarked;

  /// `null` : le jour ne s'écrit pas (validé, mois clos, droit manquant).
  final ValueChanged<PresenceStatus>? onMarkUnmarked;

  const PresenceResultsBar({
    super.key,
    required this.countLabel,
    required this.unmarked,
    this.onMarkUnmarked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onMark = onMarkUnmarked;
    return EteeloResultsBar(
      label: [
        countLabel,
        if (unmarked > 0) l10n.presenceMarkBadgeToMark(unmarked),
      ].join(' · '),
      trailing: unmarked > 0 && onMark != null
          ? PresenceBulkMarkButton(count: unmarked, onMark: onMark)
          : null,
    );
  }
}
