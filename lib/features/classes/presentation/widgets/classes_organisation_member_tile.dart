import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Variante d'action de la ligne élève (PARCOURS 7).
///
/// - [transfer] : dans une classe → bouton « Transférer » à contour bleu-ardoise.
/// - [assign]   : dans la section non-répartis → bouton « Affecter » terre-cuite
///   plein.
enum ClassesOrganisationMemberAction { transfer, assign }

/// Ligne élève réutilisée dans une classe (Transférer) et dans la section
/// non-répartis (Affecter). Avatar, identité (Nom Post-nom / Prénom), marqueur
/// de genre et bouton d'action ; survol teinté.
class ClassesOrganisationMemberTile extends StatefulWidget {
  final ClassroomMember member;
  final String? classroomId;
  final bool isReassigning;
  final bool isCurrentReassigningMember;
  final ClassesOrganisationMemberAction action;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationMemberTile({
    required this.member,
    required this.classroomId,
    required this.isReassigning,
    required this.isCurrentReassigningMember,
    required this.action,
    required this.onTransferTap,
    super.key,
  });

  @override
  State<ClassesOrganisationMemberTile> createState() =>
      _ClassesOrganisationMemberTileState();
}

class _ClassesOrganisationMemberTileState
    extends State<ClassesOrganisationMemberTile> {
  bool _hovered = false;

  String get _topLine => [
    widget.member.studentLastName,
    widget.member.studentMiddleName ?? '',
  ].where((part) => part.trim().isNotEmpty).join(' ');

  String get _bottomLine => widget.member.studentFirstName.trim();

  String get _displayName => [
    widget.member.studentLastName,
    widget.member.studentMiddleName ?? '',
    widget.member.studentFirstName,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  void _onAction() {
    widget.onTransferTap(
      ClassroomMemberReassignIntent(
        classroomId: widget.classroomId,
        classroomMemberId: widget.member.id,
        studentId: widget.member.studentId,
        studentFirstName: widget.member.studentFirstName,
        studentLastName: widget.member.studentLastName,
        studentGender: widget.member.studentGender,
        studentDisplayName: _displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = widget.isReassigning && !widget.isCurrentReassigningMember;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tuile étroite (téléphone) : bouton en icône seule + tooltip pour ne
        // pas écraser le nom de l'élève.
        final compact =
            constraints.maxWidth < AppBreakpoints.classesMemberTileCompactMax;
        return _buildTile(context, dimmed: dimmed, compact: compact);
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required bool dimmed,
    required bool compact,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.stateHover
              : AppColors.classesMemberSurface,
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.65 : 1,
          child: Row(
            children: [
              StudentAvatar(
                firstName: widget.member.studentFirstName,
                lastName: widget.member.studentLastName,
                studentId: widget.member.studentId,
                size: AvatarSize.md,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _topLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_bottomLine.isNotEmpty)
                      Text(
                        _bottomLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              ClassesOrganisationGenderMarker(
                gender: widget.member.studentGender,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              _ActionButton(
                action: widget.action,
                loading: widget.isCurrentReassigningMember,
                enabled: !widget.isReassigning,
                compact: compact,
                onPressed: _onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ClassesOrganisationMemberAction action;
  final bool loading;
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.loading,
    required this.enabled,
    required this.compact,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTransfer = action == ClassesOrganisationMemberAction.transfer;
    final label = isTransfer
        ? l10n.classesOrganisationTransferAction
        : l10n.classesOrganisationAssignAction;

    final icon = loading
        ? const SizedBox(
            width: AppDimensions.detailMiniIconSize,
            height: AppDimensions.detailMiniIconSize,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(isTransfer ? Icons.swap_horiz_rounded : Icons.add_rounded);

    final onTap = (enabled && !loading) ? onPressed : null;

    // Étroit : icône seule (+ tooltip) pour préserver la place du nom.
    if (compact) {
      final child = _styledButton(
        isTransfer: isTransfer,
        onTap: onTap,
        square: true,
        child: loading
            ? icon
            : Icon(isTransfer ? Icons.swap_horiz_rounded : Icons.add_rounded),
      );
      return Tooltip(message: label, child: child);
    }

    return _styledButton(
      isTransfer: isTransfer,
      onTap: onTap,
      square: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _styledButton({
    required bool isTransfer,
    required VoidCallback? onTap,
    required bool square,
    required Widget child,
  }) {
    final minSize = square
        ? const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget)
        : const Size(0, AppDimensions.minTouchTarget);
    final padding = EdgeInsets.symmetric(
      horizontal: square ? AppDimensions.spacingXS : AppDimensions.spacingS,
    );

    if (isTransfer) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bleuArdoise,
          side: const BorderSide(color: AppColors.bleuArdoise),
          minimumSize: minSize,
          padding: padding,
          shape: const StadiumBorder(),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.terreCuite,
        foregroundColor: AppColors.blancCasse,
        minimumSize: minSize,
        padding: padding,
        shape: const StadiumBorder(),
      ),
      child: child,
    );
  }
}
