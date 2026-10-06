import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes d'une rangée : Monter / Descendre (absents aux extrémités),
/// Modifier, Supprimer. En [compact], Modifier et Supprimer passent dans un
/// menu « ⋮ » pour libérer la largeur du titre ; les flèches restent, elles
/// sont la voie accessible et utilisable au doigt pour réordonner.
///
/// Boutons d'icône standard : 48 × 48 de zone tactile, une infobulle chacun.
class ChapitreRowActions extends StatelessWidget {
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final bool compact;

  const ChapitreRowActions({
    super.key,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onMoveUp != null)
          IconButton(
            tooltip: l10n.chapitreActionMoveUp,
            onPressed: onMoveUp,
            icon: const Icon(Icons.arrow_upward_rounded),
            color: AppColors.textSecondary,
          ),
        if (onMoveDown != null)
          IconButton(
            tooltip: l10n.chapitreActionMoveDown,
            onPressed: onMoveDown,
            icon: const Icon(Icons.arrow_downward_rounded),
            color: AppColors.textSecondary,
          ),
        if (compact)
          _MoreMenu(onEdit: onEdit, onDelete: onDelete)
        else ...[
          if (onEdit != null)
            IconButton(
              tooltip: l10n.chapitreActionEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.textSecondary,
            ),
          IconButton(
            tooltip: l10n.chapitreActionDelete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
          ),
        ],
      ],
    );
  }
}

enum _MoreAction { edit, delete }

class _MoreMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _MoreMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_MoreAction>(
      tooltip: l10n.chapitreActionMore,
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      onSelected: (action) => switch (action) {
        _MoreAction.edit => onEdit?.call(),
        _MoreAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: _MoreAction.edit,
            child: Text(l10n.chapitreActionEdit),
          ),
        PopupMenuItem(
          value: _MoreAction.delete,
          child: Text(
            l10n.chapitreActionDelete,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
