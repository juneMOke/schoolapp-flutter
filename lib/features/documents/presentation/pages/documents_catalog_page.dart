import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
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

  /// Sur-titre de la barre : « DOCUMENTS · {classe} ».
  String _eyebrow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.documentsCatalogEyebrow,
      if (intent.levelName.trim().isNotEmpty) intent.levelName,
    ].join(' · ');
  }

  /// Nom complet, ou repli explicite : un lien profond rechargé perd le contexte
  /// d'affichage transporté par `extra`, mais le catalogue reste ouvrable.
  String _fullName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!intent.hasDisplayContext) return l10n.documentsCatalogUnknownStudent;
    return [
      intent.lastName,
      intent.surname,
      intent.firstName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

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
        appBar: StudentDetailAppBar(
          fullName: _fullName(context),
          eyebrow: _eyebrow(context),
          firstName: intent.firstName,
          lastName: intent.lastName,
          fallbackRoute: AppRoutesNames.documentsStudents,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: _CatalogGroups(intent: intent),
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
