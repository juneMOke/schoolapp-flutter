import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bloc payeur du panier.
///
/// **Le téléphone est en premier parce qu'il est la clé** : il retrouve un
/// payeur déjà connu et évite de retaper son identité. Nom, post-nom et prénom
/// suivent, dans l'ordre RDC.
///
/// Les champs restent **éditables après « Utiliser »** : corriger une
/// orthographe ne casse pas le rattachement, puisque la clé reste le numéro.
///
/// **Tous facultatifs** (V114 serveur) : aucune étoile, et une mention qui le
/// dit. Une vente au comptant remet sa contrepartie sur-le-champ — il n'y a ni
/// dette à rattacher ni personne à recontacter — et exiger un nom pour
/// encaisser un cahier faisait taper « X » au guichet, un champ rempli qui ne
/// désigne personne. Le nom reste précieux quand il est là, et il le sera dans
/// l'immense majorité des cas : un uniforme se vend à un parent qu'on connaît.
/// Il cesse simplement de conditionner l'encaissement.
class BoutiquePayerSection extends StatelessWidget {
  final CartPayer payer;

  /// Le payeur reconnu au répertoire, `null` si le numéro est inconnu ou trop
  /// court pour qu'on le juge.
  final BoutiquePayer? match;

  final TextEditingController phoneController;
  final TextEditingController lastNameController;
  final TextEditingController middleNameController;
  final TextEditingController firstNameController;

  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onLastNameChanged;
  final ValueChanged<String> onMiddleNameChanged;
  final ValueChanged<String> onFirstNameChanged;
  final void Function(BoutiquePayer payer) onUseMatch;

  const BoutiquePayerSection({
    super.key,
    required this.payer,
    required this.match,
    required this.phoneController,
    required this.lastNameController,
    required this.middleNameController,
    required this.firstNameController,
    required this.onPhoneChanged,
    required this.onLastNameChanged,
    required this.onMiddleNameChanged,
    required this.onFirstNameChanged,
    required this.onUseMatch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.boutiquePayerSection,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Le badge ne survit pas à la modification du numéro : il affirme un
            // fait établi sur une clé, et cette clé vient de changer. C'est
            // `CartPayer.copyWith` qui le fait tomber, pas cet écran.
            if (payer.knownFromDirectory)
              _KnownBadge(label: l10n.boutiquePayerKnownBadge),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        EteeloPhoneInput(
          controller: phoneController,
          label: l10n.boutiquePayerPhoneLabel,
          onChanged: onPhoneChanged,
        ),
        if (match != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _MatchCard(match: match!, onUse: () => onUseMatch(match!)),
        ] else if (payer.phoneStatus == PayerPhoneStatus.usable) ...[
          const SizedBox(height: AppDimensions.spacingS),
          // Ce n'est PAS une erreur — ni ambre, ni rouge. Un nouveau payeur est
          // le cas nominal d'une boutique.
          _NeutralNote(text: l10n.boutiquePayerUnknownNotice),
        ],
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: EteeloTextInput(
                controller: lastNameController,
                label: l10n.boutiquePayerLastNameLabel,
                onChanged: onLastNameChanged,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: EteeloTextInput(
                controller: middleNameController,
                label: l10n.boutiquePayerMiddleNameLabel,
                onChanged: onMiddleNameChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        EteeloTextInput(
          controller: firstNameController,
          label: l10n.boutiquePayerFirstNameLabel,
          onChanged: onFirstNameChanged,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // Dire que c'est facultatif VAUT l'espace : sans mention, un guichetier
        // qui a toujours dû remplir ces champs continuera de les remplir, et
        // l'assouplissement n'aura rien changé à la file d'attente.
        Text(
          l10n.boutiquePayerOptionalNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _KnownBadge extends StatelessWidget {
  final String label;

  const _KnownBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.vertSavane.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.vertSavane,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// La carte du payeur reconnu — identité, nombre de ventes, et « Utiliser ».
class _MatchCard extends StatelessWidget {
  final BoutiquePayer match;
  final VoidCallback onUse;

  const _MatchCard({required this.match, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.vertSavane.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.vertSavane.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.how_to_reg_outlined,
            size: 18,
            color: AppColors.vertSavane,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.boutiquePayerDirectoryCount(match.saleCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onUse, child: Text(l10n.boutiquePayerUse)),
        ],
      ),
    );
  }
}

class _NeutralNote extends StatelessWidget {
  final String text;

  const _NeutralNote({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimensions.spacingS),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.person_add_alt, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    ),
  );
}
