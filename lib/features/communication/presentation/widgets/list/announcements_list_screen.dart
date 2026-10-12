import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_state.dart';
import 'package:school_app_flutter/features/communication/presentation/projections/announcement_list_view.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_page_header.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcement_filters_card.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcement_group_list.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/states/announcements_empty_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/states/communication_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Communication ▸ Communiqués, la liste : l'en-tête reste visible dans tous
/// les états ; la barre de filtres n'apparaît qu'avec des communiqués.
class AnnouncementsListScreen extends StatelessWidget {
  final ValueChanged<Announcement> onOpen;

  /// Les actions de l'en-tête (nouveau, partir d'un modèle), `null` quand
  /// l'écriture n'est pas permise.
  final VoidCallback? onCreate;
  final VoidCallback? onUseTemplate;

  const AnnouncementsListScreen({
    super.key,
    required this.onOpen,
    this.onCreate,
    this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommunicationPageHeader(
          eyebrow: l10n.menuCommunication,
          title: l10n.subMenuAnnouncements,
          subtitle: l10n.communicationListSubtitle,
          actions: _headerActions(
            l10n,
            onCreate: onCreate,
            onUseTemplate: onUseTemplate,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<AnnouncementsCubit, AnnouncementsState>(
          builder: (context, state) => _body(context, state),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, AnnouncementsState state) {
    final cubit = context.read<AnnouncementsCubit>();
    final failure = state.failure;
    if (state.status == AnnouncementsStatus.loading) {
      return EteeloListSkeleton(
        rowCount: 5,
        pillCount: 1,
        semanticsLabel: AppLocalizations.of(context)!.communicationLoading,
      );
    }
    if (state.status == AnnouncementsStatus.failure && failure != null) {
      return CommunicationResultsErrorState(
        failure: failure,
        onRetry: cubit.load,
      );
    }
    if (state.items.isEmpty) {
      return AnnouncementsEmptyState(
        filtered: false,
        onClearFilters: cubit.clearFilters,
        onCreate: onCreate,
        onUseTemplate: onUseTemplate,
      );
    }
    final view = AnnouncementListView.of(state.items, state.filters);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnouncementFiltersCard(
          filters: state.filters,
          view: view,
          onQueryChanged: cubit.setQuery,
          onToggleStatus: cubit.toggleStatus,
          onToggleCategory: cubit.toggleCategory,
          onClear: cubit.clearFilters,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (view.isEmpty)
          AnnouncementsEmptyState(
            filtered: true,
            onClearFilters: cubit.clearFilters,
          )
        else
          AnnouncementGroupList(view: view, now: cubit.now(), onOpen: onOpen),
      ],
    );
  }
}

/// Les actions de l'en-tête : « Modèle » (partir d'un modèle), puis
/// « Nouveau communiqué ». Absentes sans le droit d'envoyer.
List<Widget> _headerActions(
  AppLocalizations l10n, {
  VoidCallback? onCreate,
  VoidCallback? onUseTemplate,
}) => [
  if (onUseTemplate != null)
    EteeloButton.secondary(
      label: l10n.communicationTemplateButton,
      icon: Icons.dashboard_customize_outlined,
      onPressed: onUseTemplate,
      fullWidth: false,
    ),
  if (onCreate != null)
    EteeloButton.primary(
      label: l10n.communicationNew,
      icon: Icons.add,
      onPressed: onCreate,
      fullWidth: false,
    ),
];
