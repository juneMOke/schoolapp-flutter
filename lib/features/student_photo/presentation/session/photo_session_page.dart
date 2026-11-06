import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/keyboard/idle_focus_shortcut.dart';
import 'package:school_app_flutter/core/widgets/content_max_width.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/camera_lifecycle_guard.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_network_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_app_bar.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_class_picker.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shooting_view.dart';
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
      // Espace déclenche, sauf quand un bouton a le focus : il le garde.
      child: IdleFocusShortcut(
        activator: const SingleActivator(LogicalKeyboardKey.space),
        onInvoke: cubit.shoot,
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
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final landscape = SessionShootingView.landscapeFor(
                    viewport.biggest,
                  );
                  return SingleChildScrollView(
                    // En paysage : marges resserrées, la hauteur va au viseur
                    // (cf. `photoSessionLandscapeChromeReserve`).
                    padding: EdgeInsets.all(
                      landscape ? AppSpacing.lg : AppSpacing.xl,
                    ),
                    child: ContentMaxWidth(
                      child: _body(
                        context,
                        state,
                        viewport.maxHeight,
                        landscape: landscape,
                      ),
                    ),
                  );
                },
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

  Widget _body(
    BuildContext context,
    PhotoSessionState state,
    double viewportHeight, {
    required bool landscape,
  }) {
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
      SessionShooting() => SessionShootingView(
        state: state,
        viewportHeight: viewportHeight,
        landscape: landscape,
      ),
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
