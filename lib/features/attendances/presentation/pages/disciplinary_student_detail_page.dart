import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_tab.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_detail_back_button.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_tabs.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_student_compact_header.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/student_attendance_summary_tab.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Coquille de la fiche élève (Liste disciplines ▸ détail) : fil d'Ariane,
/// en-tête d'identité, barre d'onglets `DossierTabs` (Discipline puis Présence)
/// et panneau teinté de l'onglet actif. Le contenu des onglets vit dans leurs
/// specs respectives (cas disciplinaires / synthèse de présence).
class DisciplinaryStudentDetailPage extends StatefulWidget {
  final DisciplinaryStudentDetailIntent intent;

  const DisciplinaryStudentDetailPage({super.key, required this.intent});

  @override
  State<DisciplinaryStudentDetailPage> createState() =>
      _DisciplinaryStudentDetailPageState();
}

class _DisciplinaryStudentDetailPageState
    extends State<DisciplinaryStudentDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppMotion.outCurve,
    );
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fadeController.forward();
      context.read<DisciplinaryCaseBloc>().add(
        DisciplinaryCaseListRequested(
          studentId: widget.intent.studentId,
          academicYearId: widget.intent.academicYearId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intent = widget.intent;

    if (!intent.hasDisplayContext) {
      return _buildContextError(context, l10n);
    }

    return AppPageBackground(
      scrollable: false,
      // Pas d'AppBar : la coquille porte son propre fil d'Ariane (spec §1).
      // SafeArea protège le haut du contenu (statut système) faute d'AppBar.
      child: SafeArea(
        top: true,
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(context, l10n),
              const SizedBox(height: AppDimensions.spacingS),
              BlocBuilder<DisciplinaryCaseBloc, DisciplinaryCaseState>(
                buildWhen: (prev, curr) =>
                    prev.listStatus != curr.listStatus ||
                    prev.cases != curr.cases,
                builder: (context, state) {
                  // Compte connu seulement une fois la liste chargée (sinon le
                  // chip afficherait « Aucun cas ouvert » pendant le chargement).
                  final int? openCount =
                      state.listStatus == DisciplinaryCaseStatusState.success
                      ? _openCasesCount(state)
                      : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DisciplinaryStudentCompactHeader(
                        studentId: intent.studentId,
                        firstName: intent.studentFirstName,
                        lastName: intent.studentLastName,
                        middleName: intent.studentMiddleName,
                        gender: intent.studentGender,
                        levelName: intent.levelName,
                        classroomName: intent.classroomName,
                        openCasesCount: openCount,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      DisciplinaryDossierTabs(
                        controller: _tabController,
                        openCasesCount: openCount ?? 0,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spacingM),
              // Le contenu des onglets s'affiche directement sur le fond décoré
              // standard de la page (halos + motif), comme les autres pages :
              // plus de panneau peignant un fond plein qui le masquerait.
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    DisciplinaryCasesTab(
                      studentId: intent.studentId,
                      academicYearId: intent.academicYearId,
                      onCreateCase: () => _showCreateDialog(context),
                    ),
                    StudentAttendanceSummaryTab(studentId: intent.studentId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _openCasesCount(DisciplinaryCaseState state) => state.cases
      .where(
        (c) =>
            c.status == DisciplinaryCaseStatus.open ||
            c.status == DisciplinaryCaseStatus.inProgress,
      )
      .length;

  /// Fil d'Ariane : lien-retour texte coloré (terre-cuite) vers l'annuaire.
  Widget _buildBreadcrumb(BuildContext context, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _goBack(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terreCuite,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXS,
          ),
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: Text(
          l10n.disciplinaryFolderBreadcrumb,
          style: AppTextStyles.action.copyWith(color: AppColors.terreCuite),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutesNames.presences);
  }

  Widget _buildContextError(BuildContext context, AppLocalizations l10n) {
    return AppPageBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_problem_outlined,
              size: 40,
              color: AppColors.warning.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.disciplinaryDetailContextErrorTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.disciplinaryDetailContextErrorMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          DisciplinaryDetailBackButton(
            label: l10n.disciplinaryDetailBackLabel,
            fallbackRoute: AppRoutesNames.presences,
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final disciplinaryCaseBloc = context.read<DisciplinaryCaseBloc>();
    final studentId = widget.intent.studentId;
    final academicYearId = widget.intent.academicYearId;

    showDialog(
      context: context,
      builder: (context) => BlocProvider<DisciplinaryCaseBloc>.value(
        value: disciplinaryCaseBloc,
        child: DisciplinaryCaseCreateDialog(
          studentId: studentId,
          studentFirstName: widget.intent.studentFirstName,
          studentLastName: widget.intent.studentLastName,
          studentMiddleName: widget.intent.studentMiddleName,
          studentGender: widget.intent.studentGender,
          academicYearId: academicYearId,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      disciplinaryCaseBloc.add(
        DisciplinaryCaseListRequested(
          studentId: studentId,
          academicYearId: academicYearId,
        ),
      );
    });
  }
}
