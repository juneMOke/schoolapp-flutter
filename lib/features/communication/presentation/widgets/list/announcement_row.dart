import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_category_chip.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_medallion.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de la liste : la ligne entière ouvre le communiqué — le détail
/// s'il est envoyé, l'éditeur sinon.
///
/// ≥ 720 dp : statut et date alignés à droite. En dessous, ils passent sous
/// la méta.
class AnnouncementRow extends StatelessWidget {
  final Announcement announcement;
  final DateTime now;
  final VoidCallback onOpen;

  /// Un filet au-dessus de la ligne — absent sur la première d'une carte.
  final bool divided;

  /// Ouvert à côté de la liste (grand écran) : la ligne reste marquée.
  final bool selected;

  const AnnouncementRow({
    super.key,
    required this.announcement,
    required this.now,
    required this.onOpen,
    this.divided = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected ? true : null,
    child: InkWell(
      onTap: onOpen,
      hoverColor: AppColors.stateHover,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.statePressed : null,
          border: divided
              ? const Border(top: BorderSide(color: AppColors.border))
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >=
                AppDimensions.communicationRowWideMinWidth;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnnouncementMedallion(category: announcement.content.category),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Body(
                    announcement: announcement,
                    trailingBelow: wide ? null : _Trailing(announcement, now),
                  ),
                ),
                if (wide) ...[
                  const SizedBox(width: AppSpacing.md),
                  _Trailing(announcement, now, alignEnd: true),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  final Announcement announcement;
  final Widget? trailingBelow;

  const _Body({required this.announcement, this.trailingBelow});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = announcement.content;
    final title = content.title.isEmpty
        ? l10n.communicationUntitled
        : content.title;
    final trailing = trailingBelow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            // Seule l'urgence est répétée près du titre.
            if (content.category == AnnouncementCategory.urgent)
              const AnnouncementCategoryChip(
                category: AnnouncementCategory.urgent,
              ),
          ],
        ),
        if (content.body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            l10n.excerptOf(announcement),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs / 2),
        Text(
          l10n.metaOf(announcement),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        if (trailing != null) ...[
          const SizedBox(height: AppSpacing.sm),
          trailing,
        ],
      ],
    );
  }
}

class _Trailing extends StatelessWidget {
  final Announcement announcement;
  final DateTime now;
  final bool alignEnd;

  const _Trailing(this.announcement, this.now, {this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final date = AnnouncementDates.rowDate(
      AppLocalizations.of(context)!,
      announcement,
      now,
    );
    final children = [
      AnnouncementStatusBadge(status: announcement.status),
      if (date != null)
        Text(
          date,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
    ];
    return alignEnd
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              children.first,
              if (children.length > 1) ...[
                const SizedBox(height: AppSpacing.xs),
                children.last,
              ],
            ],
          )
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
  }
}
