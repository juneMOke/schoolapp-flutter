import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_avatar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_dialog.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_edit_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_launcher.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_slot_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'emplacement photo de l'étape « Identité » : une colonne de 148 dp à
/// gauche de la grille, comme sur une carte d'élève.
///
/// Reste actif sur un dossier verrouillé : la photo se gère hors du dossier.
/// Sans `student.photo.write`, la photo (ou un cercle vide) et la mention
/// « Gérée par le secrétariat ».
class PhotoSlot extends StatelessWidget {
  final String studentId;
  final String studentName;

  const PhotoSlot({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.photoSlotColumn,
      child: PermissionGate.access(
        kStudentPhotoWriteAccess,
        fallback: _ReadOnlySlot(studentId: studentId),
        child: BlocProvider(
          create: (_) => getIt<StudentPhotoEditCubit>(),
          child: _EditableSlot(studentId: studentId, studentName: studentName),
        ),
      ),
    );
  }
}

/// Ce que l'emplacement montre : la photo en brouillon d'abord (nouvelle
/// inscription), sinon celle du registre.
class _SlotView {
  final Uint8List? draft;
  final StudentPhotoRef? ref;

  const _SlotView(this.draft, this.ref);

  bool get hasPhoto => draft != null || (ref?.hasPhoto ?? false);
}

class _EditableSlot extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _EditableSlot({required this.studentId, required this.studentName});

  @override
  State<_EditableSlot> createState() => _EditableSlotState();
}

class _EditableSlotState extends State<_EditableSlot> {
  bool _confirmingRemoval = false;

  StudentPhotoDraftCubit? get _draft {
    try {
      return BlocProvider.of<StudentPhotoDraftCubit>(context);
    } on FlutterError {
      return null;
    }
  }

  Future<void> _capture(PhotoCaptureEntry entry) =>
      StudentPhotoLauncher.capture(
        context,
        studentId: widget.studentId,
        studentName: widget.studentName,
        entry: entry,
      );

  Future<void> _recrop() => StudentPhotoLauncher.recrop(
    context,
    studentId: widget.studentId,
    studentName: widget.studentName,
  );

  Future<void> _remove(_SlotView view) async {
    final draft = _draft;
    if (view.draft != null && draft != null) {
      draft.discard();
    } else {
      await context.read<StudentPhotoEditCubit>().remove(widget.studentId);
    }
    if (mounted) setState(() => _confirmingRemoval = false);
  }

  @override
  Widget build(BuildContext context) {
    final draftCubit = _draft;
    final registry = getIt<StudentPhotoRegistry>();
    return ValueListenableBuilder<StudentPhotoRef?>(
      valueListenable: registry.watch(widget.studentId),
      builder: (context, ref, _) {
        if (draftCubit == null) return _build(_SlotView(null, ref));
        return BlocBuilder<StudentPhotoDraftCubit, StudentPhotoDraftState>(
          bloc: draftCubit,
          builder: (context, draft) => _build(_SlotView(draft.photo, ref)),
        );
      },
    );
  }

  Widget _build(_SlotView view) {
    final l10n = AppLocalizations.of(context)!;
    final busy = context.watch<StudentPhotoEditCubit>().state.busy;
    final ref = view.ref;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.hasPhoto)
          SlotPhoto(studentId: widget.studentId, draft: view.draft)
        else
          SessionWriteGate(
            child: PhotoSlotEmptyCircle(
              semanticLabel: l10n.photoTake,
              onTap: () => _capture(PhotoCaptureEntry.camera),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        SessionWriteGate(
          child: view.hasPhoto
              ? (_confirmingRemoval
                    ? PhotoSlotRemoveConfirm(
                        onCancel: () =>
                            setState(() => _confirmingRemoval = false),
                        onConfirm: busy ? null : () => _remove(view),
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          PhotoSlotLink(
                            label: l10n.photoRetake,
                            onPressed: () => _capture(PhotoCaptureEntry.camera),
                          ),
                          PhotoSlotLink(
                            label: l10n.photoCrop,
                            onPressed: _recrop,
                          ),
                          PhotoSlotLink(
                            label: l10n.photoRemove,
                            danger: true,
                            onPressed: () =>
                                setState(() => _confirmingRemoval = true),
                          ),
                        ],
                      ))
              : Column(
                  children: [
                    EteeloButton.primary(
                      label: l10n.photoTake,
                      icon: Icons.photo_camera_outlined,
                      onPressed: () => _capture(PhotoCaptureEntry.camera),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    EteeloButton.secondary(
                      label: l10n.photoImport,
                      icon: Icons.upload_rounded,
                      onPressed: () => _capture(PhotoCaptureEntry.import),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (ref?.rejection != null)
          PhotoSlotCaption(
            text: l10n.photoRejected,
            alert: true,
            icon: Icons.error_outline_rounded,
          )
        else if (view.draft != null)
          PhotoSlotCaption(text: l10n.photoDraftPending)
        else if (ref?.isPending ?? false)
          PhotoSlotCaption(
            text: l10n.photoPendingSync,
            icon: Icons.cloud_upload_outlined,
          )
        else if (!view.hasPhoto)
          PhotoSlotCaption(text: l10n.photoOptional),
      ],
    );
  }
}

/// La photo de l'emplacement : un anneau blanc et un filet, autour de la
/// photo en brouillon ou de celle du registre.
class SlotPhoto extends StatelessWidget {
  final String studentId;
  final Uint8List? draft;
  final double size;

  const SlotPhoto({
    super.key,
    required this.studentId,
    this.draft,
    this.size = AppDimensions.photoSlotCircle,
  });

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    // L'anneau garde la proportion de l'emplacement (4 dp pour 128).
    final ring =
        size * AppDimensions.photoSlotRing / AppDimensions.photoSlotCircle;
    final inner = size - 2 * ring;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: draft != null
          ? ClipOval(
              child: Image.memory(
                draft,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => SizedBox.square(dimension: inner),
              ),
            )
          : PersonPhotoOr(
              personId: studentId,
              size: inner,
              fallback: SizedBox.square(dimension: inner),
            ),
    );
  }
}

class _ReadOnlySlot extends StatelessWidget {
  final String studentId;

  const _ReadOnlySlot({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SlotPhoto(studentId: studentId),
        const SizedBox(height: AppSpacing.sm),
        PhotoSlotCaption(
          text: l10n.photoManagedBySecretariat,
          icon: Icons.lock_outline_rounded,
        ),
      ],
    );
  }
}
