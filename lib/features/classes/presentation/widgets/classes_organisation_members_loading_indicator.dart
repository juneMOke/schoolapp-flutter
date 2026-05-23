import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationMembersLoadingIndicator extends StatelessWidget {
  const ClassesOrganisationMembersLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ClassroomBloc, ClassroomState>(
      buildWhen: (previous, current) =>
          previous.membersStatus != current.membersStatus ||
          previous.membersLoadingCount != current.membersLoadingCount,
      builder: (context, classroomState) {
        final shouldShow =
            classroomState.membersStatus == ClassroomStatus.loading &&
                classroomState.membersLoadingCount > 0;

        return AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: shouldShow
              ? Padding(
                  key: const ValueKey('classes-loading-classrooms'),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingS,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: AppDimensions.detailMiniIconSize,
                        height: AppDimensions.detailMiniIconSize,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          l10n.classesOrganisationLoadingClassroomsCount(
                            classroomState.membersLoadingCount,
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
