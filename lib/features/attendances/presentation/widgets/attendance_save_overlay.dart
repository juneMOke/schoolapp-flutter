import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> showAttendanceSaveOverlay({
  required BuildContext context,
  required AttendanceBloc attendanceBloc,
  required String classroomName,
  required DateTime date,
  required int presentCount,
  required int justifiedCount,
  required int unjustifiedCount,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<AttendanceBloc>.value(
      value: attendanceBloc,
      child: AttendanceSaveOverlay(
        classroomName: classroomName,
        date: date,
        presentCount: presentCount,
        justifiedCount: justifiedCount,
        unjustifiedCount: unjustifiedCount,
      ),
    ),
  );
}

enum _Phase { processing, success, error }

class AttendanceSaveOverlay extends StatefulWidget {
  final String classroomName;
  final DateTime date;
  final int presentCount;
  final int justifiedCount;
  final int unjustifiedCount;

  const AttendanceSaveOverlay({
    super.key,
    required this.classroomName,
    required this.date,
    required this.presentCount,
    required this.justifiedCount,
    required this.unjustifiedCount,
  });

  @override
  State<AttendanceSaveOverlay> createState() => _AttendanceSaveOverlayState();
}

class _AttendanceSaveOverlayState extends State<AttendanceSaveOverlay> {
  _Phase _phase = _Phase.processing;
  bool _awaitingBloc = false;
  EteeloErrorType _errorType = EteeloErrorType.unknown;
  String? _incidentCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSave();
    });
  }

  void _startSave() {
    if (_awaitingBloc) return;
    setState(() {
      _phase = _Phase.processing;
      _awaitingBloc = true;
    });
    context.read<AttendanceBloc>().add(const AttendanceSaveRequested());
  }

  void _onBlocState(AttendanceState state) {
    if (!mounted || !_awaitingBloc) return;
    if (state.saveStatus == AttendanceStatus.success) {
      _awaitingBloc = false;
      setState(() => _phase = _Phase.success);
    } else if (state.saveStatus == AttendanceStatus.failure) {
      _awaitingBloc = false;
      setState(() {
        _phase = _Phase.error;
        _errorType = _mapErrorType(state.saveErrorType);
        _incidentCode = _generateIncidentCode();
      });
    }
  }

  String _generateIncidentCode() =>
      'ATT-${DateTime.now().millisecondsSinceEpoch.remainder(1000000)}';

  EteeloErrorType _mapErrorType(AttendanceErrorType type) => switch (type) {
    AttendanceErrorType.network => EteeloErrorType.network,
    AttendanceErrorType.unauthorized ||
    AttendanceErrorType.auth ||
    AttendanceErrorType.invalidCredentials => EteeloErrorType.unauthorized,
    AttendanceErrorType.forbidden => EteeloErrorType.forbidden,
    AttendanceErrorType.server ||
    AttendanceErrorType.storage => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
      listener: (context, state) => _onBlocState(state),
      child: PopScope(
        canPop: _phase != _Phase.processing,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingXL,
          ),
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OverlayHeader(
                classroomName: widget.classroomName,
                date: widget.date,
                onClose: _phase != _Phase.processing
                    ? () => Navigator.of(context).pop()
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingXL),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_phase),
                    child: switch (_phase) {
                      _Phase.processing => _ProcessingBody(l10n: l10n),
                      _Phase.success => _SuccessBody(
                        l10n: l10n,
                        presentCount: widget.presentCount,
                        justifiedCount: widget.justifiedCount,
                        unjustifiedCount: widget.unjustifiedCount,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      _Phase.error => _ErrorBody(
                        l10n: l10n,
                        errorType: _errorType,
                        incidentCode: _incidentCode,
                        onRetry: _startSave,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  final String classroomName;
  final DateTime date;
  final VoidCallback? onClose;

  const _OverlayHeader({
    required this.classroomName,
    required this.date,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatShortDate(date);

    return SizedBox(
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
              ),
            ),
          ),
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.attendanceSaveOverlayEyebrow.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classroomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.totalAmountLora.copyWith(
                          fontSize: 18,
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.8),
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
  final AppLocalizations l10n;

  const _ProcessingBody({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EteeloResultMedallion(kind: EteeloResultKind.processing),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.attendanceSaveProcessingTitle,
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
  final AppLocalizations l10n;
  final int presentCount;
  final int justifiedCount;
  final int unjustifiedCount;
  final VoidCallback onClose;

  const _SuccessBody({
    required this.l10n,
    required this.presentCount,
    required this.justifiedCount,
    required this.unjustifiedCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EteeloResultMedallion(kind: EteeloResultKind.success),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.attendanceSaveSuccessTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          l10n.attendanceSaveSuccessSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _RecapPills(
          l10n: l10n,
          presentCount: presentCount,
          justifiedCount: justifiedCount,
          unjustifiedCount: unjustifiedCount,
        ),
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
            child: Text(l10n.attendanceSaveCloseAction),
          ),
        ),
      ],
    );
  }
}

class _RecapPills extends StatelessWidget {
  final AppLocalizations l10n;
  final int presentCount;
  final int justifiedCount;
  final int unjustifiedCount;

  const _RecapPills({
    required this.l10n,
    required this.presentCount,
    required this.justifiedCount,
    required this.unjustifiedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      alignment: WrapAlignment.center,
      children: [
        _Pill(
          count: presentCount,
          label: l10n.attendancePresentCount,
          color: AppColors.success,
        ),
        _Pill(
          count: justifiedCount,
          label: l10n.attendanceJustifiedCount,
          color: AppColors.warning,
        ),
        _Pill(
          count: unjustifiedCount,
          label: l10n.attendanceUnjustifiedCount,
          color: AppColors.danger,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _Pill({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final AppLocalizations l10n;
  final EteeloErrorType errorType;
  final String? incidentCode;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorBody({
    required this.l10n,
    required this.errorType,
    required this.incidentCode,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return EteeloErrorResult(
      type: errorType,
      title: l10n.attendanceSaveErrorTitle,
      message: l10n.attendanceSaveErrorMessage,
      incidentCodeLabel: incidentCode,
      primaryAction: FilledButton(
        onPressed: onRetry,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppDimensions.minTouchTarget),
          shape: const StadiumBorder(),
        ),
        child: Text(l10n.attendanceSaveRetryAction),
      ),
      secondaryAction: TextButton(
        onPressed: onClose,
        child: Text(l10n.attendanceSaveCloseAction),
      ),
    );
  }
}
