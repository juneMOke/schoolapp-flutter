import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// PARCOURS 4 — Sur-couche de résultat de la répartition par genre.
///
/// Centrée (rendue au-dessus de la page via [showDialog]), elle traverse
/// `processing → (success | error)` dans le même vocabulaire que l'encaissement
/// (médaillon, halo, code incident). Le succès récapitule l'effectif par classe ;
/// l'échec laisse les classes intactes et propose « Réessayer ».
///
/// La distribution n'est dispatchée que par la sur-couche : à l'ouverture puis,
/// le cas échéant, sur « Réessayer ». [onDistributed] applique les effets de
/// bord côté page (marquer le niveau réparti + recharger l'aperçu) au succès —
/// jamais en cas d'échec.
Future<void> showClassesOrganisationDistributionResultDialog({
  required BuildContext context,
  required ClassroomBloc classroomBloc,
  required ClassroomDistributionRequested request,
  required String levelName,
  required VoidCallback onDistributed,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<ClassroomBloc>.value(
      value: classroomBloc,
      child: ClassesOrganisationDistributionResultDialog(
        request: request,
        levelName: levelName,
        onDistributed: onDistributed,
      ),
    ),
  );
}

enum _Phase { processing, success, error }

class ClassesOrganisationDistributionResultDialog extends StatefulWidget {
  final ClassroomDistributionRequested request;
  final String levelName;
  final VoidCallback onDistributed;

  const ClassesOrganisationDistributionResultDialog({
    super.key,
    required this.request,
    required this.levelName,
    required this.onDistributed,
  });

  @override
  State<ClassesOrganisationDistributionResultDialog> createState() =>
      _ClassesOrganisationDistributionResultDialogState();
}

class _ClassesOrganisationDistributionResultDialogState
    extends State<ClassesOrganisationDistributionResultDialog> {
  _Phase _phase = _Phase.processing;
  bool _awaitingBloc = false;
  EteeloErrorType _errorType = EteeloErrorType.unknown;
  String? _incidentCode;

  @override
  void initState() {
    super.initState();
    // Démarre la répartition une fois le BlocListener attaché.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runDistribution();
    });
  }

  void _runDistribution() {
    if (_awaitingBloc) return;
    setState(() {
      _phase = _Phase.processing;
      _awaitingBloc = true;
    });
    context.read<ClassroomBloc>().add(widget.request);
  }

  void _onBlocState(ClassroomState state) {
    if (!mounted || !_awaitingBloc) return;
    if (state.distributionStatus == ClassroomStatus.success) {
      _awaitingBloc = false;
      // Effets de bord page : niveau marqué réparti + rechargement de l'aperçu
      // (qui alimente le récapitulatif effectif par classe).
      widget.onDistributed();
      setState(() => _phase = _Phase.success);
    } else if (state.distributionStatus == ClassroomStatus.failure) {
      _awaitingBloc = false;
      setState(() {
        _phase = _Phase.error;
        _errorType = _mapErrorType(state.distributionErrorType);
        _incidentCode = _generateIncidentCode();
      });
    }
  }

  String _generateIncidentCode() =>
      'INC-${DateTime.now().millisecondsSinceEpoch.remainder(1000000)}';

  EteeloErrorType _mapErrorType(ClassroomErrorType type) => switch (type) {
    ClassroomErrorType.network => EteeloErrorType.network,
    ClassroomErrorType.unauthorized ||
    ClassroomErrorType.auth ||
    ClassroomErrorType.invalidCredentials => EteeloErrorType.unauthorized,
    ClassroomErrorType.server ||
    ClassroomErrorType.storage => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return BlocListener<ClassroomBloc, ClassroomState>(
      listenWhen: (previous, current) =>
          previous.distributionStatus != current.distributionStatus,
      listener: (_, state) => _onBlocState(state),
      // Pendant le traitement, la sortie est neutralisée (croix masquée, scrim
      // non-dismissible ET bouton retour système) : une issue est toujours
      // rendue avant fermeture.
      child: PopScope(
        canPop: _phase != _Phase.processing && !_awaitingBloc,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppDimensions.classesDistributionResultModalMaxWidth,
              maxHeight: maxHeight,
            ),
            child: _phase == _Phase.error
                ? _buildErrorCard(context)
                : _buildResultCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: EteeloErrorResult(
        type: _errorType,
        title: l10n.classesDistributionErrorTitle,
        message: l10n.classesDistributionErrorMessage,
        incidentCodeLabel: _incidentCode,
        secondaryAction: TextButton(
          onPressed: _close,
          child: Text(l10n.classesDistributionClose),
        ),
        primaryAction: FilledButton.icon(
          onPressed: _runDistribution,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terreCuite,
            foregroundColor: AppColors.blancCasse,
            minimumSize: const Size(0, AppDimensions.minTouchTarget),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.classesDistributionRetry),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        boxShadow: AppElevation.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultHeader(
            levelName: widget.levelName,
            // Pas de fermeture pendant le traitement.
            onClose: _phase == _Phase.processing ? null : _close,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: _phase == _Phase.processing
                  ? const _ProcessingBody()
                  : _SuccessBody(onClose: _close),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête sombre Kuba : eyebrow « Répartition par genre » + niveau + croix.
class _ResultHeader extends StatelessWidget {
  final String levelName;
  final VoidCallback? onClose;

  const _ResultHeader({required this.levelName, this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingL,
              AppDimensions.spacingM,
              AppDimensions.spacingS,
              AppDimensions.spacingM,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.classesDistributionResultEyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.orDoux,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        levelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.totalAmountLora.copyWith(
                          fontSize: 20,
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textOnDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingBody extends StatelessWidget {
  const _ProcessingBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const EteeloResultMedallion(kind: EteeloResultKind.processing),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.classesDistributionProcessingTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final VoidCallback onClose;

  const _SuccessBody({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const EteeloResultMedallion(kind: EteeloResultKind.success),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.classesDistributionSuccessTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          l10n.classesDistributionSuccessSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        const _DistributionRecap(),
        const SizedBox(height: AppDimensions.spacingL),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bleuArdoise,
              foregroundColor: AppColors.blancCasse,
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.classesDistributionClose),
          ),
        ),
      ],
    );
  }
}

/// Récapitulatif « effectif par classe », alimenté par l'aperçu rechargé.
class _DistributionRecap extends StatelessWidget {
  const _DistributionRecap();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ClassroomBloc, ClassroomState>(
      buildWhen: (previous, current) =>
          previous.distributionOverviewStatus !=
              current.distributionOverviewStatus ||
          previous.distributionOverview != current.distributionOverview,
      builder: (context, state) {
        if (state.distributionOverviewStatus != ClassroomStatus.success) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
            child: SizedBox(
              width: AppDimensions.spacingL,
              height: AppDimensions.spacingL,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final classrooms = state.distributionOverview?.classrooms ?? const [];
        if (classrooms.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.classesDistributionRecapTitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            for (final classroom in classrooms) ...[
              _RecapRow(
                name: classroom.classroom.name,
                count: classroom.members.length,
              ),
              const SizedBox(height: AppDimensions.spacingXS),
            ],
          ],
        );
      },
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String name;
  final int count;

  const _RecapRow({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            l10n.classesDistributionClassHeadcount(count),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
