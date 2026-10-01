import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// L'avatar d'une personne (initiales sur sa teinte d'identité) et, en bas à
/// droite, la pastille de synchronisation de ce qu'on a saisi pour elle.
class PersonSyncAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String personId;
  final RecordSyncState sync;
  final double size;

  const PersonSyncAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.personId,
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
            firstName: firstName,
            lastName: lastName,
            personId: personId,
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
              child: RecordSyncDot(state: sync, size: dot),
            ),
          ),
        ],
      ),
    );
  }
}
