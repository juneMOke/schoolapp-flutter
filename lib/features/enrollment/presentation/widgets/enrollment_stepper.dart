import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_tep.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/summary_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStepper extends StatefulWidget {
  final EnrollmentDetail enrollmentDetail;

  const EnrollmentStepper({super.key, required this.enrollmentDetail});

  @override
  State<EnrollmentStepper> createState() => _EnrollmentStepperState();
}

class _EnrollmentStepperState extends State<EnrollmentStepper> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepTitles = _stepTitles(l10n);
    final stepSubtitles = _stepSubtitles(l10n);
    final steps = _stepContents();
    final progress = (_currentStep + 1) / stepTitles.length;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WizardBreadcrumb(
            titles: stepTitles,
            currentStep: _currentStep,
            progress: progress,
            onStepTap: _onBreadcrumbStepTap,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _StepPageCard(
              key: ValueKey(_currentStep),
              title: stepTitles[_currentStep],
              subtitle: stepSubtitles[_currentStep],
              child: _buildStepContent(steps[_currentStep]),
            ),
          ),
          const SizedBox(height: 12),
          _buildControls(context),
        ],
      ),
    );
  }

  List<String> _stepTitles(AppLocalizations l10n) {
    return [
      l10n.personalInformation,
      l10n.address,
      '${l10n.previousYear} / ${l10n.targetYear}',
      l10n.guardianInformation,
      l10n.summary,
    ];
  }

  List<String> _stepSubtitles(AppLocalizations l10n) {
    return [
      l10n.stepPersonalInfoSubtitle,
      l10n.stepAddressSubtitle,
      l10n.stepAcademicSubtitle,
      l10n.stepGuardianSubtitle,
      l10n.stepSummarySubtitle,
    ];
  }

  List<Widget> _stepContents() {
    return [
      PersonalInfoStep(studentDetail: widget.enrollmentDetail.studentDetail),
      AddressStep(studentDetail: widget.enrollmentDetail.studentDetail),
      AcademicInfoStep(enrollmentDetail: widget.enrollmentDetail.enrollmentDetail),
      GuardianInfoStep(parentDetails: widget.enrollmentDetail.parentDetails),
      SummaryStep(enrollmentDetail: widget.enrollmentDetail),
    ];
  }

  void _onBreadcrumbStepTap(int targetStep) {
    if (targetStep <= _currentStep) {
      setState(() => _currentStep = targetStep);
      _resetContentScroll();
      return;
    }
    _showHint(AppLocalizations.of(context)!.stepForwardHint);
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;
    final student = widget.enrollmentDetail.studentDetail;
    final enrollment = widget.enrollmentDetail.enrollmentDetail;
    final parents = widget.enrollmentDetail.parentDetails;

    switch (_currentStep) {
      case 0:
        final ok = student.firstName.trim().isNotEmpty &&
            student.lastName.trim().isNotEmpty &&
            student.dateOfBirth.toString().trim().isNotEmpty;
        if (!ok) _showHint(l10n.validatePersonalInfoHint);
        return ok;
      case 1:
        final ok = student.city.trim().isNotEmpty &&
            student.district.trim().isNotEmpty &&
            student.municipality.trim().isNotEmpty &&
            student.address.trim().isNotEmpty;
        if (!ok) _showHint(l10n.validateAddressHint);
        return ok;
      case 2:
        final ok = enrollment.previousAcademicYear.trim().isNotEmpty &&
            enrollment.previousSchoolName.trim().isNotEmpty &&
            enrollment.previousSchoolLevel.trim().isNotEmpty;
        if (!ok) _showHint(l10n.validateAcademicInfoHint);
        return ok;
      case 3:
        final ok = parents.isNotEmpty &&
            parents.every(
              (p) => p.firstName.trim().isNotEmpty &&
                  p.lastName.trim().isNotEmpty &&
                  p.phoneNumber.trim().isNotEmpty,
            );
        if (!ok) _showHint(l10n.validateGuardianInfoHint);
        return ok;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _currentStep == 4;

    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep -= 1),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(l10n.previous),
          ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            if (!_validateCurrentStep()) return;

            if (isLast) {
              _showHint(l10n.enrollmentReadyForValidation);
              return;
            }

            setState(() => _currentStep += 1);
            _resetContentScroll();
          },
          icon: Icon(
            isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
            size: 16,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          label: Text(isLast ? l10n.finish : l10n.next),
        ),
      ],
    );
  }

  void _resetContentScroll() {
    // Le scroll est maintenant géré par le SingleChildScrollView parent.
  }

  Widget _buildStepContent(Widget stepContent) {
    return stepContent;
  }
}

class _WizardBreadcrumb extends StatelessWidget {
  final List<String> titles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;

  const _WizardBreadcrumb({
    required this.titles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.stepIndicator(
                  currentStep + 1,
                  titles.length,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: List.generate(titles.length, (index) {
              final isDone = index < currentStep;
              final isCurrent = index == currentStep;
              final isFuture = index > currentStep;
              final canTap = !isFuture;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: canTap
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.forbidden,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: isFuture ? 0.55 : 1,
                      child: InkWell(
                        onTap: canTap ? () => onStepTap(index) : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primaryColor
                                : isDone
                                ? AppTheme.primaryColor.withValues(alpha: 0.14)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : isDone
                                      ? AppTheme.primaryColor.withValues(
                                          alpha: 0.18,
                                        )
                                      : const Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  isDone ? '✓' : '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent
                                        ? Colors.white
                                        : isDone
                                        ? AppTheme.primaryColor
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                titles[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? Colors.white
                                      : isDone
                                      ? AppTheme.primaryColor
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index < titles.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepPageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepPageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
        ],
      ),
    );
  }
}