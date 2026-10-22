import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiary.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un élève et ce qu'il a reçu : avatar, nom, classe et dernier achat, une
/// pastille par article (« 2× Polo Lacoste · T. M »), son total à droite.
///
/// Le total est celui de **ses** lignes — jamais celui du reçu, le payeur a pu
/// acheter pour d'autres.
class BoutiqueBeneficiaryTile extends StatelessWidget {
  final BoutiqueBeneficiary student;

  /// Sous ce seuil, les pastilles passent **sous** le nom.
  static const double _wideMin = 600;

  /// Teinte des pastilles : 9 % de la couleur de famille.
  static const int _chipTint = 9;

  const BoutiqueBeneficiaryTile({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final words = student.fullName.trim().split(RegExp(r'\s+'));
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.fullName,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          l10n.boutiqueBeneficiariesLastPurchase(
            student.classLabel ?? l10n.boutiqueBeneficiariesNoClass,
            // Le jour de l'ÉCOLE : un achat de 0 h 30 à Kinshasa n'est pas
            // de la veille parce que la tablette est en UTC.
            formatLocalDay(SchoolTime.today(student.lastPurchaseAt)),
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
        ),
      ],
    );
    final chips = Wrap(
      spacing: AppDimensions.spacingXS,
      runSpacing: AppDimensions.spacingXS,
      children: [for (final article in student.articles) _chip(article, l10n)],
    );
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final line in BoutiqueDashboardLabels.moneyLines(
          student.amounts.entries,
        ))
          Text(
            line,
            style: AppTypography.money.copyWith(color: AppColors.textPrimary),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideMin;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(
                firstName: words.length > 1 ? words.last : '',
                lastName: words.first,
                personId: student.studentId,
                studentPhotoOf: student.studentId,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: identity),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(child: chips),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          identity,
                          const SizedBox(height: AppDimensions.spacingXS),
                          chips,
                        ],
                      ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              amount,
            ],
          );
        },
      ),
    );
  }

  Widget _chip(BeneficiaryArticle article, AppLocalizations l10n) {
    final accent = BoutiqueFamilyStyle.accentOf(article.family);
    final text = [
      l10n.boutiqueBeneficiariesArticleChip(article.quantity, article.label),
      if (article.sizes.isNotEmpty)
        l10n.boutiqueBeneficiariesSizes(article.sizes.join(', ')),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: ColorMix.tint(AppColors.surfaceRaised, accent, _chipTint),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
