import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
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
  /// Une demande de versements a-t-elle déjà été émise pour l'élève courant ?
  ///
  /// Sert à ne pas rejouer la lecture quand les droits changent alors qu'elle
  /// est déjà partie — et à la rejouer quand ils s'élargissent après un refus.
  /// Remis à faux quand la fiche change d'élève, et quand le droit se retire :
  /// ce qui est affiché n'appartient plus à la session d'après.
  bool _paymentsRequested = false;

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

    _paymentsRequested = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestData();
    });
  }

  void _requestData({bool silent = false}) {
    _requestPayments(silent: silent);

    context.read<StudentChargesBloc>().add(
      StudentChargesByAcademicYearRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
        silent: silent,
      ),
    );
  }

  /// Les encaissements ne sont demandés que si la session a le droit de les
  /// lire. Sans cette garde, un profil « créances seules » (le secrétariat)
  /// déclenchait une lecture qui ne pouvait rien rendre, et la section
  /// affichait « Aucun versement enregistré » — faux, et contredit par le
  /// « Déjà payé » du bandeau juste au-dessus (ADR-015 §6-C).
  ///
  /// ⚠️ **On ne renonce que sur `missing`.** La garde à deux états refusait
  /// aussi sur un ensemble encore INCONNU — l'état de tout le parc jusqu'au
  /// premier refresh suivant la migration v24 — et comme la demande ne part
  /// qu'au post-frame de `initState`, la section restait sur `initial` : elle
  /// affichait « Aucun versement enregistré » à un caissier qui a le droit, et
  /// seul un aller-retour sur la page en sortait. Une lecture tentée à tort ne
  /// coûte qu'un 403, rendu en état d'erreur ; une lecture omise à tort ment.
  void _requestPayments({required bool silent}) {
    if (permissionHolding(context, const [Perm.financePaymentRead]) ==
        PermissionHolding.missing) {
      return;
    }
    _paymentsRequested = true;
    context.read<PaymentsBloc>().add(
      PaymentsRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
        silent: silent,
      ),
    );
  }

  /// Le droit de lire les versements vient de changer pendant la consultation.
  ///
  /// L'autre moitié du défaut, et la plus tenace : un ensemble qui arrive en
  /// séance ne redemande rien de lui-même. Un profil d'abord refusé, puis
  /// élargi par un refresh, gardait une section vide jusqu'à ce qu'on quitte la
  /// fiche — alors même que la section, elle, s'était rouverte.
  ///
  /// La lecture de rattrapage n'est **pas** silencieuse : il n'y a rien à
  /// l'écran à préserver, et un skeleton dit honnêtement qu'on est allé
  /// chercher. Seuls les versements sont redemandés — les créances, elles, sont
  /// déjà à l'écran, et les relire ferait clignoter une donnée intacte.
  void _onPaymentsHoldingChanged(bool mayRead) {
    if (!mayRead) {
      // Le droit se retire : ce qui est affiché ne sera pas rafraîchi, et un
      // élargissement ultérieur devra repartir d'une vraie lecture.
      _paymentsRequested = false;
      return;
    }
    if (_paymentsRequested) return;
    _requestPayments(silent: false);
  }

  /// « On sait que le droit manque » — la seule réponse qui fait renoncer.
  bool _mayReadPayments(AuthState state) =>
      permissionHoldingOf(state.permissions, const [Perm.financePaymentRead]) !=
      PermissionHolding.missing;

  @override
  Widget build(BuildContext context) {
    final revalidation = BlocListener<LedgerRevalidationCubit, int>(
      // Un cycle de rafraîchissement vient d'aboutir : on relit le local, sans
      // skeleton. C'est la contrepartie du `await` retiré des deux repos
      // offline-first — les lectures rendent la main tout de suite, et c'est ce
      // signal qui les rattrape. Sans lui, une tablette dont la base est encore
      // vide afficherait « Aucun frais » et n'en sortirait pas de la visite.
      listener: (_, _) => _requestData(silent: true),
      child: widget.child,
    );

    // Sans `AuthBloc` dans l'arbre — harnais de test qui monte la page seule —
    // il n'y a rien à écouter, et c'est la même convention de transparence que
    // `PermissionGate`.
    final auth = PermissionGate.maybeBlocOf(context);
    if (auth == null) return revalidation;

    return BlocListener<AuthBloc, AuthState>(
      bloc: auth,
      // Comparé sur la DÉCISION, pas sur les ensembles : un droit qui bouge
      // ailleurs dans le catalogue ne relance aucune lecture, et la comparaison
      // n'a pas à se prononcer sur les doublons d'une liste.
      listenWhen: (previous, current) =>
          _mayReadPayments(previous) != _mayReadPayments(current),
      listener: (_, state) =>
          _onPaymentsHoldingChanged(_mayReadPayments(state)),
      child: revalidation,
    );
  }
}
