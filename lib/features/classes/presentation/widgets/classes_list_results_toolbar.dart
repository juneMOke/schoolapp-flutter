import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListResultsToolbar extends StatelessWidget {
  final String summary;
  final bool canExport;
  final VoidCallback onExportPressed;

  const ClassesListResultsToolbar({
    super.key,
    required this.summary,
    required this.canExport,
    required this.onExportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      // La barre est la première apparition de la terre cuite : c'est la
      // réponse de la machine. Elle est **toujours** présente, quel que soit
      // l'état — c'est elle qui nomme l'état — donc sa couleur ne bouge jamais.
      //
      // ⚠️ Le rayon change aussi : 18 (carte de section) → 14. Ce n'est pas un
      // détail esthétique laissé au hasard — `listeBarRadius` existe pour ce
      // rôle précis, « la surface qui nomme l'état de la recherche », et cette
      // barre en est une. Aucun test ne figeait cette géométrie.
      decoration: BoxDecoration(
        color: ListingTones.barreFond,
        borderRadius: BorderRadius.circular(AppDimensions.listeBarRadius),
        border: Border.all(color: ListingTones.barreBord),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final exportButton = _ExportButton(
            canExport: canExport,
            onPressed: onExportPressed,
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AppDimensions.spacingS),
                Row(children: [const Spacer(), exportButton]),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              exportButton,
            ],
          );
        },
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool canExport;
  final VoidCallback onPressed;

  const _ExportButton({required this.canExport, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: canExport ? 1 : 0.72,
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(9),
        child: EteeloButton.secondary(
          onPressed: canExport ? onPressed : null,
          // Le geste copie un CSV dans le presse-papiers : ni PDF, ni fichier
          // téléchargé. Le libellé ET le glyphe le disent, sans quoi le bouton
          // promet une pièce que personne ne recevra.
          icon: Icons.content_copy_rounded,
          label: l10n.classesListCopyCsv,
          tooltip: l10n.classesListCopyCsv,
        ),
      ),
    );
  }
}
