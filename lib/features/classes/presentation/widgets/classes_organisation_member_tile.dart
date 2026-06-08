import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
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
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.loading,
    required this.enabled,
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
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (isTransfer) {
      return OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bleuArdoise,
          side: const BorderSide(color: AppColors.bleuArdoise),
          minimumSize: const Size(0, AppDimensions.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
          ),
          shape: const StadiumBorder(),
        ),
        icon: icon,
        label: labelWidget,
      );
    }

    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.terreCuite,
        foregroundColor: AppColors.blancCasse,
        minimumSize: const Size(0, AppDimensions.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
        shape: const StadiumBorder(),
      ),
      icon: icon,
      label: labelWidget,
    );
  }
}
