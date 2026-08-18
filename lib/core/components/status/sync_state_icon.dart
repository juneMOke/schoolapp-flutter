import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Picto d'état de **synchro** d'une ligne de listing — axe technique, distinct
/// du statut métier porté par la pastille voisine.
///
/// Trois états seulement, en pictogramme seul (pas de libellé : la ligne porte
/// déjà une pastille de statut métier, et parfois un badge « Brouillon ») :
///
/// | État           | Picto    | Couleur | Sens                                     |
/// |----------------|----------|---------|------------------------------------------|
/// | `SYNCED`       | coche    | vert    | acquitté par le serveur                  |
/// | `PENDING_SYNC` | sablier  | orange  | dans la file, repartira toute seule      |
/// | `SYNC_ERROR`   | triangle | rouge   | refusée, **ne repartira pas d'elle-même** |
///
/// Rien n'est rendu pour :
///  - `null` — un résumé venu du serveur ou un candidat du vivier (RE/PRE) n'a
///    pas d'axe synchro : il n'existe pas encore de dossier local ;
///  - `DRAFT` — une saisie en cours n'est pas dans la file d'envoi ; le badge
///    « Brouillon » de la ligne porte déjà cette information ;
///  - `PROVISIONAL` — état propre à la Facturation (créance locale qui attend
///    d'être *remplacée* par celle du serveur, jamais poussée) : ce n'est pas
///    une écriture en attente d'envoi, l'assimiler au sablier mentirait.
///
/// Purement informatif : aucun tap propre (le tap de la ligne garde son
/// comportement). Le libellé n'apparaît qu'en appui long (`Tooltip`), qui
/// fournit du même coup la sémantique lue par les lecteurs d'écran — un picto
/// nu, sans texte, leur serait sinon muet.
class SyncStateIcon extends StatelessWidget {
  final SyncState? state;
  final double size;

  const SyncStateIcon({
    super.key,
    required this.state,
    this.size = AppDimensions.syncStateIconSize,
  });

  /// Vrai si [state] donne lieu à un picto. Laisse l'appelant décider de son
  /// espacement sans dupliquer la règle : un `SizedBox` posé devant un picto
  /// absent laisserait un trou dans la ligne.
  static bool isVisible(SyncState? state) => _specFor(state) != null;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(state);
    if (spec == null) return const SizedBox.shrink();

    return Tooltip(
      message: spec.label(AppLocalizations.of(context)!),
      triggerMode: TooltipTriggerMode.longPress,
      child: Icon(spec.icon, color: spec.color, size: size),
    );
  }

  static _SyncIconSpec? _specFor(SyncState? state) => switch (state) {
    SyncState.synced => _SyncIconSpec(
      icon: Icons.check_circle,
      color: AppColors.success,
      label: (l10n) => l10n.syncRowSynced,
    ),
    SyncState.pendingSync => _SyncIconSpec(
      icon: Icons.hourglass_top,
      color: AppColors.warning,
      label: (l10n) => l10n.syncRowPending,
    ),
    SyncState.syncError => _SyncIconSpec(
      icon: Icons.warning_rounded,
      color: AppColors.error,
      label: (l10n) => l10n.syncRowError,
    ),
    SyncState.draft || SyncState.provisional || null => null,
  };
}

class _SyncIconSpec {
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations l10n) label;

  const _SyncIconSpec({
    required this.icon,
    required this.color,
    required this.label,
  });
}
