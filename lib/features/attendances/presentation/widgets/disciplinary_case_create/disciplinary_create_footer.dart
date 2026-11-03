import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied de la modale « Nouveau cas » : Annuler, et Créer le cas — gardé
/// par la permission et le gel de session.
class DisciplinaryCreateFooter extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;

  const DisciplinaryCreateFooter({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // reduced-motion : les transitions du formulaire deviennent instantanées.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final switchDuration = reduceMotion ? Duration.zero : AppMotion.fast;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      // Wrap (pas Row) : sur téléphone étroit, si les deux boutons ne
      // tiennent pas sur une ligne, le bouton principal passe dessous au
      // lieu de déborder.
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: [
          Semantics(
            label: l10n.cancel,
            button: true,
            child: TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: AppTextStyles.action.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          // Le dialog peut rester ouvert quand la permission redescend en
          // cours de session (refresh) : garder la porte ne suffit pas, il
          // faut garder le geste. Même raison que pour le gel READ_ONLY,
          // dont le raisonnement est ici étendu aux droits.
          PermissionGate.access(
            kDisciplineInstructAccess,
            child: SessionWriteGate(
              child: Semantics(
                label: l10n.disciplinaryCaseCreateDialogSubmitAction,
                button: true,
                enabled: !isLoading,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.disciplinaryDetailAccent,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                    ),
                  ),
                  onPressed: isLoading ? null : onSubmit,
                  icon: AnimatedSwitcher(
                    duration: switchDuration,
                    switchInCurve: AppMotion.outCurve,
                    switchOutCurve: AppMotion.inCurve,
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('loading-icon'),
                            width: AppDimensions
                                .disciplinaryCreateSubmitSpinnerSize,
                            height: AppDimensions
                                .disciplinaryCreateSubmitSpinnerSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.surface,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.add_task_outlined,
                            key: ValueKey('submit-icon'),
                          ),
                  ),
                  label: AnimatedSwitcher(
                    duration: switchDuration,
                    switchInCurve: AppMotion.outCurve,
                    switchOutCurve: AppMotion.inCurve,
                    child: Text(
                      isLoading
                          ? l10n.disciplinaryCaseCreateDialogCreatingMessage
                          : l10n.disciplinaryCaseCreateDialogSubmitAction,
                      key: ValueKey(isLoading),
                      style: AppTextStyles.action,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
