import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/helpers/documents_page_helpers.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/documents_search_form.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/documents_student_table.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Liste du module Documents — premier temps du parcours (§00 de la spec) :
/// on trouve l'élève, puis on ouvre le catalogue de ses pièces.
///
/// La recherche est **100 % locale** et porte sur les élèves réellement
/// inscrits l'année courante, comme la Facturation : ce sont ceux pour qui une
/// pièce a un sens.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, academicYearState) {
          final status = academicYearState.status;

          if (status == AcademicYearContextLoadStatus.loading ||
              status == AcademicYearContextLoadStatus.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // Sans contexte académique, aucune pièce scopée élève n'est
          // adressable : les trois endpoints concernés exigent l'année.
          if (status != AcademicYearContextLoadStatus.success) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final options = DocumentsPageHelpers.buildAcademicOptions(
            academicYearState.context?.schoolLevelGroups ?? const [],
          );

          return AnimatedSwitcher(
            duration: AppMotion.layout,
            child: Column(
              key: const ValueKey('documents-content'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<EnrollmentLocalListBloc, EnrollmentLocalListState>(
                  buildWhen: (prev, curr) =>
                      prev.summariesStatus != curr.summariesStatus,
                  builder: (context, enrollmentState) => DocumentsSearchForm(
                    options: options,
                    isLoading:
                        enrollmentState.summariesStatus ==
                        EnrollmentLoadStatus.loading,
                    onSearch: (request) =>
                        context.read<EnrollmentLocalListBloc>().add(
                          LocalListByEnrolledAcademicInfoRequested(
                            academicYearId:
                                academicYearState.context?.academicYear.id ??
                                '',
                            firstName: request.firstName,
                            lastName: request.lastName,
                            surname: request.surname,
                            schoolLevelGroupId: request.schoolLevelGroupId,
                            schoolLevelId: request.schoolLevelId,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                DocumentsStudentTable(onCatalogRequested: _onCatalogRequested),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Ouvre le catalogue de l'élève tapé.
  ///
  /// L'année vient du contexte académique et non du résumé de recherche, qui ne
  /// la porte pas. Sans elle, on refuse la navigation plutôt que d'ouvrir un
  /// catalogue dont aucune pièce financière ne serait adressable.
  void _onCatalogRequested(EnrollmentSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';

    if (academicYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bootstrapContextUnavailableMessage)),
      );
      return;
    }

    final levelId = context
        .read<EnrollmentLocalListBloc>()
        .state
        .lastSummariesQuery
        ?.schoolLevelId;
    final labels = _levelLabels(
      academicYearContext?.schoolLevelGroups ?? const [],
      levelId,
    );

    context.push(
      AppRoutesNames.documentsCatalogPath(
        studentId: summary.student.id,
        academicYearId: academicYearId,
      ),
      extra: DocumentsCatalogIntent(
        studentId: summary.student.id,
        academicYearId: academicYearId,
        // Seule clé de l'attestation d'inscription, et elle ne transite pas par
        // l'URL : un lien profond ouvrira le catalogue sans elle.
        enrollmentId: summary.enrollmentId,
        firstName: summary.student.firstName,
        lastName: summary.student.lastName,
        surname: summary.student.surname,
        levelName: labels.$1,
        levelGroupName: labels.$2,
      ),
    );
  }

  /// (niveau, cycle) correspondant à [levelId].
  ///
  /// Vides quand la recherche s'est faite **par nom** : le résumé d'élève ne
  /// porte aucun niveau, et le dernier critère de recherche est la seule source
  /// disponible. Le catalogue s'affiche alors sans sur-titre de classe — c'est
  /// du contexte d'affichage, jamais une condition d'ouverture.
  (String, String) _levelLabels(
    List<SchoolLevelGroupBundle> bundles,
    String? levelId,
  ) {
    if (levelId == null || levelId.isEmpty) return ('', '');

    for (final bundle in bundles) {
      for (final level in bundle.levels) {
        if (level.id == levelId) return (level.name, bundle.group.name);
      }
    }
    return ('', '');
  }
}
