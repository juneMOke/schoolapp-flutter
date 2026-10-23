import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
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

/// Une ligne du tableau « Élèves concernés » : l'élève et sa classe, une
/// pastille par article (« 2× Polo Lacoste · T. M »), son dernier achat, son
/// total.
///
/// Le total est celui de **ses** lignes — jamais celui du reçu, le payeur a pu
/// acheter pour d'autres.
abstract final class BoutiqueBeneficiaryRow {
  static DataTableRowSpec of(
    BoutiqueBeneficiary student,
    AppLocalizations l10n,
  ) {
    final words = student.fullName.trim().split(RegExp(r'\s+'));
    final amounts = BoutiqueDashboardLabels.moneyLines(student.amounts.entries);
    return DataTableRowSpec(
      id: student.studentId,
      displayName: student.fullName,
      leading: PersonAvatar(
        firstName: words.length > 1 ? words.last : '',
        lastName: words.first,
        personId: student.studentId,
        studentPhotoOf: student.studentId,
        size: AppDimensions.enrollmentDashboardDayAvatarSize,
      ),
      cells: [
        DataTableCellSpec(
          text: student.fullName,
          variant: DataTableCellTextVariant.strong,
          secondaryText:
              student.classLabel ?? l10n.boutiqueBeneficiariesNoClass,
        ),
        DataTableCellSpec(
          child: _ArticleChips(articles: student.articles, l10n: l10n),
        ),
        DataTableCellSpec(
          // Le jour de l'ÉCOLE : un achat de 0 h 30 à Kinshasa n'est pas de la
          // veille parce que la tablette est en UTC.
          text: formatLocalDay(SchoolTime.today(student.lastPurchaseAt)),
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          // Une devise par ligne : elles ne se somment pas.
          text: amounts.isEmpty ? '' : amounts.first,
          variant: DataTableCellTextVariant.strong,
          secondaryText: amounts.length > 1
              ? amounts.skip(1).join(' · ')
              : null,
          secondaryVariant: DataTableCellTextVariant.strong,
        ),
      ],
    );
  }
}

class _ArticleChips extends StatelessWidget {
  final List<BeneficiaryArticle> articles;
  final AppLocalizations l10n;

  /// Teinte des pastilles : 9 % de la couleur de famille.
  static const int _chipTint = 9;

  const _ArticleChips({required this.articles, required this.l10n});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppDimensions.spacingXS,
    runSpacing: AppDimensions.spacingXS,
    children: [for (final article in articles) _chip(article)],
  );

  Widget _chip(BeneficiaryArticle article) {
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
