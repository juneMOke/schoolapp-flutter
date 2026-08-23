import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_class_accordion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vue « contenu » de la liste : en-tête (compteur + bascule globale) puis les
/// accordéons de classe. L'état d'ouverture est local (présentation pure) ;
/// toutes les classes sont dépliées par défaut (spec §1).
///
/// Un cours dont la classe n'est pas encore descendue en local
/// ([CourseSummary.classroomUnsynced]) n'a **pas** d'accordéon : on ne sait ni
/// la nommer ni compter ses élèves, et une carte anonyme aux effectifs à zéro
/// se lit comme une classe vide. Il est masqué, et une mention en pied dit
/// combien de cours attendent leur classe — les taire ferait croire à un cours
/// perdu.
///
/// ⚠️ **Mais jamais toutes.** Si le filtre ne laisse rien, l'écran annonçait
/// « 0 CLASSE · 0 COURS » et plus aucun cours n'était atteignable, alors que la
/// donnée est là. Ce n'est pas un cas de bord : sur une base fraîche,
/// `ref_cours` est tiré indépendamment du pull des classes, lequel échoue tant
/// que le référentiel Inscription n'a pas atterri — la fenêtre est donc
/// systématique, et permanente pour un rôle qui aurait `academics.course.read`
/// sans `classroom.read`. Dans ce cas la vue bascule en **repli** : tout est
/// rendu, la classe est nommée « non synchronisée » plutôt qu'anonyme, et le
/// bandeau explique pourquoi les effectifs manquent.
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
    //
    // ⚠️ La comparaison porte sur les classes VISIBLES, pas sur la liste
    // reçue : une classe dont le pull vient d'atterrir passe de masquée à
    // visible sans changer ni la longueur ni les ids de `courses`. Comparée
    // sur la liste brute, elle serait rendue repliée — seule de son écran, et
    // contre la règle « toutes dépliées par défaut » — tout en faisant
    // basculer l'en-tête sur « Tout déplier » alors que le reste est ouvert.
    if (!_sameIds(_resolve(oldWidget.courses).shown, _visible)) {
      _expandedIds = _allIds();
    }
  }

  /// Les classes à rendre, et si l'on est en repli (cf. l'entête de classe).
  ({List<CourseSummary> shown, bool degraded}) get _resolved =>
      _resolve(widget.courses);

  static ({List<CourseSummary> shown, bool degraded}) _resolve(
    List<CourseSummary> courses,
  ) {
    final synced = courses
        .where((course) => !course.classroomUnsynced)
        .toList(growable: false);
    if (synced.isEmpty && courses.isNotEmpty) {
      return (shown: courses, degraded: true);
    }
    return (shown: synced, degraded: false);
  }

  /// Les classes réellement affichables, dans l'ordre reçu.
  List<CourseSummary> get _visible => _resolved.shown;

  /// Nombre de cours masqués faute de leur classe — **zéro en repli**, où plus
  /// rien n'est masqué.
  int get _pendingCourseCount => _resolved.degraded
      ? 0
      : widget.courses
            .where((course) => course.classroomUnsynced)
            .fold(0, (sum, course) => sum + course.courses.length);

  Set<String> _allIds() =>
      _visible.map((course) => course.classroom.id).toSet();

  bool _sameIds(List<CourseSummary> a, List<CourseSummary> b) {
    if (a.length != b.length) return false;
    final idsB = b.map((course) => course.classroom.id).toSet();
    return a.every((course) => idsB.contains(course.classroom.id));
  }

  bool get _allExpanded =>
      _visible.isNotEmpty && _expandedIds.length == _visible.length;

  /// Le compteur ne parle que de ce qui est à l'écran : annoncer des cours
  /// qu'on masque serait un compte que l'utilisateur ne peut pas vérifier.
  int get _totalCourses =>
      _visible.fold(0, (sum, course) => sum + course.courses.length);

  void _toggleAll() {
    setState(() {
      _expandedIds = _allExpanded ? <String>{} : _allIds();
    });
  }

  /// Le même groupe, sa classe portant un nom lisible. Utilisé en repli
  /// seulement — ailleurs la classe est en cache et porte son vrai nom.
  static CourseSummary _named(CourseSummary group, String name) =>
      CourseSummary(
        classroom: ClassroomSummary(
          id: group.classroom.id,
          schoolLevelId: group.classroom.schoolLevelId,
          name: name,
          capacity: group.classroom.capacity,
          totalCount: group.classroom.totalCount,
          femaleCount: group.classroom.femaleCount,
          maleCount: group.classroom.maleCount,
        ),
        courses: group.courses,
        classroomUnsynced: group.classroomUnsynced,
      );

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

    final resolved = _resolved;
    final degraded = resolved.degraded;
    // En repli, la classe est nommée plutôt qu'anonyme : une carte sans titre
    // aux effectifs à zéro se lit comme une classe vide, ce qui est faux — la
    // classe existe, c'est son pull qui n'a pas abouti. Le libellé vit ici et
    // non dans le repository : c'est une chaîne d'interface (règle #4).
    final visible = degraded
        ? [
            for (final group in resolved.shown)
              group.classroomUnsynced
                  ? _named(group, l10n.myCoursesUnsyncedClassroomName)
                  : group,
          ]
        : resolved.shown;
    final pending = _pendingCourseCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListHeader(
          counterLabel: l10n.myCoursesCount(visible.length, _totalCourses),
          allExpanded: _allExpanded,
          onToggleAll: _toggleAll,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < visible.length; i++) ...[
          MyCoursesClassAccordion(
            group: visible[i],
            visual: AcademicsClassVisual.forIndex(i),
            expanded: _expandedIds.contains(visible[i].classroom.id),
            onToggle: () => _toggleOne(visible[i].classroom.id),
            onOpenCourse: widget.onOpenCourse,
          ),
          if (i != visible.length - 1) const SizedBox(height: AppSpacing.md),
        ],
        if (degraded) ...[
          const SizedBox(height: AppSpacing.lg),
          _UnsyncedClassroomNotice(
            label: l10n.myCoursesDegradedClassroomNotice(_totalCourses),
          ),
        ] else if (pending > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          _UnsyncedClassroomNotice(
            label: l10n.myCoursesUnsyncedClassroomNotice(pending),
          ),
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

/// Mention de pied de liste : des cours existent, mais leur classe n'est pas
/// encore descendue. Discrète — c'est un retard de synchro, pas une erreur.
class _UnsyncedClassroomNotice extends StatelessWidget {
  final String label;

  const _UnsyncedClassroomNotice({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
