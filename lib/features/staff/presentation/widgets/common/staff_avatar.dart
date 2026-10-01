import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/avatars/person_sync_avatar.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// L'avatar d'un agent et la pastille de synchronisation de sa fiche.
class StaffAvatar extends StatelessWidget {
  final StaffMember member;
  final RecordSyncState sync;
  final double size;

  const StaffAvatar({
    super.key,
    required this.member,
    required this.sync,
    this.size = AvatarSize.lg,
  });

  @override
  Widget build(BuildContext context) => PersonSyncAvatar(
    firstName: member.firstName,
    lastName: member.lastName,
    personId: member.id,
    sync: sync,
    size: size,
  );
}
