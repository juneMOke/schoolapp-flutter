import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_sync_pill.dart';

/// L'avatar d'un agent (initiales sur sa teinte d'identité) et, en bas à
/// droite, la pastille de synchronisation.
class StaffAvatar extends StatelessWidget {
  final StaffMember member;
  final StaffSyncState sync;
  final double size;

  const StaffAvatar({
    super.key,
    required this.member,
    required this.sync,
    this.size = AvatarSize.lg,
  });

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PersonAvatar(
            firstName: member.firstName,
            lastName: member.lastName,
            personId: member.id,
            size: size,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(dot * 0.28),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: StaffSyncDot(state: sync, size: dot),
            ),
          ),
        ],
      ),
    );
  }
}
