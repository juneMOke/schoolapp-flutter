import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résultats de la popin « Choisir un payeur » : une identité par ligne,
/// sélection immédiate au tap.
///
/// ⚠️ Liste **inerte** (`shrinkWrap` + `NeverScrollableScrollPhysics`) : c'est
/// `EteeloDialogBody` qui fournit le défilement. Maîtresse du sien, elle
/// gagnerait l'arène des gestes sans avoir rien à faire défiler, et le doigt de
/// l'utilisateur ne déplacerait plus rien.
class FacturationPayerSearchResultsList extends StatelessWidget {
  final List<LocalPayerIdentity> results;
  final ValueChanged<LocalPayerIdentity> onSelected;

  const FacturationPayerSearchResultsList({
    super.key,
    required this.results,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimensions.spacingS),
      itemBuilder: (context, index) => _PayerRow(
        payer: results[index],
        onSelected: () => onSelected(results[index]),
      ),
    );
  }
}

/// Une identité proposable : nom, numéro connu, et ce qui la justifie.
class _PayerRow extends StatelessWidget {
  final LocalPayerIdentity payer;
  final VoidCallback onSelected;

  const _PayerRow({required this.payer, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGuardian = payer.origin == PayerOrigin.guardian;

    return Semantics(
      button: true,
      label: l10n.facturationPayerSearchSelectSemantics(payer.fullName),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  isGuardian
                      ? Icons.family_restroom_outlined
                      : Icons.history_rounded,
                  size: AppDimensions.financeRowIconSize,
                  color: AppColors.bleuArdoise,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payer.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Un numéro manquant se DIT, il ne se tait pas : la
                        // ligne vide laisserait croire à un défaut d'affichage,
                        // alors que le guichetier doit savoir qu'il aura à le
                        // saisir après avoir choisi ce payeur.
                        payer.phoneNumber ??
                            l10n.facturationPayerSearchUnknownPhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: payer.phoneNumber == null
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _provenance(context, l10n),
                        maxLines: 2,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ce qui justifie la proposition. « 3 versements, dernier le 12/08/2026 »
  /// est un fait ; « tuteur de l'élève » n'est qu'une piste — le tuteur n'est
  /// pas nécessairement celui qui vient à la caisse, et confondre les deux
  /// ferait signer un reçu au nom de quelqu'un qui n'a rien payé.
  String _provenance(BuildContext context, AppLocalizations l10n) {
    if (payer.origin == PayerOrigin.guardian) {
      return l10n.facturationPayerSearchOriginGuardian;
    }
    final count = l10n.facturationPayerSearchPaymentCount(payer.paymentCount);
    final paidAt = DateTime.tryParse(payer.lastPaidAt ?? '');
    if (paidAt == null) return count;
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(paidAt.toLocal());
    return '$count · ${l10n.facturationPayerSearchLastPaidAt(date)}';
  }
}
