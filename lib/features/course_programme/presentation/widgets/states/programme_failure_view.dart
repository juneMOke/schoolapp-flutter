import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_state.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/my_courses_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/states/programme_error_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// L'erreur d'une lecture du programme, selon sa source :
/// - la base de la tablette ([StorageFailure], ou rien de plus précis) :
///   « illisible », avec « Réessayer » ;
/// - la lecture en ligne (la direction) : les quatre familles de la charte —
///   réseau, 401 (se reconnecter), 403 (contacter l'administrateur, jamais
///   « Réessayer »), 500 — celles de la liste des cours.
class ProgrammeFailureView extends StatelessWidget {
  final Failure? failure;
  final VoidCallback onRetry;
  final String? localTitle;
  final String? localMessage;

  const ProgrammeFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.localTitle,
    this.localMessage,
  });

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    if (failure == null || failure is StorageFailure) {
      return ProgrammeResultsErrorState(
        title: localTitle,
        message: localMessage,
        onRetry: onRetry,
      );
    }
    return MyCoursesResultsErrorState(
      type: CourseErrorType.of(failure),
      onRetry: onRetry,
      onReconnect: () =>
          context.read<AuthBloc>().add(const AuthLogoutRequested()),
      onContactAdmin: () =>
          launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail)),
    );
  }
}
