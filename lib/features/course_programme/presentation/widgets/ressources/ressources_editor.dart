import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_form_model.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/ressource_tile.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_sections.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/ressources/ressource_draft_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Les ressources du chapitre dans la modale (spec §5) : la liste (gardées et
/// jointes), un ✕ pour retirer, et le brouillon en ligne. Les fichiers
/// partent à l'enregistrement du chapitre.
class RessourcesEditor extends StatefulWidget {
  final ChapitreFormModel model;
  final String Function() newId;
  final VoidCallback onChanged;

  const RessourcesEditor({
    super.key,
    required this.model,
    required this.newId,
    required this.onChanged,
  });

  @override
  State<RessourcesEditor> createState() => _RessourcesEditorState();
}

class _RessourcesEditorState extends State<RessourcesEditor> {
  bool _drafting = false;

  void _setDrafting(bool value) => setState(() => _drafting = value);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = widget.model;
    final tiles = [
      for (final r in model.keptRessources)
        RessourceTile(
          key: ValueKey<String>(r.id),
          type: r.type,
          nom: r.nom,
          detail: r.detail,
          trailing: _RemoveButton(
            onPressed: () {
              model.removeKeptRessource(r);
              widget.onChanged();
            },
          ),
        ),
      for (final d in model.addedRessources)
        RessourceTile(
          key: ValueKey<String>(d.id),
          type: d.type,
          nom: d.nom,
          detail: d.url ?? d.reference ?? d.fileName,
          trailing: _RemoveButton(
            onPressed: () {
              model.addedRessources.remove(d);
              widget.onChanged();
            },
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapitreFormLabel(
          label: l10n.chapitreFormRessourcesLabel,
          optional: true,
          count: model.ressourcesCount,
          action: _drafting
              ? null
              : ChapitreFormAddButton(onPressed: () => _setDrafting(true)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (tiles.isEmpty && !_drafting)
          _EmptyButton(onTap: () => _setDrafting(true)),
        if (tiles.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  tiles[i],
                ],
              ],
            ),
          ),
        if (_drafting) ...[
          if (tiles.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          RessourceDraftPanel(
            newId: widget.newId,
            onCancel: () => _setDrafting(false),
            onAdd: (draft) {
              model.addedRessources.add(draft);
              _setDrafting(false);
              widget.onChanged();
            },
          ),
        ],
      ],
    );
  }
}

class _EmptyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(
          color: AppColors.borderStrong,
          width: ProgrammeLayout.emptyBorderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.attach_file_rounded,
                size: ProgrammeLayout.iconSmall,
                color: AppColors.bleuArdoise,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.ressourceEditorEmpty,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context)!.ressourceRemove,
    icon: const Icon(Icons.close_rounded),
    color: AppColors.error,
    onPressed: onPressed,
  );
}
