import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre d'encaissement ancrée au bas de la page : total en direct + CTA.
///
/// Elle vit dans le `bottomNavigationBar` de la page et non dans le
/// défilement : le montant qu'on s'apprête à encaisser et le geste qui le
/// valide doivent rester sous les yeux, quelle que soit la longueur de la liste
/// de frais — c'est ce que le pied figé de la popin garantissait.
class FacturationCollectActionBar extends StatelessWidget {
  /// Total à encaisser, déjà rendu par devise (« 425,00 $ · 90 000 FC »).
  /// Vide tant qu'aucun frais n'est retenu.
  ///
  /// C'est **ce que le tiroir va recevoir** dès qu'une devise de règlement est
  /// choisie : le caissier compte des billets, et c'est ce chiffre-là qu'il
  /// annonce au parent.
  final String totalLabel;

  /// Ce que ce versement **impute**, en devise de créance, quand ce n'est pas la
  /// même chose. `null` dans le cas courant, où les deux se confondent et où
  /// répéter le montant n'apprendrait rien.
  ///
  /// En second, et en petit : c'est la hiérarchie du métier. Le comptable lit
  /// l'imputation, le guichet compte ce qu'on lui tend.
  final String? settledLabel;

  /// `null` éteint le CTA (payeur incomplet, rien à encaisser, confirmation
  /// déjà ouverte).
  final VoidCallback? onCollect;

  const FacturationCollectActionBar({
    super.key,
    required this.totalLabel,
    required this.onCollect,
    this.settledLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Rien de retenu : la barre reste en place — c'est le repère du guichet —
    // mais elle ne promet pas un montant qu'elle n'a pas. Le CTA reprend alors
    // le libellé neutre de la fiche, plutôt qu'un « Encaisser » suivi d'un
    // blanc.
    final hasTotal = totalLabel.trim().isNotEmpty;
    final total = _TotalBand(
      // Le libellé change avec ce qu'il coiffe : « Total à encaisser » tant que
      // perçu et imputé se confondent, « À percevoir » dès qu'ils divergent —
      // auquel cas la ligne du dessous dit ce qui est éteint.
      label: settledLabel == null
          ? l10n.facturationCreatePaymentTotalToCollect
          : l10n.facturationCreatePaymentToPerceive,
      amount: hasTotal ? totalLabel : l10n.facturationDetailUnknownValue,
      settled: hasTotal ? settledLabel : null,
    );

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          // `heightFactor` : posé dans le `bottomNavigationBar`, un `Align`
          // sans lui remplirait la contrainte lâche du Scaffold — toute la
          // hauteur d'écran — et masquerait le corps de la page.
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.facturationContentMaxWidth,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Gel READ_ONLY (ADR-010) : le tick de fraîcheur (5 min) peut
                  // basculer le mode PENDANT la saisie — l'argent ne part pas
                  // d'une session gelée.
                  final button = SessionWriteGate(
                    child: EteeloButton.primary(
                      label: hasTotal
                          ? l10n.facturationCreatePaymentCollectAmountAction(
                              totalLabel,
                            )
                          : l10n.facturationDetailCollectPaymentAction,
                      icon: Icons.account_balance_wallet_outlined,
                      size: EteeloButtonSize.regular,
                      fullWidth:
                          constraints.maxWidth <
                          AppBreakpoints.financeCollectBarRowMin,
                      onPressed: onCollect,
                    ),
                  );

                  if (constraints.maxWidth <
                      AppBreakpoints.financeCollectBarRowMin) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        total,
                        const SizedBox(height: AppDimensions.spacingM),
                        button,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: total),
                      const SizedBox(width: AppDimensions.spacingM),
                      button,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau sombre totalisant en direct : billet or-doux + total.
class _TotalBand extends StatelessWidget {
  final String label;
  final String amount;

  /// L'imputé, rendu sous le perçu. `null` quand les deux se confondent.
  final String? settled;

  const _TotalBand({required this.label, required this.amount, this.settled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bleuProfond,
        borderRadius: AppRadius.brMd,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingM,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: AppColors.orDoux,
            size: AppDimensions.detailHeaderIconSize,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: AppColors.textOnDark),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amount,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (settled != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.facturationCreatePaymentImputes(settled!),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
