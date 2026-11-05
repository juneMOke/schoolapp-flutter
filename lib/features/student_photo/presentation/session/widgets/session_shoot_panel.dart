import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_capture_decor.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_landscape.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_viewfinder.dart';

/// La prise de vue d'un élève : qui il est, où en est la classe, le viseur,
/// et la barre Passer · déclencheur · Absent.
///
/// Empilés d'ordinaire ; [landscape] (fenêtre basse, cf.
/// `AppBreakpoints.photoSessionLandscapeMaxHeight`) : le viseur à gauche, le
/// reste à droite, pour que le déclencheur ne passe pas sous le pli.
class SessionShootPanel extends StatelessWidget {
  final SessionShooting state;
  final bool online;
  final VoidCallback onShoot;
  final VoidCallback onSkip;
  final VoidCallback onAbsent;
  final VoidCallback onImport;
  final VoidCallback onSwitch;
  final VoidCallback onAdvance;
  final VoidCallback onRetake;

  /// Redemande la caméra après un refus ou une absence.
  final VoidCallback onRetryCamera;

  /// Le viseur (et son flash) se borne à cette hauteur, centré : sa largeur
  /// en découle. Nul : toute la largeur du panneau.
  final double? viewfinderMaxHeight;

  /// Le viseur à gauche, l'élève et les gestes à droite.
  final bool landscape;

  /// L'identité du viseur, tenue par la vue de prise : d'une disposition à
  /// l'autre, l'aperçu change de parent sans être recréé.
  final GlobalKey? viewfinderKey;

  const SessionShootPanel({
    super.key,
    required this.state,
    this.viewfinderMaxHeight,
    this.landscape = false,
    this.viewfinderKey,
    required this.online,
    required this.onShoot,
    required this.onSkip,
    required this.onAbsent,
    required this.onImport,
    required this.onSwitch,
    required this.onAdvance,
    required this.onRetake,
    required this.onRetryCamera,
  });

  @override
  Widget build(BuildContext context) {
    final viewfinder = SessionShootViewfinder(
      key: viewfinderKey,
      state: state,
      online: online,
      onImport: onImport,
      onRetryCamera: onRetryCamera,
      onAdvance: onAdvance,
      onRetake: onRetake,
    );
    final header = SessionStudentHeader(state: state);
    final actions = SessionShootActions(
      state: state,
      onShoot: onShoot,
      onSkip: onSkip,
      onAbsent: onAbsent,
      onImport: onImport,
      onSwitch: onSwitch,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: PhotoCaptureDecor.gradient,
      ),
      child: landscape
          ? SessionShootLandscape(
              viewfinder: viewfinder,
              viewfinderMaxHeight: viewfinderMaxHeight,
              header: header,
              actions: actions,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.md),
                _bounded(viewfinder),
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            ),
    );
  }

  /// Le flash couvre le viseur, pas le panneau : on borne les deux ensemble.
  Widget _bounded(Widget viewfinder) {
    final maxHeight = viewfinderMaxHeight;
    if (maxHeight == null) return viewfinder;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxHeight * 4 / 3),
        child: viewfinder,
      ),
    );
  }
}
