import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/audience_section.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_back_bar.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_page_header.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/content_section.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/diffusion_section.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_banners.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_failure_banner.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois sections de l'éditeur, précédées du retour, du titre et des
/// bandeaux.
class EditorForm extends StatelessWidget {
  final AnnouncementEditorState state;
  final VoidCallback onBack;
  final DateTime now;
  final List<SchoolLevelGroupBundle> groups;

  const EditorForm({
    super.key,
    required this.state,
    required this.onBack,
    required this.now,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AnnouncementEditorCubit>();
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommunicationBackBar(onBack: state.busy == null ? onBack : null),
        const SizedBox(height: AppSpacing.md),
        CommunicationPageHeader(
          eyebrow: l10n.menuCommunication,
          title: state.isNew
              ? l10n.communicationNew
              : l10n.communicationEditTitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        EditorStatusBanner(state: state, now: now),
        if (failure != null) ...[
          EditorFailureBanner(
            failure: failure,
            gesture: state.failedGesture,
            refusal: state.refusal,
            onRetry: cubit.retry,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ContentSection(
          state: state,
          onCategory: cubit.setCategory,
          onTitle: cubit.setTitle,
          onBody: cubit.setBody,
        ),
        const SizedBox(height: AppSpacing.lg),
        AudienceSection(state: state, groups: groups),
        const SizedBox(height: AppSpacing.lg),
        DiffusionSection(
          number: 3,
          state: state,
          now: now,
          onToggleChannel: cubit.toggleChannel,
          onSendMode: cubit.setSendMode,
          onScheduledAt: cubit.setScheduledAt,
        ),
      ],
    );
  }
}
