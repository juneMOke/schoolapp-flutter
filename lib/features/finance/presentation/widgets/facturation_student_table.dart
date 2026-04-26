import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_pagination_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';

/// Point d'entrée public de la section résultats de la page Facturation.
///
/// Responsabilité unique : écouter [EnrollmentBloc] et router vers le bon
/// widget selon l'état courant. Toute logique de rendu est déléguée.
class FacturationStudentTable extends StatelessWidget {
  /// Appelé quand l'icône "œil" est tapée.
  /// [levelId] provient du dernier critère de recherche stocké dans l'état BLoC.
  final void Function(EnrollmentSummary summary, String levelId) onViewRequested;

  const FacturationStudentTable({super.key, required this.onViewRequested});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      buildWhen: _shouldBuild,
      builder: (context, state) {
        // Aucune recherche byAcademicInfo lancée → invitation à chercher
        if (state.summariesQueryType !=
            EnrollmentSummaryQueryType.byAcademicInfo) {
          return const FacturationSearchInvitationCard();
        }

        final levelId = state.lastSummariesQuery?.schoolLevelId ?? '';
        final isLoading = state.summariesStatus == EnrollmentLoadStatus.loading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FacturationDataTable(
              isLoading: isLoading,
              summaries: state.summaries,
              onViewRequested: (s) => onViewRequested(s, levelId),
            ),
            const SizedBox(height: 10),
            if (state.summariesTotalPages > 1)
              FacturationPaginationBar(
                currentPage: state.summariesPage,
                totalPages: state.summariesTotalPages,
                isLoading: isLoading,
                onPrevious: () => context.read<EnrollmentBloc>().add(
                  EnrollmentSummariesPageRequested(
                    page: state.summariesPage - 1,
                  ),
                ),
                onNext: () => context.read<EnrollmentBloc>().add(
                  EnrollmentSummariesPageRequested(
                    page: state.summariesPage + 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _shouldBuild(EnrollmentState prev, EnrollmentState curr) =>
      prev.summariesQueryType != curr.summariesQueryType ||
      prev.summariesStatus != curr.summariesStatus ||
      prev.summaries != curr.summaries ||
      prev.summariesTotalPages != curr.summariesTotalPages ||
      prev.summariesPage != curr.summariesPage;
}
