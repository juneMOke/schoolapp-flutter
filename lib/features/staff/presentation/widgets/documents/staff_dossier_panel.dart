import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_flow.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_failure_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/documents/staff_document_tile.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/documents/staff_document_viewer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les pièces du dossier d'un agent enregistré, sous l'étape « Diplômes &
/// pièces » : celles que son contrat exige d'abord, puis celles versées en
/// plus.
///
/// Comme un contrat, une pièce ne passe jamais par la fiche : elle est scellée
/// sur la tablette et part par sa propre file.
class StaffDossierPanel extends StatelessWidget {
  final StaffMember member;
  final String today;

  const StaffDossierPanel({
    super.key,
    required this.member,
    required this.today,
  });

  Future<void> _add(BuildContext context, StaffDocumentType type) async {
    final cubit = context.read<StaffDossierCubit>();
    final captured = await getIt<DocumentCaptureFlow>().run(
      context,
      title: AppLocalizations.of(
        context,
      )!.staffDocumentCaptureTitle(type.label),
      policy: DocumentCapturePolicy.staffDocument,
    );
    if (captured == null) return;
    await cubit.add(member.id, type.rawCode, captured);
  }

  Future<void> _view(
    BuildContext context,
    StaffDocumentType type,
    StaffDocument document,
  ) async {
    final content = await context.read<StaffDossierCubit>().open(document);
    if (content == null || !context.mounted) return;
    await showStaffDocumentViewer(context, title: type.label, content: content);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRead = PermissionGate.allows(context, const [Perm.hrDocumentRead]);
    final canWrite = PermissionGate.allows(context, const [
      Perm.hrDocumentWrite,
    ]);
    if (!canRead && !canWrite) return const SizedBox.shrink();
    return BlocConsumer<StaffDossierCubit, StaffDossierState>(
      buildWhen: (previous, current) =>
          previous.dossier != current.dossier ||
          previous.loaded != current.loaded ||
          previous.busy != current.busy,
      listenWhen: (previous, current) =>
          current.outcomeSeq != previous.outcomeSeq,
      listener: (context, state) {
        switch (state.outcome) {
          case StaffDocumentOutcome.saved:
            AppSnackBar.showSuccess(context, l10n.staffDocumentSaved);
          case StaffDocumentOutcome.saveFailed:
            AppSnackBar.showError(
              context,
              StaffFailureMessages.save(
                l10n,
                state.failure,
                fallback: l10n.staffDocumentSaveFailed,
              ),
            );
          case StaffDocumentOutcome.openFailed:
            AppSnackBar.showError(
              context,
              StaffFailureMessages.open(l10n, state.failure),
            );
          case null:
            break;
        }
      },
      builder: (context, state) {
        final snapshot = state.dossier;
        final kind = StaffContractTimeline.currentAt(
          member.contracts,
          today,
        )?.kind;
        final dossier = StaffDossier.of(
          kind: kind,
          types: snapshot.types,
          documents: snapshot.documents,
        );
        final required = {for (final type in dossier.required) type.rawCode};
        final types = [
          ...dossier.required,
          for (final type in snapshot.types)
            if (!required.contains(type.rawCode) &&
                snapshot.currentOf(type.rawCode) != null)
              type,
        ];
        return StaffFormBlock(
          title: l10n.staffBlockDossier,
          subtitle: dossier.isKnown
              ? l10n.staffDossierProgress(dossier.done, dossier.total)
              : l10n.staffBlockDossierHint,
          icon: Icons.folder_open_outlined,
          color: StaffStepStyle.of(3).color,
          children: [
            // Un versement ou un téléchargement peut prendre du temps : les
            // boutons se taisent, la barre dit que quelque chose se passe.
            if (state.busy)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: LinearProgressIndicator(),
              ),
            if (!state.loaded)
              EteeloListSkeleton(
                rowCount: 3,
                pillCount: 1,
                showAvatar: false,
                semanticsLabel: l10n.staffDossierLoading,
              )
            else if (types.isEmpty)
              Text(
                l10n.staffDossierUnknown,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (state.loaded)
              for (final type in types)
                StaffDocumentTile(
                  type: type,
                  document: snapshot.currentOf(type.rawCode),
                  required: required.contains(type.rawCode),
                  memberPending: member.syncState != RecordSyncState.synced,
                  onAdd: canWrite && !state.busy
                      ? () => unawaited(_add(context, type))
                      : null,
                  onView: canRead && !state.busy
                      ? () => unawaited(
                          _view(
                            context,
                            type,
                            snapshot.currentOf(type.rawCode)!,
                          ),
                        )
                      : null,
                ),
            const SizedBox(height: AppSpacing.xs),
          ],
        );
      },
    );
  }
}
