import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';

class FacturationDetailDataLoader extends StatefulWidget {
  final FacturationDetailIntent intent;
  final Widget child;

  const FacturationDetailDataLoader({
    super.key,
    required this.intent,
    required this.child,
  });

  @override
  State<FacturationDetailDataLoader> createState() =>
      _FacturationDetailDataLoaderState();
}

class _FacturationDetailDataLoaderState extends State<FacturationDetailDataLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestData();
    });
  }

  @override
  void didUpdateWidget(covariant FacturationDetailDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idsChanged =
        oldWidget.intent.studentId != widget.intent.studentId ||
        oldWidget.intent.academicYearId != widget.intent.academicYearId;
    if (!idsChanged) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestData();
    });
  }

  void _requestData() {
    context.read<PaymentsBloc>().add(
      PaymentsRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
      ),
    );

    context.read<StudentChargesBloc>().add(
      StudentChargesByAcademicYearRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
