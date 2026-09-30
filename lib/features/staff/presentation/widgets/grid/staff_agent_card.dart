import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dossier_meter.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_identity_lines.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_sync_pill.dart';

/// Un agent en carte : qui il est, ce qu'il fait, sous quel contrat, et où en
/// est son dossier. La carte entière ouvre l'agent.
class StaffAgentCard extends StatelessWidget {
  final StaffFileRow row;
  final VoidCallback? onOpen;

  const StaffAgentCard({super.key, required this.row, this.onOpen});

  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    final member = row.member;
    final dossier = row.dossier;
    return Material(
      color: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brCard,
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaffAvatar(
                    member: member,
                    sync: row.sync,
                    size: _avatarSize,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        StaffNumberText(staffNumber: member.staffNumber),
                        const SizedBox(height: AppSpacing.xs),
                        StaffRoleText(member: member),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Flexible(child: StaffContractBadge(kind: row.kind)),
                  const SizedBox(width: AppSpacing.sm),
                  const Spacer(),
                  if (row.sync == StaffSyncState.failed)
                    Flexible(child: StaffSyncPill(state: row.sync))
                  else if (dossier != null)
                    Flexible(child: StaffDossierMeter(dossier: dossier)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
