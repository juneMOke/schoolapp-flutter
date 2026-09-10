import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **La barre n'existe que quand une sélection existe.**
///
/// Elle porte les sorties de l'écran — un document, un marquage — et une
/// échappatoire. Tant que rien n'est coché, elle n'occupe aucune place : une
/// barre d'actions vide apprend à ne plus la regarder.
///
/// ⚠️ La spec en compte une troisième, « Notifier les parents ». Elle n'est pas
/// rendue : le numéro d'un payeur n'a pas de source locale pour un élève déjà
/// inscrit (`guardian_phone` ne vit que sur les tables de candidats), et il n'y
/// a pas de canal d'envoi. Un bouton qui n'aboutit pas serait pire que son
/// absence — la relance en lot demande une route serveur, elle est demandée à
/// part.
class FeeControlActionBar extends StatelessWidget {
  /// Édite la liste d'appel des élèves cochés.
  final VoidCallback? onCallList;

  /// Ajoute les cochés à la liste de travail des renvois.
  final VoidCallback onMark;

  const FeeControlActionBar({
    super.key,
    required this.onCallList,
    required this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FeeControlSelectionCubit, FeeControlSelectionState>(
      buildWhen: (prev, curr) => prev.selected.length != curr.selected.length,
      builder: (context, selection) {
        final count = selection.selected.length;

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: count == 0
              ? const SizedBox.shrink(key: ValueKey('fee-control-actions-off'))
              : Padding(
                  key: const ValueKey('fee-control-actions'),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.billingHelpSurface,
                      border: Border.all(color: AppColors.billingHelpBorder),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                    ),
                    child: Wrap(
                      spacing: AppDimensions.spacingS,
                      runSpacing: AppDimensions.spacingS,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Annoncé : le nombre de cochés change sans que rien ne
                        // bouge à l'écran pour qui ne voit pas les cases.
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l10n.feeControlSelectionCount(count),
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.bleuArdoise,
                            ),
                          ),
                        ),
                        EteeloButton.ghost(
                          label: l10n.feeControlCallListAction,
                          icon: Icons.print_outlined,
                          onPressed: onCallList,
                          fullWidth: false,
                          size: EteeloButtonSize.compact,
                        ),
                        EteeloButton.primary(
                          label: l10n.feeControlMarkAction,
                          icon: Icons.person_off_outlined,
                          onPressed: onMark,
                          fullWidth: false,
                          size: EteeloButtonSize.compact,
                        ),
                        // Sortie sans conséquence, toujours en dernier.
                        EteeloButton.ghost(
                          label: l10n.feeControlDeselectAction,
                          onPressed: () => context
                              .read<FeeControlSelectionCubit>()
                              .clearSelection(),
                          fullWidth: false,
                          size: EteeloButtonSize.compact,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
