import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmation d'encaissement — un récapitulatif **non modifiable**.
///
/// C'est le point où deux invariants se voient à l'œil nu : un montant qu'on ne
/// peut pas toucher (I-2, aucun champ de prix nulle part) et un seul moyen de
/// paiement (I-5, comptant intégral — ni partiel, ni créance).
///
/// Le montant figure **dans le libellé du bouton** : on confirme un chiffre, pas
/// une intention.
class BoutiqueConfirmDialog extends StatelessWidget {
  final BoutiqueCart cart;

  /// Vrai si ce payeur n'a pas été reconnu au répertoire.
  final bool payerIsNew;

  /// Vrai si l'appareil est hors ligne — la phrase gagne alors sa mention de
  /// ticket provisoire.
  final bool isOffline;

  const BoutiqueConfirmDialog({
    super.key,
    required this.cart,
    required this.payerIsNew,
    required this.isOffline,
  });

  /// Ouvre la confirmation. Rend `true` si le guichet confirme.
  static Future<bool> show(
    BuildContext context, {
    required BoutiqueCart cart,
    required bool payerIsNew,
    required bool isOffline,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => BoutiqueConfirmDialog(
          cart: cart,
          payerIsNew: payerIsNew,
          isOffline: isOffline,
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = cart.currency ?? 'USD';
    final total = BoutiqueMoneyFormat.exact(cart.totalInCents, currency);
    final payer = cart.payer;

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
            eyebrow: l10n.boutiqueConfirmEyebrow,
            title: l10n.boutiqueConfirmTitle,
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
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _Row(
                      label: l10n.boutiqueConfirmPayer,
                      value: _payerNameOf(cart),
                    ),
                    if (payer.phoneNumber.trim().isNotEmpty)
                      _Row(
                        label: l10n.boutiqueConfirmPhone,
                        value: payer.phoneNumber,
                      ),
                    _Row(
                      label: l10n.boutiqueConfirmArticles,
                      value: '${cart.articleCount}',
                    ),
                    // « Espèces », en dur : c'est le seul moyen, et proposer un
                    // choix laisserait croire qu'il y en a d'autres.
                    _Row(
                      label: l10n.boutiqueConfirmMethod,
                      value: l10n.boutiqueConfirmMethodCash,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.boutiqueConfirmAmountReceived,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        // TEXTE, jamais un champ (I-2, I-5) : il n'y a rien à
                        // saisir, pas de monnaie à rendre, pas d'échéance.
                        Text(
                          total,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                _noticeOf(l10n),
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
                      child: Text(l10n.boutiqueConfirmCancel),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terreCuite,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      // Le montant EST dans le libellé : on confirme un chiffre.
                      child: Text(l10n.boutiqueConfirmAction(total)),
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

  /// La phrase du comptant intégral, **toujours présente** — c'est elle qui dit
  /// au guichet ce qu'il ne pourra pas faire ensuite. Le reste s'y ajoute.
  String _noticeOf(AppLocalizations l10n) => [
    if (payerIsNew) l10n.boutiqueConfirmNewPayerPrefix,
    l10n.boutiqueConfirmNotice,
    if (isOffline) l10n.boutiqueConfirmOfflineSuffix,
  ].join(' ');

  static String _payerNameOf(BoutiqueCart cart) => [
    cart.payer.lastName.trim(),
    cart.payer.middleName.trim(),
    cart.payer.firstName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
