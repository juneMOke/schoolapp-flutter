import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Le marquage est un brouillon, pas une décision.**
///
/// L'encart le dit dans cet ordre, et l'ordre compte : c'est un brouillon ·
/// rien n'est notifié aux familles · l'étape suivante est de **mesurer**
/// l'effet au tableau de bord, pas d'appliquer.
///
/// Il n'y a **aucun bouton « Appliquer les renvois »**, ni ici ni là-bas. Un
/// renvoi effectif passe par le dossier d'inscription, élève par élève, avec sa
/// propre traçabilité.
class FeeControlMarkedCard extends StatelessWidget {
  const FeeControlMarkedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FeeControlSelectionCubit, FeeControlSelectionState>(
      buildWhen: (prev, curr) => prev.marked.length != curr.marked.length,
      builder: (context, selection) {
        final count = selection.marked.length;

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: count == 0
              ? const SizedBox.shrink(key: ValueKey('fee-control-marked-off'))
              : Padding(
                  key: const ValueKey('fee-control-marked'),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingM,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.feeStatusDueSoft,
                      border: Border.all(color: AppColors.feeStatusDueBorder),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_off_outlined,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Expanded(
                              child: Text(
                                l10n.feeControlMarkedTitle(count),
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          l10n.feeControlMarkedNote,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: EteeloButton.ghost(
                            label: l10n.feeControlMarkedClear,
                            icon: Icons.delete_outline,
                            fullWidth: false,
                            size: EteeloButtonSize.compact,
                            onPressed: () {
                              context
                                  .read<FeeControlSelectionCubit>()
                                  .clearMarks();
                              AppSnackBar.showInfo(
                                context,
                                l10n.feeControlMarkedCleared,
                              );
                            },
                          ),
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
