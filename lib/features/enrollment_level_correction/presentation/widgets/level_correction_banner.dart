import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_status_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_refusal_l10n.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_notice.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'une correction de niveau, en tête du dossier : en attente ou
/// acceptée sans être descendue (l'encaissement est suspendu), abandonnée par
/// la file, ou refusée (avec la raison). Rien une fois descendue : le dossier
/// montre alors le nouveau niveau.
class LevelCorrectionBanner extends StatelessWidget {
  /// Nom affiché d'un niveau, par identifiant ; l'identifiant brut sinon.
  final String Function(String levelId) levelName;

  const LevelCorrectionBanner({super.key, required this.levelName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correction = context
        .select<LevelCorrectionStatusCubit, LevelCorrection?>(
          (cubit) => cubit.state.correction,
        );
    if (correction == null) return const SizedBox.shrink();
    final from = levelName(correction.fromSchoolLevelId);
    final to = levelName(correction.toSchoolLevelId);
    final Widget? banner = switch (correction.status) {
      LevelCorrectionStatus.pending => SuspensionNotice(
        lead: l10n.levelCorrectionBannerPendingLead(from, to),
        body: l10n.levelCorrectionBannerPendingBody,
      ),
      LevelCorrectionStatus.applied => SuspensionNotice(
        lead: l10n.levelCorrectionBannerAppliedLead(from, to),
        body: l10n.levelCorrectionBannerAppliedBody,
      ),
      LevelCorrectionStatus.stalled => SuspensionGestureError(
        message: l10n.levelCorrectionBannerStalled(from, to),
      ),
      LevelCorrectionStatus.refused => SuspensionGestureError(
        message: l10n.levelCorrectionBannerRefused(
          from,
          to,
          l10n.levelCorrectionRefusalMessage(correction.refusalCode),
        ),
      ),
      LevelCorrectionStatus.settled => null,
    };
    if (banner == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: banner,
      ),
    );
  }
}
