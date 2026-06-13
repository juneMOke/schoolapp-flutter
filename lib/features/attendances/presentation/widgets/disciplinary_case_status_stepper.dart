import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Frise (lecture seule) du cycle de vie d'un cas : Ouvert → En cours →
/// Clôturé (3 statuts de l'enum backend). Étapes franchies = coche verte ;
/// étape courante = icône pleine colorée + libellé gras ; suivantes grises.
class DisciplinaryCaseStatusStepper extends StatelessWidget {
  final DisciplinaryCaseStatus status;

  const DisciplinaryCaseStatusStepper({super.key, required this.status});

  static const _flow = [
    DisciplinaryCaseStatus.open,
    DisciplinaryCaseStatus.inProgress,
    DisciplinaryCaseStatus.closed,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _flow.indexOf(status);

    final items = <Widget>[];
    for (var i = 0; i < _flow.length; i++) {
      if (i > 0) {
        items.add(_Connector(crossed: current >= i));
      }
      items.add(
        _Step(status: _flow[i], state: _stateFor(i, current), l10n: l10n),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacingXS,
      runSpacing: AppDimensions.spacingXS,
      children: items,
    );
  }

  _StepState _stateFor(int index, int current) {
    if (current < 0 || index > current) return _StepState.upcoming;
    if (index < current) return _StepState.done;
    return _StepState.current;
  }
}

enum _StepState { done, current, upcoming }

class _Step extends StatelessWidget {
  final DisciplinaryCaseStatus status;
  final _StepState state;
  final AppLocalizations l10n;

  const _Step({required this.status, required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color foreground,
      IconData icon,
      Border? border,
    ) = switch (state) {
      _StepState.done => (
        AppColors.vertSavane,
        AppColors.textOnDark,
        Icons.check_rounded,
        null,
      ),
      _StepState.current => (
        status.getColor(),
        AppColors.textOnDark,
        status.getIcon(),
        null,
      ),
      _StepState.upcoming => (
        AppColors.surfaceAlt,
        AppColors.textMuted,
        status.getIcon(),
        Border.all(color: AppColors.borderStrong),
      ),
    };

    final labelColor = switch (state) {
      _StepState.done => AppColors.textSecondary,
      _StepState.current => status.getColor(),
      _StepState.upcoming => AppColors.textMuted,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppDimensions.disciplinaryStepperDotSize,
          height: AppDimensions.disciplinaryStepperDotSize,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Icon(
            icon,
            size: AppDimensions.disciplinaryStepperIconSize,
            color: foreground,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          status.getDisplayName(l10n),
          style: AppTextStyles.caption.copyWith(
            color: labelColor,
            fontWeight: state == _StepState.current
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  final bool crossed;

  const _Connector({required this.crossed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.disciplinaryStepperConnectorWidth,
      height: AppDimensions.disciplinaryStepperConnectorHeight,
      decoration: BoxDecoration(
        color: crossed ? AppColors.vertSavane : AppColors.border,
        borderRadius: AppRadius.brPill,
      ),
    );
  }
}
