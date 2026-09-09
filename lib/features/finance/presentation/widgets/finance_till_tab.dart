import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_loading_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_period_filter.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_rate_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_success_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/finance_stats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet **Caisse** : ce qui est entré dans le tiroir sur la fenêtre.
class FinanceTillTab extends StatefulWidget {
  const FinanceTillTab({super.key});

  @override
  State<FinanceTillTab> createState() => _FinanceTillTabState();
}

class _FinanceTillTabState extends State<FinanceTillTab> {
  @override
  void initState() {
    super.initState();
    // ⚠️ **Un `BlocListener` ne réagit qu'aux TRANSITIONS, pas à l'état qu'il
    // trouve en se montant.**
    //
    // Les agrégats peuvent avoir déjà répondu quand cet onglet apparaît — le
    // cas normal d'un retour sur l'onglet, et un cas possible dès la première
    // ouverture si la réponse arrive avant la frame. L'écouteur ne voyait alors
    // aucune transition, et la table n'était **jamais demandée** : elle restait
    // vide sous des cartes pleines, sans que rien ne signale l'appel manquant.
    //
    // On synchronise donc aussi au montage. Les deux chemins passent par la
    // même méthode, et le BLoC de la table ignore une demande identique à ce
    // qu'il sert déjà — un double déclenchement ne coûte donc pas un second
    // appel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncReceipts(context.read<FinanceTillBloc>().state);
    });
  }

  /// Demande à la table la fenêtre que les agrégats viennent de décrire.
  ///
  /// ⚠️ **La caisse ne fait plus partie de la demande.** La table porte tous
  /// les paiements de la fenêtre : la rejouer sur une bascule de devise
  /// redemanderait la même page. Le BLoC la refuserait déjà — sa garde compare
  /// la fenêtre servie — mais l'événement ne la porte plus du tout, ce qui rend
  /// la règle lisible ici plutôt que déduite là-bas.
  void _syncReceipts(FinanceTillState state) {
    if (state.status != FinanceTillStatus.success) return;

    context.read<FinanceTillReceiptsBloc>().add(
      FinanceTillReceiptsRequested(window: state.selectedWindow),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        // **Le bloc des agrégats fait autorité.** C'est lui qui sait quelle
        // fenêtre a répondu et quelle caisse est examinée ; la table ne décide
        // ni l'une ni l'autre, elle les reçoit. Un second appel déclenché par
        // la table elle-même finirait par demander une caisse que les agrégats
        // ne portent plus.
        BlocListener<FinanceTillBloc, FinanceTillState>(
          listenWhen: (prev, curr) =>
              curr.status == FinanceTillStatus.success &&
              curr.selectedCurrency != null &&
              (prev.selectedCurrency != curr.selectedCurrency ||
                  prev.till != curr.till),
          listener: (context, state) => _syncReceipts(state),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le taux d'abord, la fenêtre ensuite : l'ordre de la maquette
          // raconte « à quel taux → sur quelle fenêtre → combien dans chaque
          // caisse ».
          //
          // ⚠️ **Écart assumé : il reste rendu EN ERREUR.** La spec le fait
          // disparaître « avec le reste du contenu ». Mais elle emporte au même
          // endroit la fenêtre de temps, que cet onglet garde délibérément :
          // un 400 sur une plage libre est laissé remonter tel quel, et sans
          // le sélecteur la seule issue serait « Réessayer », qui rejouerait
          // la requête qui vient d'échouer. Faire disparaître le bandeau seul,
          // en gardant le sélecteur, ne serait plus une règle mais un
          // arbitraire. Les deux restent, ou aucun ne reste.
          const FinanceTillRateBar(),
          const Align(
            alignment: Alignment.centerLeft,
            child: FinanceTillPeriodFilter(),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _body(context, l10n),
        ],
      ),
    );
  }

  /// Le corps de l'onglet, sous un sélecteur qui, lui, ne clignote pas :
  /// faire disparaître le contrôle qu'on vient d'actionner pendant le
  /// chargement rendrait la bascule de grain impossible à répéter.
  Widget _body(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<FinanceTillBloc, FinanceTillState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.till != curr.till ||
          prev.failure != curr.failure ||
          prev.selectedCurrency != curr.selectedCurrency,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<FinanceTillStatus>(state.status),
            child: switch (state.status) {
              // Le squelette de la caisse, et non celui du recouvrement :
              // trois tuiles puis un graphique puis des rangées, dans l'ordre
              // et aux hauteurs de ce qui arrive.
              FinanceTillStatus.loading => const FinanceTillLoadingView(),
              FinanceTillStatus.success => FinanceTillSuccessView(
                till: state.till!,
                selectedBlock: state.selectedBlock,
                onCurrencySelected: (currency) => context
                    .read<FinanceTillBloc>()
                    .add(FinanceTillCurrencySelected(currency)),
                // Le même événement que le sélecteur de période : c'est ce qui
                // fait suivre le segment quand le vide global élargit la
                // fenêtre.
                onWindowRequested: (window) => context
                    .read<FinanceTillBloc>()
                    .add(FinanceTillRequested(window: window)),
              ),
              FinanceTillStatus.error => FinanceStatsResultsErrorState(
                failure:
                    state.failure ?? const ServerFailure('unknown failure'),
                onRetry: () => context.read<FinanceTillBloc>().add(
                  const FinanceTillRefreshRequested(),
                ),
              ),
              FinanceTillStatus.initial => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}
