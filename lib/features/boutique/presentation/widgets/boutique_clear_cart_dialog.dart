import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmation avant de vider le panier.
///
/// **Rien n'est encaissé à ce stade** — et la phrase le dit, plutôt que de
/// laisser croire qu'on annule une vente. Ce qui se perd est du travail de
/// composition : des lignes, des bénéficiaires désignés un par un, une identité
/// de payeur saisie au clavier. C'est assez pour mériter une question.
///
/// Elle NOMME ce qui disparaît. « Êtes-vous sûr ? » ne dit rien de ce qu'on
/// s'apprête à perdre, et se répond au hasard.
class BoutiqueClearCartDialog extends StatelessWidget {
  final BoutiqueCart cart;

  const BoutiqueClearCartDialog({super.key, required this.cart});

  /// Rend `true` si le guichet confirme.
  static Future<bool> show(
    BuildContext context, {
    required BoutiqueCart cart,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => BoutiqueClearCartDialog(cart: cart),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final payer = _payerNameOf(cart);

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: EteeloDialogBody(
          header: EteeloDialogDarkHeader(
            eyebrow: l10n.boutiqueClearEyebrow,
            title: l10n.boutiqueClearTitle,
            onClose: () => Navigator.of(context).pop(false),
          ),
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.delete_sweep_outlined,
                      size: 20,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.boutiqueClearLinesSummary(cart.articleCount),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.bleuProfond,
                            ),
                          ),
                          // L'identité saisie ne se mentionne que si elle
                          // existe : une ligne « Payeur : » vide ferait
                          // chercher ce qu'on a oublié de remplir.
                          if (payer.isNotEmpty)
                            Text(
                              l10n.boutiqueClearPayerSummary(payer),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.boutiqueClearMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          footer: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        // ⚠️ Sans `minimumSize`, un bouton inline hérite du
                        // thème plein-largeur et lève en contrainte infinie.
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(l10n.boutiqueClearCancel),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(l10n.boutiqueClearConfirm),
                      style: FilledButton.styleFrom(
                        // Rouge, et non terre-cuite : le terre-cuite est la
                        // couleur de ce qui va être payé, pas de ce qui va être
                        // effacé.
                        backgroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _payerNameOf(BoutiqueCart cart) => [
    cart.payer.lastName.trim(),
    cart.payer.middleName.trim(),
    cart.payer.firstName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
}
