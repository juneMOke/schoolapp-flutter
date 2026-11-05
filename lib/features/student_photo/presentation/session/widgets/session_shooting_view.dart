import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_network_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_queue_panel.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_panel.dart';

/// La prise de vue et la file : côte à côte à partir de
/// [AppBreakpoints.photoSessionSideBySideMin], empilées en dessous (la prise
/// de vue d'abord). Sous [AppBreakpoints.photoSessionLandscapeMaxHeight] de
/// hauteur visible, la prise de vue elle-même passe en paysage : le viseur à
/// gauche, l'élève et les gestes à droite.
///
/// Chacune garde son identité à la bascule — et le viseur la sienne, d'une
/// disposition de la prise de vue à l'autre (rotation) : sans elle, le viseur serait
/// démonté puis remonté — sur le web, l'élément vidéo ainsi recréé peut
/// rester noir — et la file perdrait son défilement.
class SessionShootingView extends StatefulWidget {
  final SessionShooting state;

  /// La hauteur visible de la page : le viseur s'y borne, pour que le
  /// déclencheur reste à l'écran sur un portable (768, 900 dp de haut).
  final double viewportHeight;

  /// La prise de vue en paysage (cf. [landscapeFor]) ; la file passe alors
  /// dessous, quelle que soit la largeur.
  final bool landscape;

  const SessionShootingView({
    super.key,
    required this.state,
    required this.viewportHeight,
    this.landscape = false,
  });

  /// Une page de [viewport] (sous l'en-tête) met-elle la prise de vue en
  /// paysage ? Basse, mais assez large pour un viseur et les gestes côte à
  /// côte : une fenêtre basse et étroite garde la colonne.
  static bool landscapeFor(Size viewport) =>
      viewport.height < AppBreakpoints.photoSessionLandscapeMaxHeight &&
      viewport.width >= AppBreakpoints.photoSessionLandscapeMinWidth;

  @override
  State<SessionShootingView> createState() => _SessionShootingViewState();
}

class _SessionShootingViewState extends State<SessionShootingView> {
  final GlobalKey _shootKey = GlobalKey(debugLabel: 'session-shoot');
  final GlobalKey _queueKey = GlobalKey(debugLabel: 'session-queue');
  final GlobalKey _viewfinderKey = GlobalKey(debugLabel: 'session-viewfinder');

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
    final landscape = widget.landscape;
    final shoot = KeyedSubtree(
      key: _shootKey,
      child: SessionShootPanel(
        state: state,
        landscape: landscape,
        viewfinderKey: _viewfinderKey,
        viewfinderMaxHeight: PhotoViewfinder.heightWithin(
          widget.viewportHeight,
          reserve: landscape
              ? AppDimensions.photoSessionLandscapeChromeReserve
              : AppDimensions.photoSessionShootChromeReserve,
        ),
        online: online,
        onShoot: cubit.shoot,
        onSkip: cubit.skip,
        onAbsent: cubit.markAbsent,
        onImport: cubit.importForCurrent,
        onSwitch: cubit.switchCamera,
        onAdvance: cubit.advance,
        onRetake: cubit.retakeCurrent,
        onRetryCamera: cubit.retryCamera,
      ),
    );
    // La file défile en elle-même, sous un plancher : sur un téléphone en
    // paysage, « hauteur − réserve » ne laissait qu'une ligne et demie.
    final screen = MediaQuery.sizeOf(context).height;
    final queueMaxHeight = math.max(
      screen - AppDimensions.photoSessionQueueReserve,
      AppDimensions.photoSessionQueueMinHeight,
    );
    final queue = KeyedSubtree(
      key: _queueKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!online && waiting > 0) ...[
            SessionOfflineBanner(pending: waiting),
            const SizedBox(height: AppSpacing.md),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: queueMaxHeight),
            child: SessionQueuePanel(
              state: state,
              online: online,
              onSelect: cubit.select,
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // En paysage, la prise de vue garde toute la largeur : à côté de la
        // file, il ne resterait au viseur que quelques dizaines de dp.
        if (landscape ||
            constraints.maxWidth < AppBreakpoints.photoSessionSideBySideMin) {
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
