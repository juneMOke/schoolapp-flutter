import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_category_chip.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_medallion.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_status_badge.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_back_bar.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_card.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/detail/announcement_meta_grid.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/preview/announcement_preview_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un communiqué envoyé, en lecture seule : il ne se modifie ni ne se
/// retire. « Dupliquer » ouvre un nouveau brouillon pré-rempli.
class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onBack;

  /// `null` sans le droit d'envoyer.
  final VoidCallback? onDuplicate;
  final String? schoolName;
  final DateTime Function() now;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
    required this.onBack,
    this.onDuplicate,
    this.schoolName,
    this.now = DateTime.now,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= AppDimensions.communicationEditorWideMinWidth;
      final preview = AnnouncementPreviewPanel(
        content: announcement.content,
        schoolName: schoolName,
      );
      final body = _Body(
        announcement: announcement,
        onBack: onBack,
        onDuplicate: onDuplicate,
        now: now(),
      );
      if (!wide) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              body,
              const SizedBox(height: AppSpacing.xl),
              preview,
            ],
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: body,
            ),
          ),
          SizedBox(
            width:
                AppDimensions.communicationPreviewPanelWidth +
                2 * AppSpacing.lg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: preview,
            ),
          ),
        ],
      );
    },
  );
}

class _Body extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onBack;
  final VoidCallback? onDuplicate;
  final DateTime now;

  const _Body({
    required this.announcement,
    required this.onBack,
    required this.onDuplicate,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = announcement.content;
    final duplicate = onDuplicate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommunicationBackBar(onBack: onBack),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnnouncementMedallion(
              category: content.category,
              size: AppDimensions.communicationHeroMedallionSize,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AnnouncementCategoryChip(category: content.category),
                      AnnouncementStatusBadge(status: announcement.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    header: true,
                    child: Text(
                      content.title.isEmpty
                          ? l10n.communicationUntitled
                          : content.title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (duplicate != null)
              EteeloButton.secondary(
                label: l10n.communicationDuplicate,
                icon: Icons.copy_outlined,
                onPressed: duplicate,
                fullWidth: false,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AnnouncementMetaGrid(announcement: announcement, now: now),
        const SizedBox(height: AppSpacing.lg),
        CommunicationCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.communicationBodyLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                content.body,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.communicationDetailPersonalised,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
