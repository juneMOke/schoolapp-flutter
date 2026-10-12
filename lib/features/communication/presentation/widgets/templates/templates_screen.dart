import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_back_bar.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_page_header.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/states/communication_results_error_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/templates/template_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La grille des modèles. Deux usages : le menu Modèles (créer, modifier,
/// supprimer, utiliser) et le choix depuis la liste ([onBack] posé : lecture
/// seule, une seule action, « Utiliser »).
class TemplatesScreen extends StatelessWidget {
  final ValueChanged<AnnouncementTemplate>? onUse;
  final VoidCallback? onCreate;
  final ValueChanged<AnnouncementTemplate>? onEdit;
  final ValueChanged<AnnouncementTemplate>? onDelete;

  /// Mode choix : la barre « ← Communiqués ».
  final VoidCallback? onBack;

  const TemplatesScreen({
    super.key,
    this.onUse,
    this.onCreate,
    this.onEdit,
    this.onDelete,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final create = onCreate;
    final back = onBack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (back != null) ...[
          CommunicationBackBar(onBack: back),
          const SizedBox(height: AppSpacing.md),
        ],
        CommunicationPageHeader(
          eyebrow: l10n.menuCommunication,
          title: back == null
              ? l10n.subMenuAnnouncementTemplates
              : l10n.communicationTemplatePickTitle,
          subtitle: back == null
              ? l10n.communicationTemplatesSubtitle
              : l10n.communicationTemplatePickSubtitle,
          actions: [
            if (create != null)
              EteeloButton.primary(
                label: l10n.communicationTemplateCreate,
                icon: Icons.add,
                onPressed: create,
                fullWidth: false,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<AnnouncementTemplatesCubit, AnnouncementTemplatesState>(
          builder: (context, state) => _body(context, state),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, AnnouncementTemplatesState state) {
    final l10n = AppLocalizations.of(context)!;
    final failure = state.failure;
    final create = onCreate;
    return switch (state.status) {
      TemplatesStatus.loading => EteeloListSkeleton(
        rowCount: 4,
        pillCount: 1,
        showAvatar: false,
        semanticsLabel: l10n.communicationTemplatesLoading,
      ),
      TemplatesStatus.failure => CommunicationResultsErrorState(
        failure: failure ?? const ServerFailure(),
        onRetry: context.read<AnnouncementTemplatesCubit>().load,
      ),
      _ when state.items.isEmpty => EteeloEmptyResult(
        label: l10n.communicationTemplatesEmptyTitle,
        description: l10n.communicationTemplatesEmptyMessage,
        medallionIcon: Icons.dashboard_customize_outlined,
        fullWidthCard: true,
        primaryAction: create == null
            ? null
            : EteeloButton.primary(
                label: l10n.communicationTemplateCreate,
                icon: Icons.add,
                onPressed: create,
                fullWidth: false,
              ),
      ),
      _ => EteeloGridView(
        itemCount: state.items.length,
        padding: EdgeInsets.zero,
        minItemWidth: AppDimensions.communicationTemplateCardMinWidth,
        spacing: AppSpacing.lg,
        itemBuilder: (context, index) {
          final template = state.items[index];
          final use = onUse;
          final edit = onEdit;
          final delete = onDelete;
          return TemplateCard(
            key: ValueKey(template.id),
            template: template,
            onUse: use == null ? null : () => use(template),
            onEdit: edit == null ? null : () => edit(template),
            onDelete: delete == null ? null : () => delete(template),
          );
        },
      ),
    };
  }
}
