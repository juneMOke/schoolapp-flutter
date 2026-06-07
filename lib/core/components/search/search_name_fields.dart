import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Grille auto-fit des trois champs Nom / Post-nom / Prénom (EteeloTextInput).
///
/// Les champs s'adaptent à la largeur disponible : 3 colonnes si la place le
/// permet, sinon ils repassent à la ligne (1 colonne quand le groupe est
/// étroit, p. ex. en disposition côte à côte).
class SearchNameFields extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
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
    this.enabled = true,
    this.inputFormatters,
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

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: fieldWidth,
              child: EteeloTextInput(
                controller: lastNameController,
                label: lastNameLabel,
                enabled: enabled,
                onChanged: onChanged,
                inputFormatters: inputFormatters,
                textInputAction: TextInputAction.next,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: EteeloTextInput(
                controller: surnameController,
                label: surnameLabel,
                enabled: enabled,
                onChanged: onChanged,
                inputFormatters: inputFormatters,
                textInputAction: TextInputAction.next,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: EteeloTextInput(
                controller: firstNameController,
                label: firstNameLabel,
                enabled: enabled,
                onChanged: onChanged,
                inputFormatters: inputFormatters,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        );
      },
    );
  }
}
