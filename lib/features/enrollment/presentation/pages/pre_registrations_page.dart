import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registrations_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';

class PreRegistrationsPage extends StatelessWidget {
  const PreRegistrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<EnrollmentBloc>()
        ..add(
          const EnrollmentSummariesRequested(
            status: 'PRE_REGISTERED',
            academicYearId: '42c64ea3-89e7-4872-8a1c-757f7add33b4',
          ),
        ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4F8FF), Color(0xFFEFF5FF), Color(0xFFF7FAFF)],
            ),
          ),
          child: Stack(
            children: [
              // ── Cercles décoratifs ────────────────────────────────
              Positioned(
                top: -60,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // ── Contenu entièrement scrollable ───────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SearchForm(),
                    const SizedBox(height: 12),
                    BlocBuilder<EnrollmentBloc, EnrollmentState>(
                      builder: (context, state) => PreRegistrationsInfoBar(
                        count: state.summaries.length,
                        isLoading: _isLoading(state),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<EnrollmentBloc, EnrollmentState>(
                      builder: (context, state) => EnrollmentDataTable(
                        isLoading: _isLoading(state),
                        enrollments: state.summaries,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLoading(EnrollmentState state) =>
      state.summariesStatus == EnrollmentLoadStatus.loading;
}