import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

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

  const ParentSearchResultsList({
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
      itemBuilder: (context, index) {
        final parent = results[index];
        final fullName = [
          parent.firstName,
          parent.surname,
          parent.lastName,
        ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

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
                border: Border.all(color: AppColors.border),
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
                        Text(
                          parent.phoneNumber,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
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
        );
      },
    );
  }
}
