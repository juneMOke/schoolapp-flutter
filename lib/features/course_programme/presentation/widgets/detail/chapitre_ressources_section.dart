import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_sync_pill.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/ressource_tile.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les ressources, en lecture : un lien et un document s'ouvrent ; une
/// référence de manuel se lit.
class ChapitreRessourcesSection extends StatelessWidget {
  final List<ChapitreRessource> ressources;
  final ValueChanged<ChapitreRessource> onOpen;

  const ChapitreRessourcesSection({
    super.key,
    required this.ressources,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChapitreSection(
      icon: Icons.attach_file_rounded,
      title: l10n.chapitreSectionRessources,
      count: ressources.length,
      child: ressources.isEmpty
          ? ChapitreSectionEmpty(l10n.chapitreRessourcesEmpty)
          : Column(
              children: [
                for (var i = 0; i < ressources.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _tile(l10n, ressources[i]),
                ],
              ],
            ),
    );
  }

  Widget _tile(AppLocalizations l10n, ChapitreRessource ressource) {
    final openable = ressource.type != RessourceType.manuel;
    return RessourceTile(
      key: ValueKey<String>(ressource.id),
      type: ressource.type,
      nom: ressource.nom,
      detail: ressource.detail,
      badge: ressource.syncState == ProgrammeSyncState.synced
          ? null
          : ProgrammeSyncPill(state: ressource.syncState),
      trailing: openable
          ? IconButton(
              tooltip: l10n.chapitreRessourceOpen(ressource.nom),
              onPressed: () => onOpen(ressource),
              icon: const Icon(Icons.open_in_new_rounded),
              color: AppColors.bleuArdoise,
            )
          : null,
    );
  }
}
