import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// La prise de vue et la file : côte à côte à partir de 840 dp, empilées en
/// dessous (la prise de vue d'abord).
class SessionShootingView extends StatelessWidget {
  final SessionShooting state;

  /// La hauteur visible de la page : le viseur s'y borne, pour que le
  /// déclencheur reste à l'écran sur un portable (768, 900 dp de haut).
  final double viewportHeight;

  const SessionShootingView({
    super.key,
    required this.state,
    required this.viewportHeight,
  });

  @override
  Widget build(BuildContext context) {
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
    final shoot = SessionShootPanel(
      state: state,
      viewfinderMaxHeight: PhotoViewfinder.heightWithin(
        viewportHeight,
        reserve: AppDimensions.photoSessionShootChromeReserve,
      ),
      online: online,
      onShoot: cubit.shoot,
      onSkip: cubit.skip,
      onAbsent: cubit.markAbsent,
      onImport: cubit.importForCurrent,
      onSwitch: cubit.switchCamera,
      onAdvance: cubit.advance,
      onRetake: cubit.retakeCurrent,
    );
    final queue = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!online && waiting > 0) ...[
          SessionOfflineBanner(pending: waiting),
          const SizedBox(height: AppSpacing.md),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height -
                AppDimensions.photoSessionQueueReserve,
          ),
          child: SessionQueuePanel(
            state: state,
            online: online,
            onSelect: cubit.select,
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppDimensions.photoSessionStackBelow) {
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
