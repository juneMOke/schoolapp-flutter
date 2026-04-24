import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const double _summaryCompactBreakpoint = 760;
const int _summaryGuardianPreviewMaxCompact = 2;
const int _summaryGuardianPreviewMaxDesktop = 3;

class SummaryStep extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;

  const SummaryStep({super.key, required this.enrollmentDetail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildSummaryCards(context, l10n),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final student = enrollmentDetail.studentDetail;
    final location = [student.city, student.district]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.indigo,
            AppColors.indigoDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _summaryCompactBreakpoint;
          final identityInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.summary,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                '${student.firstName} ${student.lastName}'.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (student.surname.trim().isNotEmpty)
                Text(
                  student.surname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );

          final statusBadge = EnrollmentStatusBadge(
            status: enrollmentDetail.enrollmentDetail.status,
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StudentAvatar(
                      firstName: student.firstName,
                      lastName: student.lastName,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(child: identityInfo),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                statusBadge,
              ],
            );
          }

          return Row(
            children: [
              StudentAvatar(
                firstName: student.firstName,
                lastName: student.lastName,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: identityInfo),
              const SizedBox(width: AppDimensions.spacingM),
              statusBadge,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _summaryCompactBreakpoint;

        if (isCompact) {
          return Column(
            children: [
              _buildPersonalInfoCard(context, l10n),
              const SizedBox(height: AppDimensions.spacingM),
              _buildAcademicInfoCard(context, l10n),
              const SizedBox(height: AppDimensions.spacingM),
              _buildTargetAcademicInfoCard(context, l10n),
              const SizedBox(height: AppDimensions.spacingM),
              _buildGuardianInfoCard(
                context,
                l10n,
                maxGuardians: _summaryGuardianPreviewMaxCompact,
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildDesktopSummaryRow(
              left: _buildPersonalInfoCard(context, l10n),
              right: _buildAcademicInfoCard(context, l10n),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildDesktopSummaryRow(
              left: _buildTargetAcademicInfoCard(context, l10n),
              right: _buildGuardianInfoCard(
                context,
                l10n,
                maxGuardians: _summaryGuardianPreviewMaxDesktop,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopSummaryRow({
    required Widget left,
    required Widget right,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, AppLocalizations l10n) {
    final student = enrollmentDetail.studentDetail;

    return _SummaryCard(
      title: l10n.personalInformation,
      icon: Icons.person_outline,
      color: AppColors.indigo,
      children: [
        _SummaryItem(
          label: l10n.dateOfBirth,
          value: '${student.dateOfBirth} - ${student.birthPlace}',
        ),
        _SummaryItem(label: l10n.nationality, value: student.nationality),
        _SummaryItem(
          label: l10n.address,
          value: '${student.city}, ${student.district}',
        ),
      ],
    );
  }

  Widget _buildAcademicInfoCard(BuildContext context, AppLocalizations l10n) {
    final enrollment = enrollmentDetail.enrollmentDetail;

    return _SummaryCard(
      title: l10n.previousYear,
      icon: Icons.school_outlined,
      color: AppColors.indigoDark,
      children: [
        _SummaryItem(
          label: l10n.schoolLabel,
          value: enrollment.previousSchoolName,
        ),
        _SummaryItem(
          label: l10n.schoolCycle,
          value: enrollment.previousSchoolLevelGroup,
        ),
        _SummaryItem(
          label: l10n.schoolLevelLabel,
          value: enrollment.previousSchoolLevel,
        ),
        _SummaryItem(
          label: l10n.averageLabel,
          value: '${enrollment.previousRate}/20',
        ),
        _SummaryItem(
          label: l10n.confirm,
          value: enrollment.validatedPreviousYear ? l10n.confirm : l10n.cancel,
          valueColor: enrollment.validatedPreviousYear
              ? AppColors.green
              : AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildTargetAcademicInfoCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final student = enrollmentDetail.studentDetail;
    final enrollment = enrollmentDetail.enrollmentDetail;
    final targetGroupId = enrollment.schoolLevelGroupId.trim().isNotEmpty
        ? enrollment.schoolLevelGroupId
        : student.schoolLevelGroup.id;
    final targetLevelId = enrollment.schoolLevelId.trim().isNotEmpty
        ? enrollment.schoolLevelId
        : student.schoolLevel.id;

    return BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
      builder: (context, state) {
        final bootstrap = state.bootstrap;
        final resolvedGroupName = _resolveTargetGroupName(
          bootstrap: bootstrap,
          groupId: targetGroupId,
          fallbackName: student.schoolLevelGroup.name,
        );
        final resolvedLevelName = _resolveTargetLevelName(
          bootstrap: bootstrap,
          groupId: targetGroupId,
          levelId: targetLevelId,
          fallbackName: student.schoolLevel.name,
        );

        return _SummaryCard(
          title: l10n.targetYear,
          icon: Icons.flag_outlined,
          color: AppColors.indigo,
          children: [
            _SummaryItem(
              label: l10n.targetCycleLabel,
              value: _fallbackValue(resolvedGroupName),
            ),
            _SummaryItem(
              label: l10n.targetLevelLabel,
              value: _fallbackValue(resolvedLevelName),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuardianInfoCard(
    BuildContext context,
    AppLocalizations l10n, {
    int maxGuardians = _summaryGuardianPreviewMaxDesktop,
  }) {
    final parents = enrollmentDetail.parentDetails;
    final visibleParents = parents.take(maxGuardians).toList();
    final remainingCount = parents.length - visibleParents.length;

    return _SummaryCard(
      title: l10n.guardianInformation,
      icon: Icons.family_restroom,
      color: AppColors.green,
      children: parents.isEmpty
          ? [const _SummaryItem(label: '-', value: '-')]
          : [
                ...visibleParents
                .map(
                  (parent) => _SummaryItem(
                    label: _getRelationshipLabel(parent.relationshipType, l10n),
                    value:
                        _fallbackValue('${parent.firstName} ${parent.lastName}'),
                    subtitle: [parent.phoneNumber, parent.email]
                        .map((value) => value.trim())
                        .where((value) => value.isNotEmpty)
                        .join(' • '),
                  ),
                ),
                if (remainingCount > 0)
                  _SummaryItem(
                    label: l10n.guardianInformation,
                    value: '+$remainingCount',
                  ),
              ],
    );
  }

  String _getRelationshipLabel(RelationshipType type, AppLocalizations l10n) {
    return switch (type) {
      RelationshipType.father => l10n.relationshipFather,
      RelationshipType.mother => l10n.relationshipMother,
      RelationshipType.guardian => l10n.relationshipGuardian,
      RelationshipType.other => l10n.relationshipOther,
      RelationshipType.uncle => l10n.relationshipUncle,
      RelationshipType.aunt => l10n.relationshipAunt,
      RelationshipType.grandparent => l10n.relationshipGrandparent,
    };
  }

  String _fallbackValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _resolveTargetGroupName({
    required dynamic bootstrap,
    required String groupId,
    required String fallbackName,
  }) {
    final candidate = fallbackName.trim();
    if (candidate.isNotEmpty) return candidate;

    final id = groupId.trim();
    if (id.isEmpty) return '';

    if (bootstrap != null) {
      for (final bundle in bootstrap.schoolLevelGroups) {
        if (bundle.schoolLevelGroup.id == id) {
          final name = bundle.schoolLevelGroup.name.trim();
          if (name.isNotEmpty) return name;
          break;
        }
      }
    }

    // Fallback ultime: afficher l'id évite une carte vide.
    return id;
  }

  String _resolveTargetLevelName({
    required dynamic bootstrap,
    required String groupId,
    required String levelId,
    required String fallbackName,
  }) {
    final candidate = fallbackName.trim();
    if (candidate.isNotEmpty) return candidate;

    final group = groupId.trim();
    final level = levelId.trim();
    if (level.isEmpty) return '';

    if (bootstrap != null) {
      for (final groupBundle in bootstrap.schoolLevelGroups) {
        if (group.isNotEmpty && groupBundle.schoolLevelGroup.id != group) {
          continue;
        }

        for (final levelBundle in groupBundle.schoolLevels) {
          if (levelBundle.schoolLevel.id == level) {
            final name = levelBundle.schoolLevel.name.trim();
            if (name.isNotEmpty) return name;
            return level;
          }
        }
      }
    }

    return level;
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingS,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.spacingS),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
