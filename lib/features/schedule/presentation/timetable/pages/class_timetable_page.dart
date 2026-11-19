import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/offline/online_only.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_picker.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_content.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/states/school_calendar_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Agenda & Horaires ▸ Emploi du temps : l'emploi du temps publié d'une classe,
/// en semaine ou à la journée. L'adresse retient la classe, la vue et le jour
/// (EDT fiche, A1).
class ClassTimetablePage extends StatelessWidget {
  const ClassTimetablePage({super.key});

  static const classParam = 'classe';
  static const modeParam = 'vue';
  static const dayParam = 'jour';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.instance<ClassTimetableCubit>()..load(pull: true),
    child: BlocBuilder<ClassTimetableCubit, ClassTimetableState>(
      builder: (context, state) {
        final cubit = context.read<ClassTimetableCubit>();
        return LocationParamsSync(
          current: {
            classParam: state.classroomId,
            modeParam: state.mode?.name,
            dayParam: state.day?.wire,
          },
          onLocation: (values) {
            unawaited(cubit.selectClass(values[classParam]));
            cubit
              ..setMode(
                ClassTimetableMode.values
                    .where((m) => m.name == values[modeParam])
                    .firstOrNull,
              )
              ..setDay(
                values[dayParam] == null
                    ? null
                    : WeekdayX.fromWire(values[dayParam]),
              );
          },
          child: AppPageBackground(
            width: PageContentWidth.wide,
            child: OnlineOnly(
              builder: (context, online) =>
                  _Body(state: state, cubit: cubit, online: online),
            ),
          ),
        );
      },
    ),
  );
}

class _Body extends StatelessWidget {
  final ClassTimetableState state;
  final ClassTimetableCubit cubit;
  final bool online;

  const _Body({required this.state, required this.cubit, required this.online});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final header = EteeloPageHeader(
      eyebrow: l10n.classTimetableEyebrow,
      title: l10n.classTimetableTitle,
    );
    final content = switch (state.status) {
      ClassTimetableStatus.loading => EteeloListSkeleton(
        rowCount: 3,
        pillCount: 2,
        showAvatar: false,
        semanticsLabel: l10n.classTimetableLoading,
      ),
      ClassTimetableStatus.failure => SchoolCalendarErrorState(
        failure: state.failure ?? const StorageFailure(),
        onRetry: () => unawaited(cubit.load(pull: true)),
      ),
      ClassTimetableStatus.ready when state.options.isEmpty =>
        EteeloEmptyResult(
          label: l10n.classTimetableNoClassTitle,
          description: l10n.classTimetableNoClassBody,
          medallionIcon: Icons.class_outlined,
          fullWidthCard: true,
        ),
      ClassTimetableStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClassPicker(
            options: state.options,
            selectedId: state.classroomId,
            onSelected: (id) => unawaited(cubit.selectClass(id)),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClassTimetableContent(state: state, cubit: cubit, online: online),
        ],
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }
}
