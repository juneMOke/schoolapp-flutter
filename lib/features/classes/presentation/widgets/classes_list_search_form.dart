import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_search_form_logic.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_actions.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_fields.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_search_inputs.dart';
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
    final levelOptions = selectedCycle?.levels ?? const <ClassesListLevelOption>[];
    final selectedLevel = ClassesListSearchFormLogic.findLevel(
      levelOptions,
      _selectedLevelKey,
    );
    final classroomOptions = selectedLevel?.classrooms ?? const [];
    final validationMessage = ClassesListSearchFormLogic.validationMessage(
      l10n: l10n,
      selectedCycle: selectedCycle,
      selectedLevel: selectedLevel,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      surname: _surnameController.text,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.classesSectionSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.classesOrganisationShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.classesListSearchTitle,
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.classesListSearchHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ClassesListSearchFieldsGrid(
            cycleOptions: widget.options,
            selectedCycleId: _selectedCycleId,
            levelOptions: levelOptions,
            selectedLevelKey: _selectedLevelKey,
            classroomOptions: classroomOptions,
            selectedClassroomId: _selectedClassroomId,
            classroomEnabled: (selectedLevel?.splitIntoClassrooms ?? false) &&
                classroomOptions.isNotEmpty,
            classroomHelper: ClassesListSearchFormLogic.classroomHelper(
              l10n: l10n,
              selectedCycle: selectedCycle,
              selectedLevel: selectedLevel,
              classroomOptions: classroomOptions,
            ),
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            surnameController: _surnameController,
            cycleLabel: l10n.targetCycleLabel,
            levelLabel: l10n.targetLevelLabel,
            classroomLabel: l10n.classesOrganisationClassroomFieldLabel,
            firstNameLabel: l10n.firstName,
            lastNameLabel: l10n.lastName,
            surnameLabel: l10n.surname,
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
            onClassroomChanged: (value) => setState(() => _selectedClassroomId = value),
            onFirstNameChanged: (_) => setState(() {}),
            onLastNameChanged: (_) => setState(() {}),
            onSurnameChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: validationMessage == null
                ? ClassesListSearchFeedbackBanner(
                    key: const ValueKey('classes-list-ready'),
                    message: l10n.classesListSearchReady,
                    foreground: AppColors.financeDetailAccent,
                    background: AppColors.financeDetailAccentSoft,
                    icon: Icons.check_circle_outline_rounded,
                  )
                : ClassesListSearchFeedbackBanner(
                    key: const ValueKey('classes-list-error'),
                    message: validationMessage,
                    foreground: AppColors.danger,
                    background: AppColors.financeDetailDangerSoft,
                    icon: Icons.info_outline_rounded,
                  ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ClassesListSearchActions(
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
            onSearch: validationMessage == null && !widget.isSearching
                ? () {
                    if (selectedCycle == null || selectedLevel == null) {
                      return;
                    }
                    final classroom = ClassesListSearchFormLogic.findClassroom(
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
        ],
      ),
    );
  }
}
