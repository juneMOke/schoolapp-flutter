import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_dialog.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la modale de capture pour un élève, depuis n'importe quel point
/// d'entrée (étape 1, en-tête de fiche, Résumé).
///
/// Sous une nouvelle inscription — un [StudentPhotoDraftCubit] au-dessus —
/// la photo est gardée en brouillon jusqu'à l'enregistrement de l'élève ;
/// ailleurs, elle est enregistrée aussitôt.
abstract final class StudentPhotoLauncher {
  static StudentPhotoDraftCubit? _draftOf(BuildContext context) {
    try {
      return BlocProvider.of<StudentPhotoDraftCubit>(context);
    } on FlutterError {
      return null;
    }
  }

  /// Prendre (caméra) ou importer (sélecteur) une photo.
  static Future<void> capture(
    BuildContext context, {
    required String studentId,
    required String studentName,
    PhotoCaptureEntry entry = PhotoCaptureEntry.camera,
  }) => _open(context, studentId, studentName, entry: entry);

  /// Recadrer la photo actuelle de l'élève.
  static Future<void> recrop(
    BuildContext context, {
    required String studentId,
    required String studentName,
  }) async {
    final draft = _draftOf(context);
    // La grande photo seulement : recadrer une vignette l'agrandirait, et
    // la version floue remplacerait l'originale chez le serveur.
    final bytes =
        draft?.state.photo ??
        await getIt<StudentPhotoRegistry>().fullPhotoOf(studentId);
    if (!context.mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoCropUnavailable),
        ),
      );
      return;
    }
    await _open(context, studentId, studentName, recrop: bytes);
  }

  static Future<void> _open(
    BuildContext context,
    String studentId,
    String studentName, {
    PhotoCaptureEntry entry = PhotoCaptureEntry.camera,
    Uint8List? recrop,
  }) async {
    final draft = _draftOf(context);
    final outcome = await StudentPhotoCaptureDialog.show(
      context,
      studentName: studentName,
      target: draft == null ? SaveForStudent(studentId) : const KeepAsDraft(),
      entry: entry,
      recrop: recrop,
    );
    if (outcome case PhotoDraftOutcome(:final photo, :final takenAt)) {
      await draft?.keep(photo, takenAt);
    }
  }
}
