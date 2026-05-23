import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';

/// Implémentation de [DataTableRow] pour les résumés d'inscription.
/// 
/// Convertit un [EnrollmentSummary] domain en ligne displayable.
class EnrollmentSummaryRow implements DataTableRow {
  final EnrollmentSummary enrollment;
  final core_avatar.AvatarVariant avatarVariant;
  final String Function(String)? dateFormatter;

  EnrollmentSummaryRow({
    required this.enrollment,
    this.avatarVariant = core_avatar.AvatarVariant.outlined,
    this.dateFormatter,
  });

  String get _formattedDate {
    if (dateFormatter != null) {
      return dateFormatter!(enrollment.student.dateOfBirth);
    }
    try {
      final p = enrollment.student.dateOfBirth.split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    } catch (_) {}
    return enrollment.student.dateOfBirth;
  }

  @override
  String get id => enrollment.student.id;

  @override
  String get displayName =>
      '${enrollment.student.lastName} ${enrollment.student.firstName}';

  @override
  Widget get avatar => core_avatar.StudentAvatar(
        firstName: enrollment.student.firstName,
        lastName: enrollment.student.lastName,
        size: 28,
        variant: avatarVariant,
      );

  @override
  List<Widget> get cells => [
        _Cell(enrollment.student.lastName, flex: 3, bold: true),
        _Cell(enrollment.student.surname, flex: 3),
        _Cell(enrollment.student.firstName, flex: 3),
        _Cell(_formattedDate, flex: 2, mono: true),
      ];

  @override
  Widget? get trailing => _StatusChip(
        status: EnrollmentStatus.fromString(enrollment.status),
      );
}

// ─── Cellule (réutilisée depuis EnrollmentDataTable) ────────────────────────

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final bool mono;

  const _Cell(
    this.text, {
    required this.flex,
    this.bold = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text.isNotEmpty ? text : '—',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontFamily: mono ? 'monospace' : null,
          color: bold
              ? const Color(0xFF242A31)
              : const Color(0xFF4B5563),
          letterSpacing: mono ? 0.3 : 0,
        ),
      ),
    );
  }
}

// ─── Badge statut (réutilisée depuis EnrollmentDataTable) ──────────────────

class _StatusChip extends StatelessWidget {
  final EnrollmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 122),
        child: EnrollmentStatusBadge(status: status),
      ),
    );
  }
}
