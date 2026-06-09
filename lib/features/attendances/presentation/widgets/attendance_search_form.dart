import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_search_fields.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';

class AttendanceSearchForm extends StatefulWidget {
  final List<AttendanceCycleOption> options;
  final ValueChanged<AttendanceSearchRequest> onSearch;

  const AttendanceSearchForm({
    super.key,
    required this.options,
    required this.onSearch,
  });

  @override
  State<AttendanceSearchForm> createState() => _AttendanceSearchFormState();
}

class _AttendanceSearchFormState extends State<AttendanceSearchForm> {
  String? _selectedCycleId;
  String? _selectedLevelKey;
  String? _selectedClassroomId;
  DateTime _selectedDate = DateTime.now();

  @override
  void didUpdateWidget(covariant AttendanceSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options == widget.options) {
      return;
    }

    if (_selectedCycle != null &&
        _selectedLevel != null &&
        _selectedClassroom != null) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_selectedCycle == null) {
          _selectedCycleId = null;
        }
        if (_selectedLevel == null) {
          _selectedLevelKey = null;
        }
        if (_selectedClassroom == null) {
          _selectedClassroomId = null;
        }
      });
    });
  }

  AttendanceCycleOption? get _selectedCycle {
    for (final option in widget.options) {
      if (option.id == _selectedCycleId) {
        return option;
      }
    }
    return null;
  }

  List<AttendanceLevelOption> get _levelOptions =>
      _selectedCycle?.levels ?? const <AttendanceLevelOption>[];

  AttendanceLevelOption? get _selectedLevel {
    for (final option in _levelOptions) {
      if (option.key == _selectedLevelKey) {
        return option;
      }
    }
    return null;
  }

  Object? get _selectedClassroom {
    final selectedLevel = _selectedLevel;
    if (selectedLevel == null || _selectedClassroomId == null) {
      return null;
    }

    for (final classroom in selectedLevel.classrooms) {
      if (classroom.id == _selectedClassroomId) {
        return classroom;
      }
    }

    return null;
  }

  AttendanceSearchRequest? get _request {
    final cycle = _selectedCycle;
    final level = _selectedLevel;
    final classroomId = _selectedClassroomId;
    if (cycle == null || level == null || classroomId == null) {
      return null;
    }

    for (final classroom in level.classrooms) {
      if (classroom.id == classroomId) {
        return AttendanceSearchRequest(
          selectedCycle: cycle,
          selectedLevel: level,
          selectedClassroom: classroom,
          date: _selectedDate,
        );
      }
    }

    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (!mounted || picked == null || picked == _selectedDate) {
      return;
    }

    setState(() => _selectedDate = picked);
    _triggerSearchIfReady();
  }

  void _triggerSearchIfReady() {
    final request = _request;
    if (request != null) {
      widget.onSearch(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
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
      child: AttendanceSearchFields(
        cycleOptions: widget.options,
        selectedCycleId: _selectedCycleId,
        levelOptions: _levelOptions,
        selectedLevelKey: _selectedLevelKey,
        classroomOptions: _selectedLevel?.classrooms ?? const [],
        selectedClassroomId: _selectedClassroomId,
        selectedDate: _selectedDate,
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
        onClassroomChanged: (value) {
          setState(() => _selectedClassroomId = value);
          _triggerSearchIfReady();
        },
        onPickDate: _pickDate,
      ),
    );
  }
}
