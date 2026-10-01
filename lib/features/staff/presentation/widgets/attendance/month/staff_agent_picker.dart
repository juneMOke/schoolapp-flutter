import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

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
      width: AppDimensions.searchToolbarMinWidth,
      child: Autocomplete<StaffMember>(
        // Une clé par agent : ouvert depuis le récapitulatif, le champ montre
        // l'agent choisi plutôt que la dernière recherche.
        key: ValueKey(selected?.id),
        initialValue: TextEditingValue(text: selected?.fullName ?? ''),
        displayStringForOption: (member) => member.fullName,
        optionsBuilder: (value) => [
          for (final member in members)
            if (StaffMemberSearch.matches(member, value.text)) member,
        ],
        onSelected: onSelected,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            EteeloTextInput(
              controller: controller,
              focusNode: focusNode,
              label: l10n.staffAttendanceTabAgent,
              placeholder: l10n.staffAttendanceAgentPicker,
              capitalization: EteeloTextCapitalization.none,
              onSubmitted: (_) => onSubmitted(),
            ),
        optionsViewBuilder: (context, onPick, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: AppSpacing.xs,
            borderRadius: AppRadius.brMd,
            color: AppColors.surfaceRaised,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.presenceMarkPickerWidth,
                maxHeight: AppDimensions.presenceMarkPickerMaxHeight,
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
                        sync: RecordSyncState.synced,
                        size: AppDimensions.presenceMarkIconButtonSize,
                      ),
                      title: Text(member.fullName),
                      subtitle: member.jobTitle == null
                          ? null
                          : Text(member.jobTitle!),
                      trailing: member.id == selected?.id
                          ? const Icon(
                              Icons.check,
                              color: AppColors.presenceMarkPresentInk,
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
