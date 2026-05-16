import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_tab.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_detail_back_button.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_student_compact_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class DisciplinaryStudentDetailPage extends StatefulWidget {
  final DisciplinaryStudentDetailIntent intent;

  const DisciplinaryStudentDetailPage({super.key, required this.intent});

  @override
  State<DisciplinaryStudentDetailPage> createState() =>
      _DisciplinaryStudentDetailPageState();
}

class _DisciplinaryStudentDetailPageState
    extends State<DisciplinaryStudentDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intent = widget.intent;

    if (!intent.hasDisplayContext) {
      return _buildContextError(context, l10n);
    }

    return DefaultTabController(
      length: 2,
      child: AppPageBackground(
        scrollable: false,
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.disciplinaryDetailBackLabel,
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width:
                    AppDimensions.detailMiniIconSize + AppDimensions.spacingM,
                height:
                    AppDimensions.detailMiniIconSize + AppDimensions.spacingM,
                decoration: BoxDecoration(
                  color: AppColors.bleuArdoise.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.bleuArdoise,
                  size: AppDimensions.detailMiniIconSize,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.disciplinaryFollowUpTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontFamily: 'Lora',
                        color: AppColors.bleuArdoise,
                      ),
                    ),
                    Text(
                      _buildAppBarSubtitle(intent, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DisciplinaryStudentCompactHeader(
                firstName: intent.studentFirstName,
                lastName: intent.studentLastName,
                middleName: intent.studentMiddleName,
                cycleName: intent.levelGroupName,
                levelName: intent.levelName,
                classroomName: intent.classroomName,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TabBar(
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.action,
                indicatorColor: AppColors.terreCuite,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l10n.disciplinaryTabCasesLabel),
                  Tab(text: l10n.disciplinaryTabAttendanceHistoryLabel),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Expanded(
                child: TabBarView(
                  children: [
                    DisciplinaryCasesTab(
                      studentId: intent.studentId,
                      academicYearId: intent.academicYearId,
                      onCreateCase: () => _showCreateDialog(context),
                    ),
                    _AttendanceHistoryPlaceholder(
                      message: l10n.disciplinaryAttendanceHistoryComingSoon,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  String _buildAppBarSubtitle(
    DisciplinaryStudentDetailIntent intent,
    AppLocalizations l10n,
  ) {
    final fullName = [
      intent.studentLastName,
      intent.studentMiddleName,
      intent.studentFirstName,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ');
    final classroom = intent.classroomName.trim().isEmpty
        ? l10n.disciplinaryUnknownValue
        : intent.classroomName.trim();
    return '$fullName - $classroom';
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

class _AttendanceHistoryPlaceholder extends StatelessWidget {
  final String message;

  const _AttendanceHistoryPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
