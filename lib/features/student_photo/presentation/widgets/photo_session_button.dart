import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// « Séance photo », dans la barre de résultats des listes d'inscription.
/// Absent — pas désactivé — sans `student.photo.write`.
class PhotoSessionButton extends StatelessWidget {
  const PhotoSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate.access(
      kStudentPhotoWriteAccess,
      child: SessionWriteGate(
        child: EteeloButton.secondary(
          label: l10n.photoSessionButton,
          icon: Icons.photo_camera_outlined,
          fullWidth: false,
          onPressed: () => context.pushNamed(AppRoutesNames.photoSession),
        ),
      ),
    );
  }
}
