import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_dialog.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_edit_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_launcher.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_avatar_parts.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_capture_support.dart';

/// L'avatar de l'en-tête d'une fiche, qui est lui-même le bouton photo.
///
/// - Sans photo : contour pointillé or ; un appui ouvre la caméra.
/// - Avec photo : un menu (Reprendre, Importer, Recadrer, Retirer).
/// - Sans `student.photo.write` : un avatar simple, non cliquable.
class PhotoAvatarButton extends StatelessWidget {
  final String studentId;
  final String firstName;
  final String lastName;
  final String studentName;

  const PhotoAvatarButton({
    super.key,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.studentName,
  });

  static const double _size = AppDimensions.photoHeaderAvatar;

  @override
  Widget build(BuildContext context) {
    final avatar = PersonPhotoOr(
      personId: studentId,
      size: _size,
      fallback: PhotoHeaderInitials(firstName: firstName, lastName: lastName),
    );
    if (!photoCaptureSupported) return avatar;
    return PermissionGate.access(
      kStudentPhotoWriteAccess,
      fallback: avatar,
      child: SessionWriteGate.builder(
        builder: (context, blocksWrites) => blocksWrites
            ? avatar
            : BlocProvider(
                create: (_) => getIt<StudentPhotoEditCubit>(),
                child: _EditableHeaderAvatar(
                  studentId: studentId,
                  studentName: studentName,
                  avatar: avatar,
                ),
              ),
      ),
    );
  }
}

class _EditableHeaderAvatar extends StatelessWidget {
  final String studentId;
  final String studentName;
  final Widget avatar;

  const _EditableHeaderAvatar({
    required this.studentId,
    required this.studentName,
    required this.avatar,
  });

  void _capture(BuildContext context, PhotoCaptureEntry entry) =>
      StudentPhotoLauncher.capture(
        context,
        studentId: studentId,
        studentName: studentName,
        entry: entry,
      );

  Future<void> _confirmRemoval(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StudentPhotoEditCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.photoRemoveConfirm),
        content: Text(l10n.photoRemoveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.photoCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.photoRemove),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.remove(studentId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<StudentPhotoRef?>(
      valueListenable: getIt<StudentPhotoRegistry>().watch(studentId),
      builder: (context, ref, _) {
        final hasPhoto = ref?.hasPhoto ?? false;
        final badged = PhotoAvatarBadged(avatar: avatar, dashed: !hasPhoto);
        if (!hasPhoto) {
          return IconButton(
            tooltip: l10n.photoAddTooltip,
            onPressed: () => _capture(context, PhotoCaptureEntry.camera),
            icon: badged,
            padding: EdgeInsets.zero,
          );
        }
        return MenuAnchor(
          style: const MenuStyle(
            minimumSize: WidgetStatePropertyAll(
              Size(AppDimensions.photoHeaderMenuWidth, 0),
            ),
          ),
          builder: (context, controller, _) => IconButton(
            tooltip: l10n.photoEyebrow,
            padding: EdgeInsets.zero,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: badged,
          ),
          menuChildren: [
            _item(
              Icons.photo_camera_outlined,
              l10n.photoMenuRetake,
              () => _capture(context, PhotoCaptureEntry.camera),
            ),
            _item(
              Icons.upload_rounded,
              l10n.photoMenuImport,
              () => _capture(context, PhotoCaptureEntry.import),
            ),
            _item(
              Icons.crop_rounded,
              l10n.photoCrop,
              () => StudentPhotoLauncher.recrop(
                context,
                studentId: studentId,
                studentName: studentName,
              ),
            ),
            const Divider(height: 1),
            _item(
              Icons.delete_outline_rounded,
              l10n.photoMenuRemove,
              () => _confirmRemoval(context),
              danger: true,
            ),
          ],
        );
      },
    );
  }

  Widget _item(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool danger = false,
  }) => MenuItemButton(
    leadingIcon: Icon(icon, color: danger ? AppColors.error : null),
    style: const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(0, AppDimensions.photoHeaderMenuItem),
      ),
    ),
    onPressed: onPressed,
    child: Text(
      label,
      style: danger ? const TextStyle(color: AppColors.error) : null,
    ),
  );
}
