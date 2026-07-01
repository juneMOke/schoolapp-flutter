import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_class_accordion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vue « contenu » de la liste : en-tête (compteur + bascule globale) puis les
/// accordéons de classe. L'état d'ouverture est local (présentation pure) ;
/// toutes les classes sont dépliées par défaut (spec §1).
class MyCoursesSuccessView extends StatefulWidget {
  final List<CourseSummary> courses;

  /// Ouvre le détail d'un cours (`null` → tuiles non interactives).
  final void Function(CoursDetailArgs args)? onOpenCourse;

  const MyCoursesSuccessView({
    super.key,
    required this.courses,
    this.onOpenCourse,
  });

  @override
  State<MyCoursesSuccessView> createState() => _MyCoursesSuccessViewState();
}

class _MyCoursesSuccessViewState extends State<MyCoursesSuccessView> {
  late Set<String> _expandedIds;

  @override
  void initState() {
    super.initState();
    _expandedIds = _allIds();
  }

  @override
  void didUpdateWidget(covariant MyCoursesSuccessView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nouveau jeu de cours (re-fetch) -> on réouvre tout par défaut.
    if (!_sameIds(oldWidget.courses, widget.courses)) {
      _expandedIds = _allIds();
    }
  }

  Set<String> _allIds() =>
      widget.courses.map((course) => course.classroom.id).toSet();

  bool _sameIds(List<CourseSummary> a, List<CourseSummary> b) {
    if (a.length != b.length) return false;
    final idsB = b.map((course) => course.classroom.id).toSet();
    return a.every((course) => idsB.contains(course.classroom.id));
  }

  bool get _allExpanded =>
      widget.courses.isNotEmpty && _expandedIds.length == widget.courses.length;

  int get _totalCourses =>
      widget.courses.fold(0, (sum, course) => sum + course.courses.length);

  void _toggleAll() {
    setState(() {
      _expandedIds = _allExpanded ? <String>{} : _allIds();
    });
  }

  void _toggleOne(String classroomId) {
    setState(() {
      if (_expandedIds.contains(classroomId)) {
        _expandedIds.remove(classroomId);
      } else {
        _expandedIds.add(classroomId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListHeader(
          counterLabel: l10n.myCoursesCount(
            widget.courses.length,
            _totalCourses,
          ),
          allExpanded: _allExpanded,
          onToggleAll: _toggleAll,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < widget.courses.length; i++) ...[
          MyCoursesClassAccordion(
            group: widget.courses[i],
            visual: AcademicsClassVisual.forIndex(i),
            expanded: _expandedIds.contains(widget.courses[i].classroom.id),
            onToggle: () => _toggleOne(widget.courses[i].classroom.id),
            onOpenCourse: widget.onOpenCourse,
          ),
          if (i != widget.courses.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String counterLabel;
  final bool allExpanded;
  final VoidCallback onToggleAll;

  const _ListHeader({
    required this.counterLabel,
    required this.allExpanded,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            counterLabel.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        EteeloButton.secondary(
          label: allExpanded
              ? l10n.myCoursesCollapseAll
              : l10n.myCoursesExpandAll,
          icon: allExpanded
              ? Icons.unfold_less_rounded
              : Icons.unfold_more_rounded,
          onPressed: onToggleAll,
          fullWidth: false,
        ),
      ],
    );
  }
}
