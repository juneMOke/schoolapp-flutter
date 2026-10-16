import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Grille auto-fit des trois champs Nom / Post-nom / Prénom (EteeloTextInput).
///
/// La capitalisation des identités est le défaut d'[EteeloTextInput] : aucun
/// formatter à passer ici, et aucun champ d'identité ne peut plus l'oublier.
///
/// Les champs s'adaptent à la largeur disponible : 3 colonnes si la place le
/// permet, sinon ils repassent à la ligne (1 colonne quand le groupe est
/// étroit, p. ex. en disposition côte à côte).
///
/// Entrée lance la recherche ([onSubmitted]) : depuis le dernier champ sur la
/// tablette — « suivant » y enchaîne les deux premiers —, depuis n'importe
/// lequel au clavier physique.
class SearchNameFields extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final double spacing;
  final double minFieldWidth;

  const SearchNameFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.firstNameLabel,
    required this.lastNameLabel,
    required this.surnameLabel,
    required this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.spacing = AppDimensions.searchFieldGap,
    this.minFieldWidth = AppDimensions.searchFieldMinWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final threeUp = available >= (minFieldWidth * 3) + (spacing * 2);
        final fieldWidth = threeUp
            ? (available - (spacing * 2)) / 3
            : available;

        Widget field(
          TextEditingController controller,
          String label, {
          bool last = false,
        }) {
          final submits = last || expectsPhysicalKeyboard;
          return SizedBox(
            width: fieldWidth,
            child: EteeloTextInput(
              controller: controller,
              label: label,
              enabled: enabled,
              onChanged: onChanged,
              textInputAction: submits
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: submits ? (_) => onSubmitted?.call() : null,
            ),
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            field(lastNameController, lastNameLabel),
            field(surnameController, surnameLabel),
            field(firstNameController, firstNameLabel, last: true),
          ],
        );
      },
    );
  }
}
