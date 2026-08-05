import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/documents_local_dossier_cubit.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_group_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Catalogue des pièces d'un élève — second temps du parcours (§00).
///
/// Le catalogue est **le contenu du dossier possible**, pas la liste des pièces
/// déjà émises : chaque groupe est affiché même vide, et l'issue de chaque
/// document vit dans sa ligne.
///
/// Le back n'expose aucun listing des pièces d'un élève : « dernière émission »,
/// historique des versions et comptage n'ont donc aucune source de vérité, et
/// aucune n'est simulée localement — une tablette qui affirmerait « jamais
/// émis » sur une pièce produite depuis un autre poste serait menteuse.
class DocumentsCatalogPage extends StatelessWidget {
  /// Largeur maximale du contenu, conforme au plafond de 880 dp de la spec.
  static const double _contentMaxWidth = 880;

  final DocumentsCatalogIntent intent;

  const DocumentsCatalogPage({super.key, required this.intent});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Le serveur connaît-il déjà cet élève ? Garde des trois pièces
        // scopées élève (note de perception, relevé, quitus).
        BlocProvider<EditiqueEligibilityCubit>(
          create: (_) =>
              getIt<EditiqueEligibilityCubit>()
                ..resolveForStudent(intent.studentId),
        ),
        // Ce que cette tablette sait du dossier : axe de synchro (garde de
        // l'attestation), pièces déjà scellées localement, et celles dont elle
        // détient les octets — les seules consultables hors ligne.
        BlocProvider<DocumentsLocalDossierCubit>(
          create: (_) => getIt<DocumentsLocalDossierCubit>()
            ..load(
              intent.enrollmentId,
              studentId: intent.studentId,
              academicYearId: intent.academicYearId,
            ),
        ),
      ],
      child: AppPageBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CatalogHeader(intent: intent),
                  const SizedBox(height: AppDimensions.spacingL),
                  _CatalogGroups(intent: intent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les cartes de groupe, recalculées dès qu'une garde bouge.
class _CatalogGroups extends StatelessWidget {
  final DocumentsCatalogIntent intent;

  const _CatalogGroups({required this.intent});

  @override
  Widget build(BuildContext context) {
    // B-2 : le relevé et le quitus sont des émissions serveur — grisés hors
    // ligne, avec un message. `authRequired` reste ACTIF : une émission en 401
    // est une erreur traitée par l'anatomie, alors qu'un grisage muet cacherait
    // une session à rouvrir.
    final isOffline =
        context.watch<SyncStatusCubit>().state.status == SyncStatus.offline;

    return BlocBuilder<EditiqueEligibilityCubit, EditiqueEligibilityState>(
      builder: (context, eligibility) {
        return BlocBuilder<
          DocumentsLocalDossierCubit,
          DocumentsLocalDossierState
        >(
          builder: (context, dossier) {
            DocumentsCatalogAction resolve(EditiqueCatalogEntry entry) =>
                DocumentsCatalogAction.resolve(
                  entry: entry,
                  isStudentKnownToServer: switch (eligibility.status) {
                    EditiqueEligibilityStatus.resolving => null,
                    EditiqueEligibilityStatus.eligible => true,
                    EditiqueEligibilityStatus.blocked => false,
                  },
                  isOffline: isOffline,
                  enrollmentId: intent.enrollmentId,
                  enrollmentSyncState: dossier.enrollmentSyncState,
                  isDossierLoaded: dossier.loaded,
                  knownPieces: dossier.knownPieces,
                  cachedPieces: dossier.cachedPieces,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final group in EditiqueCatalogGroup.values) ...[
                  DocumentsCatalogGroupCard(
                    group: group,
                    intent: intent,
                    actionResolver: resolve,
                  ),
                  if (group != EditiqueCatalogGroup.values.last)
                    const SizedBox(height: AppDimensions.spacingL),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// En-tête compact : retour, identité de l'élève, sur-titre de classe.
///
/// Volontairement clair et non l'AppBar sombre pleine largeur de la spec : une
/// AppBar sombre a déjà été refusée sur la coquille de fiche élève de la
/// Discipline, et ce module n'a pas à trancher seul un parti pris de charte qui
/// dépasse son périmètre.
class _CatalogHeader extends StatelessWidget {
  final DocumentsCatalogIntent intent;

  const _CatalogHeader({required this.intent});

  void _onExit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutesNames.documentsStudents);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eyebrow = [
      l10n.documentsCatalogEyebrow,
      if (intent.levelName.trim().isNotEmpty) intent.levelName,
    ].join(' · ');

    return Row(
      children: [
        IconButton(
          onPressed: () => _onExit(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textSecondary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        core_avatar.StudentAvatar(
          firstName: intent.firstName,
          lastName: intent.lastName,
          studentId: intent.studentId,
          size: core_avatar.AvatarSize.md,
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _fullName(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Nom complet, ou repli explicite : un lien profond rechargé perd le contexte
  /// d'affichage transporté par `extra`, mais le catalogue reste ouvrable.
  String _fullName(AppLocalizations l10n) {
    if (!intent.hasDisplayContext) return l10n.documentsCatalogUnknownStudent;
    return [
      intent.lastName,
      intent.surname,
      intent.firstName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }
}
