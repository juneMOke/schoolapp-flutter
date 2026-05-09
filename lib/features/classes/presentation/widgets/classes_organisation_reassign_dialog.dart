import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> showClassesOrganisationReassignDialog({
  required BuildContext context,
  required ClassroomMemberReassignIntent intent,
  required List<BootstrapClassroom> options,
}) {
  final classroomBloc = context.read<ClassroomBloc>();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      String? selectedTargetId = options.first.id;

      return BlocProvider<ClassroomBloc>.value(
        value: classroomBloc,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final l10n = AppLocalizations.of(context)!;

            return BlocConsumer<ClassroomBloc, ClassroomState>(
              listenWhen: (previous, current) =>
                  previous.reassignStatus != current.reassignStatus,
              listener: (context, state) {
                if (state.reassignStatus == ClassroomStatus.success ||
                    state.reassignStatus == ClassroomStatus.failure) {
                  Navigator.of(dialogContext).pop();
                }
              },
              buildWhen: (previous, current) =>
                  previous.reassignStatus != current.reassignStatus,
              builder: (context, state) {
                final isLoading = state.reassignStatus == ClassroomStatus.loading;

                return PopScope(
                  canPop: !isLoading,
                  child: AlertDialog(
                    backgroundColor: AppColors.financeDetailCard,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.sectionCardRadius,
                      ),
                      side: BorderSide(
                        color: AppColors.borderStrong.withValues(alpha: 0.2),
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: AppDimensions.spacingXL,
                          height: AppDimensions.spacingXL,
                          decoration: BoxDecoration(
                            color: AppColors.bleuArdoise.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.spacingM,
                            ),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: AppColors.bleuArdoise,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Expanded(
                          child: Text(
                            l10n.classesOrganisationTransferDialogTitle,
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.classesOrganisationTransferDialogMessage(
                            intent.studentDisplayName,
                          ),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTargetId,
                          isExpanded: true,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                l10n.classesOrganisationTransferTargetLabel,
                            floatingLabelStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.classesFocusRing,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.spacingS),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.spacingS),
                              borderSide: const BorderSide(
                                color: AppColors.classesFocusRing,
                                width: 1.6,
                              ),
                            ),
                          ),
                          items: options
                              .map(
                                (classroom) => DropdownMenuItem<String>(
                                  value: classroom.id,
                                  child: Text(classroom.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setDialogState(() => selectedTargetId = value);
                                },
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: AppDimensions.spacingS),
                          Text(
                            l10n.classesOrganisationTransferInProgress,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(
                                    0,
                                    AppDimensions.minTouchTarget,
                                  ),
                                ),
                                child: Text(
                                  l10n.cancel,
                                  style: AppTextStyles.action.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: isLoading || selectedTargetId == null
                                    ? null
                                    : () {
                                        context.read<ClassroomBloc>().add(
                                              ClassroomMemberReassignRequested(
                                                classroomMemberId:
                                                    intent.classroomMemberId,
                                                targetClassroomId:
                                                    selectedTargetId!,
                                              ),
                                            );
                                      },
                                icon: isLoading
                                    ? const SizedBox(
                                        width: AppDimensions.detailMiniIconSize,
                                        height: AppDimensions.detailMiniIconSize,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.swap_horiz),
                                label: Text(
                                  l10n.classesOrganisationTransferAction,
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(
                                    0,
                                    AppDimensions.minTouchTarget,
                                  ),
                                  backgroundColor: AppColors.bleuArdoise,
                                  foregroundColor: AppColors.blancCasse,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}
