import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Choisir l'agent de la fiche mensuelle : une recherche à suggestions
/// (l'[Autocomplete] du framework — Entrée prend le premier résultat, Échap
/// ferme), la même recherche que le fichier du personnel.
class StaffAgentPicker extends StatelessWidget {
  final List<StaffMember> members;
  final StaffMember? selected;
  final ValueChanged<StaffMember> onSelected;

  const StaffAgentPicker({
    super.key,
    required this.members,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: AppDimensions.staffSearchMinWidth,
      child: Autocomplete<StaffMember>(
        displayStringForOption: StaffAttendanceLabels.callName,
        optionsBuilder: (value) => [
          for (final member in members)
            if (StaffMemberSearch.matches(member, value.text)) member,
        ],
        onSelected: onSelected,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => onSubmitted(),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.staffAttendanceAgentPicker,
                border: const OutlineInputBorder(borderRadius: AppRadius.brSm),
              ),
            ),
        optionsViewBuilder: (context, onPick, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: AppSpacing.xs,
            borderRadius: AppRadius.brMd,
            color: AppColors.surfaceRaised,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.staffAttendancePickerWidth,
                maxHeight: AppDimensions.staffAttendancePickerMaxHeight,
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                shrinkWrap: true,
                children: [
                  for (final member in options)
                    ListTile(
                      dense: true,
                      leading: StaffAvatar(
                        member: member,
                        sync: StaffSyncState.synced,
                        size: AppDimensions.staffAttendanceIconButtonSize,
                      ),
                      title: Text(StaffAttendanceLabels.callName(member)),
                      subtitle: member.jobTitle == null
                          ? null
                          : Text(member.jobTitle!),
                      trailing: member.id == selected?.id
                          ? const Icon(
                              Icons.check,
                              color: AppColors.staffAttendancePresentInk,
                            )
                          : null,
                      onTap: () => onPick(member),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
