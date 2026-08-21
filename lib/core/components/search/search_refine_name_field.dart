import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Champ **facultatif** d'affinage par nom, sous la cascade du mode « Par
/// classe ».
///
/// Il ne conditionne jamais l'ouverture de la recherche — c'est la classe qui
/// l'ouvre — il ne fait que restreindre la liste rendue. Sans lui, retrouver
/// quelqu'un dans une classe de soixante obligerait à connaître ses trois noms
/// et à passer par l'autre mode.
///
/// Le rapprochement est **partiel** et insensible aux accents
/// (`SearchNormalizationHelper.contains`, via `EnrollmentLocalListProjector`) :
/// « kab » suffit pour « Kabongo ». Il porte sur le **nom** (la colonne « Nom »),
/// pas sur le post-nom ni le prénom.
class SearchRefineNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const SearchRefineNameField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloTextInput(
      controller: controller,
      label: l10n.searchRefineByNameLabel,
      placeholder: l10n.searchRefineByNamePlaceholder,
      enabled: enabled,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
    );
  }
}
