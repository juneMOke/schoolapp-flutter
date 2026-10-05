import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/camera_lifecycle_guard.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_header.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/photo_capture_outcome.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_capture_decor.dart';

export 'package:school_app_flutter/features/student_photo/presentation/capture/photo_capture_outcome.dart';

/// La modale de capture, partagée par les trois points d'entrée (étape 1,
/// en-tête de fiche, Résumé). Rendue au niveau racine pour échapper aux
/// conteneurs animés du parcours.
class StudentPhotoCaptureDialog extends StatefulWidget {
  final String studentName;
  final PhotoCaptureTarget target;
  final PhotoCaptureEntry entry;
  final Uint8List? recrop;

  const StudentPhotoCaptureDialog({
    super.key,
    required this.studentName,
    required this.target,
    this.entry = PhotoCaptureEntry.camera,
    this.recrop,
  });

  /// Délai avant la fermeture d'elle-même, une fois la photo enregistrée.
  static const Duration savedAutoClose = AppMotion.photoSavedAutoClose;

  static Future<PhotoCaptureOutcome?> show(
    BuildContext context, {
    required String studentName,
    required PhotoCaptureTarget target,
    PhotoCaptureEntry entry = PhotoCaptureEntry.camera,
    Uint8List? recrop,
  }) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return showGeneralDialog<PhotoCaptureOutcome>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: AppColors.photoCaptureScrim,
      transitionDuration: reduceMotion ? Duration.zero : AppMotion.standard,
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: PhotoCaptureDecor.entryScale, end: 1)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      ),
      pageBuilder: (_, _, _) => StudentPhotoCaptureDialog(
        studentName: studentName,
        target: target,
        entry: entry,
        recrop: recrop,
      ),
    );
  }

  @override
  State<StudentPhotoCaptureDialog> createState() =>
      _StudentPhotoCaptureDialogState();
}

class _StudentPhotoCaptureDialogState extends State<StudentPhotoCaptureDialog> {
  late final StudentPhotoCaptureCubit _cubit;
  Timer? _autoClose;

  static bool get _isTouch =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _cubit = getIt<StudentPhotoCaptureCubit>();
    unawaited(
      _cubit.start(
        target: widget.target,
        isTouch: _isTouch,
        recrop: widget.recrop,
        importFirst: widget.entry == PhotoCaptureEntry.import,
      ),
    );
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    unawaited(_cubit.close());
    super.dispose();
  }

  bool get _busy => _cubit.state is CaptureSaving;

  void _close([PhotoCaptureOutcome? outcome]) {
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  void _onState(BuildContext context, StudentPhotoCaptureState state) {
    switch (state) {
      // « Photo enregistrée » est une région annoncée : le lecteur d'écran
      // la lit de lui-même.
      case CaptureSaved():
        _autoClose = Timer(
          StudentPhotoCaptureDialog.savedAutoClose,
          () => _close(const PhotoSavedOutcome()),
        );
      case CaptureDraftReady(:final photo, :final takenAt):
        _close(PhotoDraftOutcome(photo, takenAt));
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullscreen =
        MediaQuery.sizeOf(context).width <
        AppDimensions.photoPanelFullscreenBelow;
    return BlocProvider.value(
      value: _cubit,
      child: CameraLifecycleGuard(
        onSuspend: _cubit.suspendCamera,
        onResume: _cubit.resumeCamera,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (!_busy) _close();
            },
            const SingleActivator(LogicalKeyboardKey.space): _cubit.shoot,
          },
          child: FocusScope(
            autofocus: true,
            child: Stack(
              children: [
                // Le voile : un clic dehors ferme, sauf pendant l'enregistrement.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!_busy) _close();
                    },
                  ),
                ),
                Center(
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: l10n.photoDialogSemantics(widget.studentName),
                    child: _panel(context, fullscreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, bool fullscreen) {
    final radius = BorderRadius.circular(
      fullscreen ? 0 : AppDimensions.photoPanelRadius,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: fullscreen
            ? double.infinity
            : AppDimensions.photoPanelMaxWidth,
        maxHeight: fullscreen
            ? double.infinity
            : MediaQuery.sizeOf(context).height,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: PhotoCaptureDecor.gradient,
            boxShadow: fullscreen ? null : PhotoCaptureDecor.panelShadow,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sectionGap,
                AppSpacing.md,
                AppSpacing.sectionGap,
                AppSpacing.sectionGap,
              ),
              child:
                  BlocConsumer<
                    StudentPhotoCaptureCubit,
                    StudentPhotoCaptureState
                  >(
                    listenWhen: (previous, current) =>
                        current is CaptureSaved || current is CaptureDraftReady,
                    listener: _onState,
                    builder: (context, state) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CaptureHeader(
                          studentName: widget.studentName,
                          reviewing:
                              state is CaptureReview ||
                              state is CaptureSaveFailed,
                          onClose: state is CaptureSaving ? null : _close,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CaptureBody(state: state, cubit: _cubit),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
