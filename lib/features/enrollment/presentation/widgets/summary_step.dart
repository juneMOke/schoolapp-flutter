import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryStep extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;

  const SummaryStep({super.key, required this.enrollmentDetail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildSummaryCards(context, l10n),
        const SizedBox(height: 24),
        _buildActions(context, l10n),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final student = enrollmentDetail.studentDetail;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.largePadding),
        child: Row(
          children: [
            StudentAvatar(
              firstName: student.firstName,
              lastName: student.lastName,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.firstName} ${student.lastName}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (student.surname.isNotEmpty)
                    Text(
                      student.surname,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        enrollmentDetail.enrollmentDetail.enrollmentCode,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            EnrollmentStatusBadge(
              status: enrollmentDetail.enrollmentDetail.status,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPersonalInfoCard(context, l10n)),
            const SizedBox(width: 16),
            Expanded(child: _buildAcademicInfoCard(context, l10n)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGuardianInfoCard(context, l10n)),
            const SizedBox(width: 16),
            Expanded(child: _buildNextStepsCard(context, l10n)),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, AppLocalizations l10n) {
    final student = enrollmentDetail.studentDetail;

    return _SummaryCard(
      title: l10n.personalInformation,
      icon: Icons.person_outline,
      color: AppTheme.primaryColor,
      children: [
        _SummaryItem(
          label: 'Naissance',
          value: '${student.dateOfBirth} - ${student.birthPlace}',
        ),
        _SummaryItem(label: 'Nationalité', value: student.nationality),
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
      title: 'Parcours académique',
      icon: Icons.school_outlined,
      color: Colors.blue[600]!,
      children: [
        _SummaryItem(
          label: 'École précédente',
          value: enrollment.previousSchoolName,
        ),
        _SummaryItem(
          label: 'Dernière moyenne',
          value: '${enrollment.previousRate}/20',
        ),
        _SummaryItem(
          label: 'Année validée',
          value: enrollment.validatedPreviousYear ? 'Oui' : 'Non',
          valueColor: enrollment.validatedPreviousYear
              ? Colors.green
              : Colors.red,
        ),
      ],
    );
  }

  Widget _buildGuardianInfoCard(BuildContext context, AppLocalizations l10n) {
    final parents = enrollmentDetail.parentDetails;

    return _SummaryCard(
      title: l10n.guardianInformation,
      icon: Icons.family_restroom,
      color: Colors.purple[600]!,
      children: parents
          .map(
            (parent) => _SummaryItem(
              label: _getRelationshipLabel(parent.relationshipType),
              value: '${parent.firstName} ${parent.lastName}',
              subtitle: parent.phoneNumber,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNextStepsCard(BuildContext context, AppLocalizations l10n) {
    return _SummaryCard(
      title: 'Prochaines étapes',
      icon: Icons.assignment_outlined,
      color: Colors.green[600]!,
      children: [
        _SummaryItem(
          label: 'Documents requis',
          value: 'Certificats, bulletins',
          action: TextButton(onPressed: () {}, child: const Text('Voir liste')),
        ),
        _SummaryItem(
          label: 'Frais d\'inscription',
          value: 'À définir selon le niveau',
          action: TextButton(onPressed: () {}, child: const Text('Calculer')),
        ),
        _SummaryItem(
          label: 'Validation finale',
          value: 'En attente administration',
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.largePadding),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportToPdf(),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exporter PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _validateEnrollment(),
                icon: const Icon(Icons.check_circle),
                label: const Text('Valider l\'inscription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRelationshipLabel(RelationshipType type) {
    return switch (type) {
      RelationshipType.father => 'Père',
      RelationshipType.mother => 'Mère',
      RelationshipType.guardian => 'Tuteur',
      RelationshipType.other => 'Autre',
      // TODO: Handle this case.
      RelationshipType.uncle => throw UnimplementedError(),
      // TODO: Handle this case.
      RelationshipType.aunt => throw UnimplementedError(),
      // TODO: Handle this case.
      RelationshipType.grandparent => throw UnimplementedError(),
    };
  }

  void _exportToPdf() {
    // TODO: Implement PDF export
  }

  void _validateEnrollment() {
    // TODO: Implement enrollment validation
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
  final Widget? action;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
