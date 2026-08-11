import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_freshness.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/disciplinary_status_ui.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart'
    show DisciplinaryCaseErrorType;
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_comments_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_state_body.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// Onglet « Cas disciplinaires » — **lecture 100 % locale** (DF-3) sur le BLoC
/// offline. Création, avancement (Ouvert→Pris en charge→Résolu) et classement
/// sans suite passent par des écritures locales + outbox ; la liste se rafraîchit
/// après chaque écriture.
class DisciplinaryCasesTab extends StatelessWidget {
  final String studentId;
  final String academicYearId;

  /// Callback déclenché depuis l'en-tête / l'état vide pour créer un cas.
  final VoidCallback? onCreateCase;

  const DisciplinaryCasesTab({
    super.key,
    required this.studentId,
    required this.academicYearId,
    this.onCreateCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      DisciplinaryCaseOfflineBloc,
      DisciplinaryCaseOfflineState
    >(
      // Après une écriture (création / avancement / classement), on recharge la
      // liste locale pour refléter le nouvel état.
      listenWhen: (prev, curr) =>
          curr is DisciplinaryOfflineCasePendingSync ||
          curr is DisciplinaryOfflineCaseUpdated,
      listener: (context, state) => _reload(context),
      // Ne reconstruit que sur les états d'affichage de liste : les états
      // transitoires d'écriture (Saving…) laissent la dernière liste à l'écran
      // (pas de clignotement vers le squelette).
      buildWhen: (prev, curr) =>
          curr is DisciplinaryOfflineInitial ||
          curr is DisciplinaryOfflineLoading ||
          curr is DisciplinaryOfflineCasesLoaded ||
          curr is DisciplinaryOfflineError,
      builder: (context, state) {
        final cases = state is DisciplinaryOfflineCasesLoaded
            ? state.cases
            : const <OfflineDisciplinaryCase>[];
        final total = cases.length;
        final open = cases
            .where(
              (c) =>
                  c.status == DisciplinaryStatus.open ||
                  c.status == DisciplinaryStatus.pending,
            )
            .length;
        final grave = cases
            .where((c) => c.severity == DisciplinarySeverity.serious)
            .length;

        final bodyStatus = switch (state) {
          DisciplinaryOfflineError() => DisciplinaryCasesBodyStatus.error,
          DisciplinaryOfflineCasesLoaded() when cases.isEmpty =>
            DisciplinaryCasesBodyStatus.empty,
          DisciplinaryOfflineCasesLoaded() =>
            DisciplinaryCasesBodyStatus.success,
          _ => DisciplinaryCasesBodyStatus.loading,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DisciplinaryCasesHeader(
                total: total,
                open: open,
                grave: grave,
                freshness: state is DisciplinaryOfflineCasesLoaded
                    ? state.freshness
                    : null,
                onCreateCase: onCreateCase,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              DisciplinaryCasesStateBody(
                status: bodyStatus,
                cases: cases,
                commentCounts: state is DisciplinaryOfflineCasesLoaded
                    ? state.commentCounts
                    : const {},
                // Lecture locale : l'erreur est une erreur de stockage (rare).
                errorType: DisciplinaryCaseErrorType.storage,
                onRetry: () => _reload(context),
                onReconnect: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
                onContactAdmin: _contactAdmin,
                onCreateCase: onCreateCase,
                onAdvance: (c) => _advance(context, c),
                onDismiss: (c) => _dismiss(context, c),
                onOpenComments: (c) => _openComments(context, c),
              ),
            ],
          ),
        );
      },
    );
  }

  void _reload(BuildContext context) {
    context.read<DisciplinaryCaseOfflineBloc>().add(
      LoadOfflineDisciplinaryCases(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
  }

  void _advance(BuildContext context, OfflineDisciplinaryCase c) {
    final target = c.status.advanceTarget;
    if (target == null) return;
    context.read<DisciplinaryCaseOfflineBloc>().add(
      UpdateOfflineDisciplinaryCase(
        caseId: c.id,
        status: target,
        sanction: c.sanction,
        expectedVersion: c.version,
      ),
    );
  }

  void _dismiss(BuildContext context, OfflineDisciplinaryCase c) {
    context.read<DisciplinaryCaseOfflineBloc>().add(
      UpdateOfflineDisciplinaryCase(
        caseId: c.id,
        status: DisciplinaryStatus.dismissed,
        sanction: c.sanction,
        expectedVersion: c.version,
      ),
    );
  }

  /// Ouvre le fil de commentaires dans un BLoC **dédié** (une instance neuve)
  /// pour ne pas perturber l'état de la liste ; au retour, on recharge la liste
  /// (le badge de commentaires reflète l'ajout).
  void _openComments(BuildContext context, OfflineDisciplinaryCase c) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<DisciplinaryCaseOfflineBloc>(
        create: (_) => GetIt.I<DisciplinaryCaseOfflineBloc>(),
        child: DisciplinaryCaseCommentsDialog(caseData: c),
      ),
    ).then((_) {
      if (context.mounted) _reload(context);
    });
  }

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
  }
}

class _DisciplinaryCasesHeader extends StatelessWidget {
  final int total;
  final int open;
  final int grave;
  final DisciplinaryFreshness? freshness;
  final VoidCallback? onCreateCase;

  const _DisciplinaryCasesHeader({
    required this.total,
    required this.open,
    required this.grave,
    required this.freshness,
    required this.onCreateCase,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Fraîcheur (ADR-002) : « À jour » si le pull a ramené toute l'année, sinon
    // « Poste local » (seules les écritures du poste sont visibles).
    final synced = freshness?.bootstrapComplete ?? false;

    final summary = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      children: [
        const Icon(
          Icons.assignment_outlined,
          size: 16,
          color: AppColors.textMuted,
        ),
        _Pill(
          label: l10n.disciplinaryCasesCountPill(total),
          background: AppColors.surfaceAlt,
          foreground: AppColors.textSecondary,
        ),
        if (open > 0)
          _Pill(
            label: l10n.disciplinaryCasesOpenPill(open),
            background: AppColors.error.withValues(alpha: 0.10),
            foreground: AppColors.error,
            icon: Icons.error_outline_rounded,
          ),
        if (grave > 0)
          _Pill(
            label: l10n.disciplinaryCasesGravePill(grave),
            background: AppColors.error.withValues(alpha: 0.10),
            foreground: AppColors.error,
            icon: Icons.warning_amber_rounded,
          ),
        if (freshness != null)
          _Pill(
            label: synced
                ? l10n.disciplinaryFreshnessSynced
                : l10n.disciplinaryFreshnessLocal,
            background: synced
                ? AppColors.vertSavane.withValues(alpha: 0.10)
                : AppColors.surfaceAlt,
            foreground: synced ? AppColors.vertSavane : AppColors.textMuted,
            icon: synced
                ? Icons.cloud_done_outlined
                : Icons.smartphone_outlined,
          ),
      ],
    );

    // L'onglet s'ouvre avec `discipline.read` : la création exige, elle,
    // l'écriture du domaine.
    final button = PermissionGate.access(
      kDisciplineInstructAccess,
      child: SessionWriteGate(
        child: PrimaryButton(
          label: l10n.disciplinaryCaseCreateAction,
          icon: Icons.add_rounded,
          fullWidth: false,
          onPressed: onCreateCase,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summary,
              const SizedBox(height: AppDimensions.spacingS),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: summary),
            const SizedBox(width: AppDimensions.spacingM),
            button,
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppDimensions.spacingXS),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: foreground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
