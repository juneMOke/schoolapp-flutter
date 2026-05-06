import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_student_hero_card.dart';
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

    return AppPageBackground(
      scrollable: false,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact =
                constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
            final blockSpacing = isCompact
                ? AppDimensions.spacingM
                : AppDimensions.detailSectionSpacing;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Semantics(
                  label: l10n.disciplinaryDetailBackLabel,
                  button: true,
                  child: DisciplinaryDetailBackButton(
                    label: l10n.disciplinaryDetailBackLabel,
                    fallbackRoute: AppRoutesNames.presences,
                  ),
                ),
                SizedBox(height: blockSpacing),

                // Hero card
                DisciplinaryStudentHeroCard(
                  unknownValue: '-',
                  firstName: intent.studentFirstName,
                  lastName: intent.studentLastName,
                  middleName: intent.studentMiddleName,
                  levelName: intent.levelName,
                  levelGroupName: intent.levelGroupName,
                  levelLabel: l10n.facturationDetailStudentLevel,
                  levelGroupLabel: l10n.facturationDetailStudentLevelGroup,
                ),
                SizedBox(height: blockSpacing),

                // Toolbar : chip discipline + bouton créer
                _buildToolbar(context, l10n, isCompact: isCompact),
                SizedBox(height: blockSpacing),

                // Liste des cas — prend tout l'espace restant
                Expanded(
                  child: DisciplinaryCasesTab(
                    studentId: intent.studentId,
                    academicYearId: intent.academicYearId,
                    onCreateCase: () => _showCreateDialog(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isCompact,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.disciplinaryDetailAccentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(
          color: AppColors.disciplinaryDetailAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.policy_outlined,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.disciplinaryDetailAccent,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            l10n.disciplinaryHeroChipCases,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.disciplinaryDetailAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final createButton = Semantics(
      label: l10n.disciplinaryCaseCreateAction,
      button: true,
      child: FilledButton.icon(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.disciplinaryCaseCreateAction),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.disciplinaryDetailAccent,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.classesDisabledBg,
          disabledForegroundColor: AppColors.classesDisabledFg,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          minimumSize: const Size(
            AppDimensions.minTouchTarget,
            AppDimensions.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          ),
          textStyle: AppTextStyles.action,
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chip,
          const SizedBox(height: AppDimensions.spacingS),
          createButton,
        ],
      );
    }

    return Row(
      children: [
        chip,
        const Spacer(),
        createButton,
      ],
    );
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