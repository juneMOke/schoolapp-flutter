import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_referential_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_student_search_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/communication_flow_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_factory.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_outcome_messages.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/communication_failure_text.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/announcement_editor_screen.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'éditeur, monté par la page Communiqués : un cubit neuf par ouverture.
/// Au bout d'un geste abouti, retour à la liste mise à jour, et un toast.
class AnnouncementEditorPage extends StatelessWidget {
  final CommunicationEditorScreen screen;
  final String? academicYearId;

  const AnnouncementEditorPage({
    super.key,
    required this.screen,
    required this.academicYearId,
  });

  @override
  Widget build(BuildContext context) {
    final factory = GetIt.instance<AnnouncementEditorFactory>();
    final existing = screen.announcement;
    final canSend = PermissionGate.allowsAccess(
      context,
      kAnnouncementSendAccess,
    );
    final flow = context.read<CommunicationFlowCubit>();
    final getIt = GetIt.instance;
    return MultiBlocProvider(
      providers: [
        BlocProvider<AnnouncementEditorCubit>(
          create: (_) => existing == null
              ? factory.create(
                  seed: screen.seed,
                  academicYearId: academicYearId,
                )
              : factory.edit(existing, readOnly: !canSend),
        ),
        // La première portée : celle de l'audience à l'ouverture.
        BlocProvider<AnnouncementReachCubit>(
          create: (context) => getIt<AnnouncementReachCubit>()
            ..update(
              context.read<AnnouncementEditorCubit>().state.content.audience,
            ),
        ),
        BlocProvider<AudienceReferentialCubit>(
          create: (_) =>
              getIt<AudienceReferentialCubit>()..load(academicYearId),
        ),
        BlocProvider<AudienceStudentSearchCubit>(
          create: (_) => getIt<AudienceStudentSearchCubit>(),
        ),
        BlocProvider<AnnouncementTemplatesCubit>(
          create: (_) => getIt<AnnouncementTemplatesCubit>(),
        ),
        BlocProvider<FeeSectionTitlesCubit>(
          create: (_) => getIt<FeeSectionTitlesCubit>()..load(),
        ),
      ],
      // Pas de défilement de page : l'éditeur défile lui-même, sous une barre
      // d'actions collante. Le `Builder` donne aux gestes un contexte sous les
      // fournisseurs ci-dessus.
      child: AppPageBackground(
        scrollable: false,
        child: Builder(
          builder: (context) => AnnouncementEditorScreen(
            schoolName: context.read<SchoolIdentityCubit>().state.school?.name,
            groups:
                context
                    .read<AcademicYearContextBloc>()
                    .state
                    .context
                    ?.schoolLevelGroups ??
                const [],
            onBack: flow.showList,
            onSaveAsTemplate:
                PermissionGate.allowsAccess(
                  context,
                  kAnnouncementTemplateWriteAccess,
                )
                ? () => _saveAsTemplate(context)
                : null,
            onDone: (outcome, announcement) {
              context.read<AnnouncementsCubit>().upsert(announcement);
              AppSnackBar.showSuccess(
                context,
                AppLocalizations.of(
                  context,
                )!.outcomeMessage(outcome, announcement, DateTime.now()),
              );
              flow.showList();
            },
          ),
        ),
      ),
    );
  }

  /// « Enregistrer comme modèle » : titre et message requis, l'éditeur reste
  /// ouvert.
  static Future<void> _saveAsTemplate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Lu au moment du geste : c'est la saisie à l'écran qui devient modèle.
    final content = context.read<AnnouncementEditorCubit>().state.content;
    if (content.title.trim().isEmpty || content.body.trim().isEmpty) {
      AppSnackBar.showWarning(context, l10n.communicationTemplateNeedsText);
      return;
    }
    final templates = context.read<AnnouncementTemplatesCubit>();
    final failure = await templates.create(
      category: content.category,
      title: content.title,
      body: content.body,
    );
    if (!context.mounted) return;
    if (failure == null) {
      AppSnackBar.showSuccess(context, l10n.communicationTemplateSaved);
    } else {
      AppSnackBar.showError(
        context,
        l10n.communicationTemplateSaveFailed(l10n.failureReason(failure)),
      );
    }
  }
}
