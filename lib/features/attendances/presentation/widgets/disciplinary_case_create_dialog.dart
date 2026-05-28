import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/disciplinary_case_helpers.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_dialog_shell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryCaseCreateDialog extends StatefulWidget {
  final String studentId;
  final String academicYearId;

  const DisciplinaryCaseCreateDialog({
    super.key,
    required this.studentId,
    required this.academicYearId,
  });

  @override
  State<DisciplinaryCaseCreateDialog> createState() =>
      _DisciplinaryCaseCreateDialogState();
}

class _DisciplinaryCaseCreateDialogState
    extends State<DisciplinaryCaseCreateDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _selectedDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final baseTheme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final themed = baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: AppColors.disciplinaryDetailAccent,
            onPrimary: AppColors.surface,
            onSurface: AppColors.textPrimary,
            surface: AppColors.surface,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.sectionCardRadius,
              ),
            ),
            headerBackgroundColor: AppColors.disciplinaryDetailAccentSoft,
            headerForegroundColor: AppColors.disciplinaryDetailAccent,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.surface;
              }
              return AppColors.textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.disciplinaryDetailAccent;
              }
              return null;
            }),
            todayForegroundColor: const WidgetStatePropertyAll(
              AppColors.disciplinaryDetailAccent,
            ),
            todayBackgroundColor: const WidgetStatePropertyAll(
              AppColors.disciplinaryDetailAccentSoft,
            ),
            dayStyle: AppTextStyles.body,
            yearStyle: AppTextStyles.body,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.disciplinaryDetailAccent,
              textStyle: AppTextStyles.action,
            ),
          ),
        );

        return Theme(data: themed, child: child);
      },
    );
    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<DisciplinaryCaseBloc>().add(
      DisciplinaryCaseCreateRequested(
        studentId: widget.studentId,
        studentFirstName: '',
        studentLastName: '',
        studentMiddleName: null,
        studentGender: StudentGender.other,
        disciplinaryCaseDate: _selectedDate,
        academicYearId: widget.academicYearId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DisciplinaryCaseDialogShell(
      maxWidth: 500,
      child: BlocListener<DisciplinaryCaseBloc, DisciplinaryCaseState>(
        listenWhen: (prev, curr) => prev.createStatus != curr.createStatus,
        listener: (context, state) {
          if (state.createStatus == DisciplinaryCaseStatusState.success) {
            AppSnackBar.showSuccess(
              context,
              l10n.disciplinaryCaseCreateDialogSuccessMessage,
            );
            Navigator.pop(context);
            return;
          }

          if (state.createStatus == DisciplinaryCaseStatusState.failure) {
            AppSnackBar.showError(
              context,
              DisciplinaryCaseHelpers.mapErrorType(l10n, state.createErrorType),
            );
          }
        },
        child: BlocBuilder<DisciplinaryCaseBloc, DisciplinaryCaseState>(
          buildWhen: (prev, curr) => prev.createStatus != curr.createStatus,
          builder: (context, state) => _buildForm(context, l10n, state),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    DisciplinaryCaseState state,
  ) {
    final isLoading = state.createStatus == DisciplinaryCaseStatusState.loading;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildHeader(context, l10n, isLoading),
        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.disciplinaryCaseCreateDialogTitleField,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  TextFormField(
                    controller: _titleController,
                    enabled: !isLoading,
                    decoration: _inputDecoration(
                      labelText: l10n.disciplinaryCaseCreateDialogTitleField,
                      hintText: l10n.disciplinaryCaseCreateDialogTitleHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n
                            .disciplinaryCaseCreateDialogRequiredFieldError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    l10n.disciplinaryCaseCreateDialogContentField,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  TextFormField(
                    controller: _contentController,
                    enabled: !isLoading,
                    decoration: _inputDecoration(
                      labelText: l10n.disciplinaryCaseCreateDialogContentField,
                      hintText: l10n.disciplinaryCaseCreateDialogContentHint,
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n
                            .disciplinaryCaseCreateDialogRequiredFieldError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    l10n.disciplinaryCaseCreateDialogCaseDateField,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    curve: AppMotion.outCurve,
                    opacity: isLoading ? 0.65 : 1,
                    child: InkWell(
                      onTap: isLoading ? null : () => _selectDate(context),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                      child: AnimatedContainer(
                        duration: AppMotion.medium,
                        curve: AppMotion.outCurve,
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.disciplinaryDetailAccentSoft,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.spacingM,
                          ),
                          border: Border.all(
                            color: AppColors.disciplinaryDetailAccent
                                .withValues(alpha: isLoading ? 0.12 : 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: AppDimensions.detailMiniIconSize,
                              color: AppColors.disciplinaryDetailAccent,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: AppMotion.fast,
                                switchInCurve: AppMotion.outCurve,
                                switchOutCurve: AppMotion.inCurve,
                                child: Text(
                                  _formatSelectedDate(context),
                                  key: ValueKey(_selectedDate),
                                  style: AppTextStyles.bodyStrong.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.expand_more_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                label: l10n.cancel,
                button: true,
                child: TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: AppTextStyles.action.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Semantics(
                label: l10n.disciplinaryCaseCreateDialogSubmitAction,
                button: true,
                enabled: !isLoading,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.disciplinaryDetailAccent,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                    ),
                  ),
                  onPressed: isLoading ? null : () => _submit(context),
                  icon: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.outCurve,
                    switchOutCurve: AppMotion.inCurve,
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('loading-icon'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.surface,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.add_task_outlined,
                            key: ValueKey('submit-icon'),
                          ),
                  ),
                  label: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.outCurve,
                    switchOutCurve: AppMotion.inCurve,
                    child: Text(
                      isLoading
                          ? l10n.disciplinaryCaseCreateDialogCreatingMessage
                          : l10n.disciplinaryCaseCreateDialogSubmitAction,
                      key: ValueKey(isLoading),
                      style: AppTextStyles.action,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.disciplinaryDetailAccentSoft,
            AppColors.disciplinaryDetailTealSoft,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.sectionCardRadius),
          topRight: Radius.circular(AppDimensions.sectionCardRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.spacingXL + AppDimensions.spacingXS,
            height: AppDimensions.spacingXL + AppDimensions.spacingXS,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            ),
            child: const Icon(
              Icons.gavel_outlined,
              size: AppDimensions.detailHeaderIconSize,
              color: AppColors.disciplinaryDetailAccent,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.disciplinaryCaseCreateDialogTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.disciplinaryDetailAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        borderSide: const BorderSide(color: AppColors.disciplinaryDetailAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingM,
      ),
    );
  }

  String _formatSelectedDate(BuildContext context) =>
      MaterialLocalizations.of(context).formatMediumDate(_selectedDate);
}
