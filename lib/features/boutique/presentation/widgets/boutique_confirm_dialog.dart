import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
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
    // Le panier est mono-devise ici : `canCollect` l'a garanti (le mélange est
    // un blocage). La jointure reste, parce qu'un écran qui suppose une seule
    // entrée finit toujours par en recevoir deux.
    final total = cart.totals.entries.map(MoneyFormat.format).join(' · ');
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
              // Le montant EN PREMIER, et en grand : c'est le seul chiffre que
              // le guichet doit vérifier avant de prendre l'argent. Enfoui en
              // bas d'un tableau, il se confirmait sans se lire.
              _AmountBanner(
                label: l10n.boutiqueConfirmAmountReceived,
                amount: total,
                methodLabel: l10n.boutiqueConfirmMethodCash,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // La ligne RESTE, même anonyme, et le dit en toutes
                    // lettres : c'est le dernier écran avant d'engager
                    // l'argent, et la seule occasion de remarquer qu'on
                    // voulait nommer quelqu'un. Une ligne escamotée, ou pire
                    // une valeur vide, laisserait le doute intact. Le ticket,
                    // lui, escamote — il est lu APRÈS, par le client.
                    _Row(
                      icon: Icons.person_outline_rounded,
                      label: l10n.boutiqueConfirmPayer,
                      value: _payerNameOf(cart).isEmpty
                          ? l10n.boutiqueHistoryPayerUnknown
                          : _payerNameOf(cart),
                    ),
                    if (payer.phoneNumber.trim().isNotEmpty)
                      _Row(
                        icon: Icons.phone_outlined,
                        label: l10n.boutiqueConfirmPhone,
                        value: payer.phoneNumber,
                      ),
                    _Row(
                      icon: Icons.shopping_bag_outlined,
                      label: l10n.boutiqueConfirmArticles,
                      value: '${cart.articleCount}',
                    ),
                    // « Espèces », en dur : c'est le seul moyen, et proposer un
                    // choix laisserait croire qu'il y en a d'autres. Il figure
                    // aussi sur le bandeau, sous le montant.
                    _Row(
                      icon: Icons.payments_outlined,
                      label: l10n.boutiqueConfirmMethod,
                      value: l10n.boutiqueConfirmMethodCash,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Expanded(
                    child: Text(
                      _noticeOf(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
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
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.boutiqueConfirmCancel),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terreCuite,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Le montant EST dans le libellé : on confirme un chiffre.
                      label: Text(
                        l10n.boutiqueConfirmAction(total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

/// Le bandeau du montant — Bleu Profond texturé, comme le total du panier :
/// c'est le même chiffre, et le guichet doit le reconnaître d'un écran à
/// l'autre.
class _AmountBanner extends StatelessWidget {
  final String label;
  final String amount;
  final String methodLabel;

  const _AmountBanner({
    required this.label,
    required this.amount,
    required this.methodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.orDoux,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                // TEXTE, jamais un champ (I-2, I-5) : il n'y a rien à saisir,
                // pas de monnaie à rendre, pas d'échéance.
                Text(
                  amount,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDark,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 14,
                      color: AppColors.textOnDark.withValues(alpha: 0.72),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      methodLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: AppDimensions.spacingS),
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
