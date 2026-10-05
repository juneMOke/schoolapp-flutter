import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_launcher.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_slot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_capture_support.dart';

/// La ligne photo en tête du Résumé : un rappel, jamais une erreur — la photo
/// est facultative. L'action ouvre la caméra sans quitter le Résumé.
class PhotoRecapRow extends StatelessWidget {
  final String studentId;
  final String firstName;
  final String lastName;
  final String studentName;

  const PhotoRecapRow({
    super.key,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.studentName,
  });

  StudentPhotoDraftCubit? _draftOf(BuildContext context) {
    try {
      return BlocProvider.of<StudentPhotoDraftCubit>(context);
    } on FlutterError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftOf(context);
    return ValueListenableBuilder<StudentPhotoRef?>(
      valueListenable: getIt<StudentPhotoRegistry>().watch(studentId),
      builder: (context, ref, _) {
        if (draft == null) return _row(context, ref?.hasPhoto ?? false, null);
        return BlocBuilder<StudentPhotoDraftCubit, StudentPhotoDraftState>(
          bloc: draft,
          builder: (context, state) => _row(
            context,
            state.photo != null || (ref?.hasPhoto ?? false),
            state.photo,
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, bool hasPhoto, Uint8List? draftPhoto) {
    final l10n = AppLocalizations.of(context)!;
    void open() => StudentPhotoLauncher.capture(
      context,
      studentId: studentId,
      studentName: studentName,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.photoRecapPaddingH,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          draftPhoto != null
              ? SlotPhoto(
                  studentId: studentId,
                  draft: draftPhoto,
                  size: AppDimensions.photoRecapAvatar,
                )
              : PersonAvatar(
                  firstName: firstName,
                  lastName: lastName,
                  personId: studentId,
                  size: AppDimensions.photoRecapAvatar,
                  studentPhotoOf: studentId,
                ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.photoEyebrow,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  hasPhoto ? l10n.photoRecapAdded : l10n.photoRecapMissing,
                  style: AppTypography.bodySmall.copyWith(
                    color: hasPhoto ? AppColors.photoDone : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (photoCaptureSupported)
            PermissionGate.access(
              kStudentPhotoWriteAccess,
              child: SessionWriteGate(
                child: hasPhoto
                    ? EteeloButton.ghost(
                        label: l10n.photoRetake,
                        icon: Icons.photo_camera_outlined,
                        fullWidth: false,
                        onPressed: open,
                      )
                    : EteeloButton.secondary(
                        label: l10n.photoAddTooltip,
                        icon: Icons.photo_camera_outlined,
                        fullWidth: false,
                        onPressed: open,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
