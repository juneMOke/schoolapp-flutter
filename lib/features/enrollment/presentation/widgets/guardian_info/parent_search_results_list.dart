import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résultats de la popin « Rechercher un parent » : une fiche par ligne,
/// sélection immédiate au tap.
///
/// ⚠️ Liste **inerte** (`shrinkWrap` + `NeverScrollableScrollPhysics`) : c'est
/// `EteeloDialogBody` qui fournit le défilement. Rendue maîtresse du sien,
/// elle gagnerait l'arène des gestes sans avoir rien à faire défiler, et le
/// doigt de l'utilisateur ne déplacerait plus rien.
class ParentSearchResultsList extends StatelessWidget {
  final List<LocalParent> results;
  final ValueChanged<LocalParent> onSelected;

  /// Mode **désignation** : le tap marque la ligne au lieu de valider tout de
  /// suite — c'est un bouton de pied qui tranche ensuite. Sert à la popin de
  /// conflit de téléphone, où l'on veut relire la fiche proposée avant de
  /// remplacer le tuteur en cours de saisie.
  final bool selectable;

  /// Ligne actuellement désignée en mode [selectable].
  final String? selectedParentId;

  const ParentSearchResultsList({
    super.key,
    required this.results,
    required this.onSelected,
    this.selectable = false,
    this.selectedParentId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimensions.spacingS),
      itemBuilder: (context, index) {
        final parent = results[index];
        final fullName = [
          parent.firstName,
          parent.surname,
          parent.lastName,
        ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

        final isSelected = selectable && selectedParentId == parent.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(parent),
            borderRadius: AppRadius.brMd,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(
                  color: isSelected ? AppColors.bleuArdoise : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Un tuteur sans numéro se dit, il ne se laisse pas
                        // en blanc : dans une liste de résultats, une ligne
                        // vide se lit comme un chargement qui n'a pas abouti.
                        Text(
                          (parent.phoneNumber ?? '').trim().isEmpty
                              ? l10n.guardianPhoneNumberAbsent
                              : parent.phoneNumber!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selectable
                        ? (isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded)
                        : Icons.chevron_right_rounded,
                    color: isSelected
                        ? AppColors.bleuArdoise
                        : AppColors.textSecondary,
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
