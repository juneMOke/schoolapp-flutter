import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcements_list_screen.dart';

/// Communication ▸ Communiqués.
class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final yearId = context
        .read<AcademicYearContextBloc>()
        .state
        .context
        ?.academicYear
        .id;
    return BlocProvider<AnnouncementsCubit>(
      create: (_) =>
          GetIt.instance<AnnouncementsCubit>()..load(academicYearId: yearId),
      child: AppPageBackground(
        scrollable: true,
        child: AnnouncementsListScreen(onOpen: (_) {}),
      ),
    );
  }
}
