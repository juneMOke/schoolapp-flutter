import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';
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

class _FacturationDetailDataLoaderState
    extends State<FacturationDetailDataLoader> {
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

  void _requestData({bool silent = false}) {
    // Les encaissements ne sont demandés que si la session a le droit de les
    // lire. Sans cette garde, un profil « créances seules » (le secrétariat)
    // déclenchait une lecture qui ne pouvait rien rendre, et la section
    // affichait « Aucun versement enregistré » — faux, et contredit par le
    // « Déjà payé » du bandeau juste au-dessus (ADR-015 §6-C).
    if (PermissionGate.allows(context, const [Perm.financePaymentRead])) {
      context.read<PaymentsBloc>().add(
        PaymentsRequested(
          studentId: widget.intent.studentId,
          academicYearId: widget.intent.academicYearId,
          silent: silent,
        ),
      );
    }

    context.read<StudentChargesBloc>().add(
      StudentChargesByAcademicYearRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
        silent: silent,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<LedgerRevalidationCubit, int>(
    // Un cycle de rafraîchissement vient d'aboutir : on relit le local, sans
    // skeleton. C'est la contrepartie du `await` retiré des deux repos
    // offline-first — les lectures rendent la main tout de suite, et c'est ce
    // signal qui les rattrape. Sans lui, une tablette dont la base est encore
    // vide afficherait « Aucun frais » et n'en sortirait pas de la visite.
    listener: (_, _) => _requestData(silent: true),
    child: widget.child,
  );
}
