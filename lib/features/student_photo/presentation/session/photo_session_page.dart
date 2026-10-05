import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/camera_lifecycle_guard.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_network_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_app_bar.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_class_picker.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_queue_panel.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_panel.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_summary_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La séance photo de la rentrée : plein écran, une classe à la fois.
class PhotoSessionPage extends StatelessWidget {
  const PhotoSessionPage({super.key});

  static bool get _isTouch =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final yearId =
        context
            .read<AcademicYearContextBloc>()
            .state
            .context
            ?.academicYear
            .id ??
        '';
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<PhotoSessionCubit>()..load(yearId, isTouch: _isTouch),
        ),
        BlocProvider(create: (_) => getIt<PhotoNetworkCubit>()..start()),
      ],
      child: const _PhotoSessionView(),
    );
  }
}

class _PhotoSessionView extends StatelessWidget {
  const _PhotoSessionView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PhotoSessionCubit>();
    return CameraLifecycleGuard(
      onSuspend: cubit.suspendCamera,
      onResume: cubit.resumeCamera,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): cubit.shoot,
        },
        child: Focus(
          autofocus: true,
          child: BlocBuilder<PhotoSessionCubit, PhotoSessionState>(
            builder: (context, state) => Scaffold(
              backgroundColor: AppColors.surface,
              appBar: PhotoSessionAppBar(
                state: state,
                onBack: () => _back(context, state),
                onFinish: cubit.finish,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _body(context, state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Retour pendant la prise de vue : le bilan d'abord, comme « Terminer ».
  void _back(BuildContext context, PhotoSessionState state) {
    if (state is SessionShooting) {
      unawaited(context.read<PhotoSessionCubit>().finish());
      return;
    }
    if (context.canPop()) context.pop();
  }

  Widget _body(BuildContext context, PhotoSessionState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PhotoSessionCubit>();
    return switch (state) {
      SessionLoading() => const EteeloListSkeleton(rowCount: 3),
      SessionLoadFailed(:final failure) => EteeloErrorResult(
        type: _errorTypeOf(failure),
        title: l10n.photoSessionLoadErrorTitle,
        message: l10n.photoSessionLoadErrorMessage,
        primaryAction: failure is UnauthorizedFailure
            ? null
            : FilledButton(
                onPressed: () => cubit.load(
                  context
                          .read<AcademicYearContextBloc>()
                          .state
                          .context
                          ?.academicYear
                          .id ??
                      '',
                  isTouch: PhotoSessionPage._isTouch,
                ),
                child: Text(l10n.photoRetry),
              ),
      ),
      SessionSetup() => SessionClassPicker(
        state: state,
        onSelect: cubit.selectClass,
        onOnlyMissing: cubit.setOnlyMissing,
        onStart: cubit.start,
      ),
      SessionShooting() => _Shooting(state: state),
      SessionSummary() => SessionSummaryView(
        state: state,
        onResume: cubit.resume,
        onFinish: () {
          if (context.canPop()) context.pop();
        },
      ),
    };
  }

  static EteeloErrorType _errorTypeOf(Failure failure) => switch (failure) {
    NetworkFailure() => EteeloErrorType.network,
    UnauthorizedFailure() => EteeloErrorType.forbidden,
    ServerFailure() => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };
}

/// La prise de vue et la file : côte à côte à partir de 840 dp, empilées en
/// dessous (la prise de vue d'abord).
class _Shooting extends StatelessWidget {
  final SessionShooting state;

  const _Shooting({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PhotoSessionCubit>();
    final online = context.watch<PhotoNetworkCubit>().state;
    final registry = getIt<StudentPhotoRegistry>();
    final waiting = state.queue
        .where(
          (i) =>
              i.status == SessionItemStatus.photographed &&
              (registry.refOf(i.student.id)?.isPending ?? false),
        )
        .length;
    final shoot = SessionShootPanel(
      state: state,
      online: online,
      onShoot: cubit.shoot,
      onSkip: cubit.skip,
      onAbsent: cubit.markAbsent,
      onImport: cubit.importForCurrent,
      onSwitch: cubit.switchCamera,
      onAdvance: cubit.advance,
      onRetake: cubit.retakeCurrent,
    );
    final queue = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!online && waiting > 0) ...[
          SessionOfflineBanner(pending: waiting),
          const SizedBox(height: AppSpacing.md),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height -
                AppDimensions.photoSessionQueueReserve,
          ),
          child: SessionQueuePanel(
            state: state,
            online: online,
            onSelect: cubit.select,
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppDimensions.photoSessionStackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              shoot,
              const SizedBox(height: AppSpacing.sectionGap),
              queue,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: shoot),
            const SizedBox(width: AppSpacing.sectionGap),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppDimensions.photoSessionQueueMin,
                maxWidth: AppDimensions.photoSessionQueueMax,
              ),
              child: queue,
            ),
          ],
        );
      },
    );
  }
}
