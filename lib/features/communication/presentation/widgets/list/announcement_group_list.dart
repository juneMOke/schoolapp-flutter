import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/projections/announcement_list_view.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_card.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcement_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les groupes de la liste, chacun dans sa carte.
class AnnouncementGroupList extends StatelessWidget {
  final AnnouncementListView view;
  final DateTime now;
  final ValueChanged<Announcement> onOpen;

  const AnnouncementGroupList({
    super.key,
    required this.view,
    required this.now,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in view.groups) ...[
          if (view.showHeaders)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.communicationGroupHeader(
                    l10n.statusGroupLabel(group.status),
                    group.items.length,
                  ),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          CommunicationCard.flush(
            child: Column(
              children: [
                for (final (index, item) in group.items.indexed)
                  AnnouncementRow(
                    key: ValueKey(item.id),
                    announcement: item,
                    now: now,
                    // Le premier filet est celui du cadre : on ne le double pas.
                    divided: index > 0,
                    onOpen: () => onOpen(item),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
