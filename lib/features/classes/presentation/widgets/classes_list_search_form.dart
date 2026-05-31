import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_search_form_logic.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_actions.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_fields.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListSearchForm extends StatefulWidget {
  final List<ClassesListCycleOption> options;
  final bool isSearching;
  final ValueChanged<ClassesListSearchRequest> onSearch;

  const ClassesListSearchForm({
    super.key,
    required this.options,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  State<ClassesListSearchForm> createState() => _ClassesListSearchFormState();
}

class _ClassesListSearchFormState extends State<ClassesListSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();

  String? _selectedCycleId;
  String? _selectedLevelKey;
  String? _selectedClassroomId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClassesListSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options == widget.options) {
      return;
    }

    final sync = ClassesListSearchFormLogic.computeSelectionSync(
      options: widget.options,
      selectedCycleId: _selectedCycleId,
      selectedLevelKey: _selectedLevelKey,
      selectedClassroomId: _selectedClassroomId,
    );
    if (!sync.hasAny) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (sync.clearCycle) _selectedCycleId = null;
        if (sync.clearLevel) _selectedLevelKey = null;
        if (sync.clearClassroom) _selectedClassroomId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCycle = ClassesListSearchFormLogic.findCycle(
      widget.options,
      _selectedCycleId,
    );
    final levelOptions =
        selectedCycle?.levels ?? const <ClassesListLevelOption>[];
    final selectedLevel = ClassesListSearchFormLogic.findLevel(
      levelOptions,
      _selectedLevelKey,
    );
    final classroomOptions = selectedLevel?.classrooms ?? const [];
    final canSearch = ClassesListSearchFormLogic.hasAtLeastOneCriterion(
      selectedCycle: selectedCycle,
      selectedLevel: selectedLevel,
      selectedClassroomId: _selectedClassroomId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      surname: _surnameController.text,
    );

    return SearchFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClassesListSearchFieldsGrid(
            cycleOptions: widget.options,
            selectedCycleId: _selectedCycleId,
            levelOptions: levelOptions,
            selectedLevelKey: _selectedLevelKey,
            classroomOptions: classroomOptions,
            selectedClassroomId: _selectedClassroomId,
            classroomEnabled:
                (selectedLevel?.splitIntoClassrooms ?? false) &&
                classroomOptions.isNotEmpty,
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            surnameController: _surnameController,
            cycleLabel: l10n.schoolCycle,
            levelLabel: l10n.schoolLevelLabel,
            classroomLabel: l10n.classesListClassroomOptionalLabel,
            firstNameLabel: l10n.classesListFirstNameOptionalLabel,
            lastNameLabel: l10n.classesListLastNameOptionalLabel,
            surnameLabel: l10n.classesListSurnameOptionalLabel,
            onCycleChanged: (value) {
              setState(() {
                _selectedCycleId = value;
                _selectedLevelKey = null;
                _selectedClassroomId = null;
              });
            },
            onLevelChanged: (value) {
              setState(() {
                _selectedLevelKey = value;
                _selectedClassroomId = null;
              });
            },
            onClassroomChanged: (value) =>
                setState(() => _selectedClassroomId = value),
            onFirstNameChanged: (_) => setState(() {}),
            onLastNameChanged: (_) => setState(() {}),
            onSurnameChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: ClassesListSearchActions(
              onReset: () {
                setState(() {
                  _firstNameController.clear();
                  _lastNameController.clear();
                  _surnameController.clear();
                  _selectedCycleId = null;
                  _selectedLevelKey = null;
                  _selectedClassroomId = null;
                });
              },
              onSearch: canSearch && !widget.isSearching
                  ? () {
                      final classroom = selectedLevel == null
                          ? null
                          : ClassesListSearchFormLogic.findClassroom(
                              selectedLevel.classrooms,
                              _selectedClassroomId,
                            );

                      widget.onSearch(
                        ClassesListSearchRequest(
                          firstName: _firstNameController.text.trim(),
                          lastName: _lastNameController.text.trim(),
                          surname: _surnameController.text.trim(),
                          selectedCycle: selectedCycle,
                          selectedLevel: selectedLevel,
                          selectedClassroom: classroom,
                        ),
                      );
                    }
                  : null,
              isSearching: widget.isSearching,
              clearLabel: l10n.clear,
              searchLabel: l10n.search,
            ),
          ),
        ],
      ),
    );
  }
}
