import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_sync_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Une personne proposée par [PresencePersonPicker].
class PresencePickerEntry<T> {
  final T value;
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? detail;

  const PresencePickerEntry({
    required this.value,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.detail,
  });
}

/// Choisir la personne d'une fiche mensuelle : une recherche à suggestions
/// (l'[Autocomplete] du framework — Entrée prend le premier résultat, Échap
/// ferme). [matches] est la recherche du module (sans accents).
class PresencePersonPicker<T extends Object> extends StatelessWidget {
  final List<PresencePickerEntry<T>> entries;
  final String? selectedId;
  final String label;
  final String placeholder;
  final bool Function(T value, String query) matches;
  final ValueChanged<T> onSelected;

  /// Les personnes sont des élèves : leur photo remplace les initiales.
  final bool showsStudentPhotos;

  const PresencePersonPicker({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.label,
    required this.placeholder,
    required this.matches,
    required this.onSelected,
    this.showsStudentPhotos = false,
  });

  @override
  Widget build(BuildContext context) {
    PresencePickerEntry<T>? selected;
    for (final entry in entries) {
      if (entry.id == selectedId) selected = entry;
    }
    return SizedBox(
      width: AppDimensions.searchToolbarMinWidth,
      child: Autocomplete<PresencePickerEntry<T>>(
        // Une clé par personne : ouvert depuis le récapitulatif, le champ
        // montre la personne choisie plutôt que la dernière recherche.
        key: ValueKey(selectedId),
        initialValue: TextEditingValue(text: selected?.fullName ?? ''),
        displayStringForOption: (entry) => entry.fullName,
        optionsBuilder: (value) => [
          for (final entry in entries)
            if (matches(entry.value, value.text)) entry,
        ],
        onSelected: (entry) => onSelected(entry.value),
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            EteeloTextInput(
              controller: controller,
              focusNode: focusNode,
              label: label,
              placeholder: placeholder,
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
                  for (final entry in options)
                    ListTile(
                      dense: true,
                      leading: PersonSyncAvatar(
                        firstName: entry.firstName,
                        lastName: entry.lastName,
                        personId: entry.id,
                        sync: RecordSyncState.synced,
                        size: AppDimensions.presenceMarkIconButtonSize,
                        studentPhotoOf: showsStudentPhotos ? entry.id : null,
                      ),
                      title: Text(entry.fullName),
                      subtitle: entry.detail == null
                          ? null
                          : Text(entry.detail!),
                      trailing: entry.id == selectedId
                          ? const Icon(
                              Icons.check,
                              color: AppColors.presenceMarkPresentInk,
                            )
                          : null,
                      onTap: () => onPick(entry),
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
