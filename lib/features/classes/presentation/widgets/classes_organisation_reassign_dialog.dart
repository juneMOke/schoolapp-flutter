import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> showClassesOrganisationReassignDialog({
  required BuildContext context,
  required ClassroomMemberReassignIntent intent,
  required List<ClassroomReassignOption> options,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final selectedTargetId = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.financeDetailCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.cardRadius),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bleuArdoise.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.bleuArdoise,
                      size: AppDimensions.detailMiniIconSize,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      intent.classroomId == null
                          ? l10n.classesOrganisationAssignDialogTitle
                          : l10n.classesOrganisationTransferDialogTitle,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                intent.classroomId == null
                    ? l10n.classesOrganisationAssignDialogMessage(intent.studentDisplayName)
                    : l10n.classesOrganisationTransferDialogMessage(intent.studentDisplayName),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppDimensions.spacingS),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingM,
                        vertical: AppDimensions.spacingXS,
                      ),
                      leading: const Icon(Icons.class_outlined, color: AppColors.bleuArdoise),
                      title: Text(
                        option.name,
                        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        l10n.classesOrganisationClassroomPopulation(option.totalCount),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(sheetContext).pop(option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || selectedTargetId == null) {
    return;
  }

  final confirmed = await showAppConfirmationDialog(
    context: context,
    title: l10n.classesOrganisationTransferDialogTitle,
    message: l10n.classesOrganisationTransferConfirmMessage(intent.studentDisplayName),
    confirmLabel: l10n.confirm,
    cancelLabel: l10n.cancel,
  );

  if (!confirmed || !context.mounted) {
    return;
  }

  context.read<ClassroomBloc>().add(
        ClassroomMemberReassignRequested(
          classroomMemberId: intent.classroomMemberId,
          targetClassroomId: selectedTargetId,
        ),
      );
}
