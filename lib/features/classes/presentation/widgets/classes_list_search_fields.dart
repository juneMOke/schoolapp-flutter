import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';

/// Grille de recherche des classes en composants design-system Eteelo.
///
/// Deux groupes de trois champs (cascade Cycle → Niveau → Classe, puis
/// Nom / Post-nom / Prénom). Chaque groupe se replie en 3 → 2 → 1 colonnes
/// selon la largeur disponible (auto-fit, largeur min par champ).
class ClassesListSearchFieldsGrid extends StatelessWidget {
  /// Largeur minimale d'un champ avant repli sur la colonne suivante.
  static const double _minFieldWidth = 200;
  static const double _gap = AppDimensions.spacingS;

  final List<ClassesListCycleOption> cycleOptions;
  final String? selectedCycleId;
  final List<ClassesListLevelOption> levelOptions;
  final String? selectedLevelKey;
  final List<BootstrapClassroom> classroomOptions;
  final String? selectedClassroomId;
  final bool classroomEnabled;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final String cycleLabel;
  final String levelLabel;
  final String classroomLabel;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final ValueChanged<String?>? onCycleChanged;
  final ValueChanged<String?>? onLevelChanged;
  final ValueChanged<String?>? onClassroomChanged;
  final ValueChanged<String>? onFirstNameChanged;
  final ValueChanged<String>? onLastNameChanged;
  final ValueChanged<String>? onSurnameChanged;

  const ClassesListSearchFieldsGrid({
    super.key,
    required this.cycleOptions,
    required this.selectedCycleId,
    required this.levelOptions,
    required this.selectedLevelKey,
    required this.classroomOptions,
    required this.selectedClassroomId,
    required this.classroomEnabled,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.cycleLabel,
    required this.levelLabel,
    required this.classroomLabel,
    required this.firstNameLabel,
    required this.lastNameLabel,
    required this.surnameLabel,
    required this.onCycleChanged,
    required this.onLevelChanged,
    required this.onClassroomChanged,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onSurnameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownFields = <Widget>[
      FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: EteeloSelectInput<String>(
          label: cycleLabel,
          value: selectedCycleId,
          enabled: cycleOptions.isNotEmpty,
          minWidth: 0,
          onChanged: (value) => onCycleChanged?.call(value),
          items: cycleOptions
              .map((o) => EteeloSelectItem<String>(value: o.id, label: o.label))
              .toList(growable: false),
        ),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(2),
        child: EteeloSelectInput<String>(
          label: levelLabel,
          value: selectedLevelKey,
          enabled: levelOptions.isNotEmpty,
          minWidth: 0,
          onChanged: (value) => onLevelChanged?.call(value),
          items: levelOptions
              .map(
                (o) => EteeloSelectItem<String>(value: o.key, label: o.label),
              )
              .toList(growable: false),
        ),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(3),
        child: EteeloSelectInput<String>(
          label: classroomLabel,
          value: selectedClassroomId,
          enabled: classroomEnabled,
          minWidth: 0,
          onChanged: (value) => onClassroomChanged?.call(value),
          items: classroomOptions
              .map((c) => EteeloSelectItem<String>(value: c.id, label: c.name))
              .toList(growable: false),
        ),
      ),
    ];

    final textFields = <Widget>[
      FocusTraversalOrder(
        order: const NumericFocusOrder(4),
        child: EteeloTextInput(
          controller: lastNameController,
          label: lastNameLabel,
          onChanged: onLastNameChanged,
          inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          textInputAction: TextInputAction.next,
        ),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(5),
        child: EteeloTextInput(
          controller: surnameController,
          label: surnameLabel,
          onChanged: onSurnameChanged,
          inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          textInputAction: TextInputAction.next,
        ),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(6),
        child: EteeloTextInput(
          controller: firstNameController,
          label: firstNameLabel,
          onChanged: onFirstNameChanged,
          inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          textInputAction: TextInputAction.done,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Column(
          children: [
            _autoFitRow(dropdownFields, maxWidth),
            const SizedBox(height: _gap),
            _autoFitRow(textFields, maxWidth),
          ],
        );
      },
    );
  }

  /// Dispose [fields] en colonnes auto-fit : autant de colonnes que la largeur
  /// le permet (max = nombre de champs), repli ligne à ligne au-delà.
  Widget _autoFitRow(List<Widget> fields, double maxWidth) {
    var columns = fields.length;
    while (columns > 1 &&
        maxWidth < (columns * _minFieldWidth) + ((columns - 1) * _gap)) {
      columns--;
    }
    final fieldWidth = (maxWidth - ((columns - 1) * _gap)) / columns;

    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final field in fields) SizedBox(width: fieldWidth, child: field),
      ],
    );
  }
}
