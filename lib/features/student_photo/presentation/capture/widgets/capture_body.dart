import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_camera_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_outcome_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_review_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps du panneau, état par état.
class CaptureBody extends StatelessWidget {
  final StudentPhotoCaptureState state;
  final StudentPhotoCaptureCubit cubit;

  const CaptureBody({super.key, required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = this.state;
    return switch (state) {
      CaptureStarting() ||
      CaptureLive() ||
      CaptureBlocked() => CaptureCameraBody(
        state: state,
        onImport: cubit.importFile,
        onShoot: cubit.shoot,
        onSwitch: cubit.switchCamera,
      ),
      CaptureReview() => CaptureReviewBody(
        review: state,
        onAdjust: cubit.adjust,
        onRetake: cubit.retake,
        onUse: cubit.confirm,
      ),
      CaptureBadFile() => PhotoViewfinder(
        session: null,
        tip: '',
        overlay: CaptureProblemCard(
          icon: Icons.broken_image_outlined,
          title: l10n.photoBadFileTitle,
          message: l10n.photoBadFileMessage,
          actionLabel: l10n.photoImportAction,
          onAction: cubit.importFile,
        ),
      ),
      CaptureSaving() || CaptureDraftReady() => const CaptureSavingBody(),
      CaptureSaved(:final photo) => CaptureSavedBody(photo: photo),
      CaptureSaveFailed() => CaptureSaveFailedBody(
        onRetry: cubit.confirm,
        onRetake: cubit.retake,
      ),
    };
  }
}
