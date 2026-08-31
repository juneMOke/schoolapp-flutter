import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_payer_form_controller.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_collect_action_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payer_search_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Page d'encaissement (ex-popin MODALE-12) : identité du payeur, frais à
/// régler, total en direct et CTA ancré au bas de l'écran.
///
/// Écran plein, et non plus une popin posée sur la fiche : un encaissement se
/// saisit à quatre champs et autant de lignes de frais qu'en compte l'année. Il
/// porte donc la charte des autres écrans du dossier élève — barre sombre à
/// initiales, cartes de section, liseré or-doux.
///
/// Elle fournit son propre [FinanceOfflineBloc] (chemin d'écriture
/// offline-first) : la page vit sur sa propre route, hors de l'arbre de la
/// fiche. Au succès, elle se referme en rendant `true` — c'est la fiche qui
/// resynchronise ses listes une fois revenue à l'écran.
class FacturationCreatePaymentPage extends StatelessWidget {
  final FacturationCreatePaymentIntent intent;

  const FacturationCreatePaymentPage({super.key, required this.intent});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FinanceOfflineBloc>(
      create: (_) => getIt<FinanceOfflineBloc>(),
      child: FacturationCreatePaymentView(intent: intent),
    );
  }
}

/// Contenu de la page d'encaissement (état du formulaire + soumission).
class FacturationCreatePaymentView extends StatefulWidget {
  final FacturationCreatePaymentIntent intent;

  const FacturationCreatePaymentView({super.key, required this.intent});

  @override
  State<FacturationCreatePaymentView> createState() =>
      _FacturationCreatePaymentViewState();
}

class _FacturationCreatePaymentViewState
    extends State<FacturationCreatePaymentView> {
  final _payer = FacturationPayerFormController();

  late final List<FacturationChargeEntry> _entries;

  /// Anti double-dialogue : un second déclencheur (retour système pendant que
  /// la flèche a déjà ouvert la confirmation) est ignoré.
  bool _closeConfirmationOpen = false;

  /// Confirmation d'encaissement en vol. Fige le formulaire et éteint le CTA :
  /// deux taps rapides ouvriraient deux confirmations, donc deux versements
  /// pour un seul acte de guichet.
  bool _collectInFlight = false;

  @override
  void initState() {
    super.initState();
    _entries = [
      for (final charge in widget.intent.unpaidCharges)
        if (chargeRemainingInCents(charge) > 0) FacturationChargeEntry(charge),
    ];
    for (final entry in _entries) {
      entry.controller.addListener(_onChanged);
    }
    _payer.addListener(_onChanged);
  }

  @override
  void dispose() {
    _payer.dispose();
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Demande de sortie (flèche de la barre, retour système) : passe toujours
  /// par une confirmation, contrairement au succès d'encaissement qui referme
  /// directement (cf. [_onCollect]). `Navigator.pop()` ci-dessous quitte
  /// réellement la page : contrairement à `maybePop`/au retour système, il
  /// n'est pas soumis au [PopScope] et n'est donc pas re-intercepté.
  Future<void> _requestClose() async {
    if (_closeConfirmationOpen) return;
    _closeConfirmationOpen = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showAppConfirmationDialog(
        context: context,
        title: l10n.facturationCreatePaymentCloseConfirmTitle,
        message: l10n.facturationCreatePaymentCloseConfirmMessage,
        confirmLabel: l10n.facturationCreatePaymentCloseConfirmAction,
        cancelLabel: l10n.facturationCreatePaymentCloseConfirmCancel,
        isDestructive: true,
      );
      if (!mounted || !confirmed) return;
      Navigator.of(context).pop();
    } finally {
      _closeConfirmationOpen = false;
    }
  }

  String _formatPlain(int cents) {
    final amount = cents / 100;
    final isInteger = amount == amount.roundToDouble();
    return isInteger ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  }

  String _formatWithCurrency(int cents, String currency) =>
      formatMonetaryAmountWithCurrency(amount: cents / 100, currency: currency);

  void _onToggle(FacturationChargeEntry entry, bool value) {
    setState(() {
      entry.selected = value;
      if (value) {
        entry.controller.text = _formatPlain(entry.remainingInCents);
      } else {
        entry.controller.clear();
      }
    });
  }

  void _onSettleAll(FacturationChargeEntry entry) {
    setState(() {
      entry.controller.text = _formatPlain(entry.remainingInCents);
    });
  }

  /// Le total à encaisser, **par devise**.
  ///
  /// C'était un entier unique, sommé sur toutes les lignes retenues, étiqueté
  /// avec la première devise non vide rencontrée. Un versement soldant 425,00 $
  /// et 90 000 FC s'affichait « 9 042 500 USD » — sur le bandeau or, sur le
  /// ticket remis au parent, et dans le payload envoyé au serveur.
  MoneyBag get _totalBag => MoneyBag.sumBy(
    _entries.where((entry) => entry.effectiveCents > 0),
    (entry) => Money.parse(entry.effectiveCents, entry.charge.currency),
  );

  /// Le total, rendu sur une ligne — les devises séparées, jamais sommées.
  String _totalLabel() => _totalBag.entries.map(MoneyFormat.format).join(' · ');

  /// Ouvre l'annuaire local des payeurs et reprend celui qui en revient.
  Future<void> _pickPayer() async {
    final payer = await showFacturationPayerSearchDialog(
      context: context,
      studentId: widget.intent.studentId,
    );
    if (!mounted || payer == null) return;
    _payer.applyPayer(payer);
  }

  String _studentFullName(AppLocalizations l10n) {
    final name = [
      widget.intent.lastName,
      widget.intent.surname,
      widget.intent.firstName,
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return name.isEmpty ? l10n.facturationDetailUnknownValue : name;
  }

  /// Classe affichée dans le sur-titre « Encaissement · {classe} », comme sur
  /// la fiche d'où l'on vient.
  String _classLabel(AppLocalizations l10n) {
    final value = widget.intent.levelName.trim().isNotEmpty
        ? widget.intent.levelName.trim()
        : widget.intent.levelGroupName.trim();
    return value.isEmpty ? l10n.facturationDetailUnknownValue : value;
  }

  Future<void> _onCollect(AppLocalizations l10n) async {
    final bag = _totalBag;
    final totalLabel = _totalLabel();
    // Un versement mixte est un cas NOMINAL depuis que le contrat porte
    // `amounts[]` : c'est un acte de guichet, donc un versement, un reçu.
    // Reste à refuser le versement vide — rien à encaisser n'est pas un
    // encaissement.
    if (!_payer.isValid || bag.isEmpty || bag.isAllZero || _collectInFlight) {
      return;
    }

    final retained = _entries.where((e) => e.effectiveCents > 0).toList();
    final offlineBloc = context.read<FinanceOfflineBloc>();
    final middleName = _payer.middleName.text.trim();
    final phone = _payer.phone.text.trim();

    final request = PaymentsCreateRequested(
      studentId: widget.intent.studentId,
      academicYearId: widget.intent.academicYearId,
      amounts: bag,
      payerFirstName: _payer.firstName.text.trim(),
      payerLastName: _payer.lastName.text.trim(),
      payerMiddleName: middleName.isEmpty ? null : middleName,
      payerPhoneNumber: phone.isEmpty ? null : phone,
      allocations: [
        for (final entry in retained)
          CreatePaymentAllocationInput(
            studentChargeId: entry.charge.id,
            // La ligne de grille, pas seulement la nature du frais : le serveur
            // ne départage plus deux tranches d'un même minerval sans elle.
            feeTariffId: designatedFeeTariffId(entry.charge),
            feeCode: entry.charge.feeCode,
            studentChargeLabel: entry.charge.label,
            amountInCents: entry.effectiveCents,
            currency: entry.charge.currency,
          ),
      ],
    );

    setState(() => _collectInFlight = true);
    // La sur-couche 2 étapes porte la confirmation PUIS le résultat
    // (processing → succès | échec) : le paiement n'est créé qu'à l'étape
    // résultat et le toast est remplacé par la popin. Elle RESTE une popin —
    // un récapitulatif se lit par-dessus la saisie qu'il résume.
    final outcome = await showFacturationCreatePaymentConfirmDialog(
      context,
      financeOfflineBloc: offlineBloc,
      totalLabel: totalLabel,
      studentName: _studentFullName(l10n),
      payerName: _payer.fullName(l10n.facturationDetailUnknownValue),
      payerPhone: phone,
      allocations: [
        for (final entry in retained)
          FacturationConfirmAllocationItem(
            // Le libellé, pas la nature : le récapitulatif qu'on valide doit
            // nommer LA tranche encaissée, pas la famille à laquelle elle
            // appartient.
            label: chargeDesignation(entry.charge, l10n),
            amount: _formatWithCurrency(
              entry.effectiveCents,
              entry.charge.currency,
            ),
          ),
      ],
      request: request,
    );

    if (!mounted) {
      return;
    }
    setState(() => _collectInFlight = false);
    // Succès rendu par la popin résultat → on quitte la page en rendant `true`.
    // C'est la fiche qui resynchronise ses listes au retour : faire le refresh
    // là-bas évite qu'un éventuel échec de rechargement ne contredise l'écran
    // de succès.
    if (outcome == FacturationCollectOutcome.succeeded) {
      // `pop()` (pas `maybePop`) pour ne pas déclencher la confirmation de
      // sortie : il n'y a plus rien à perdre.
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canCollect =
        _payer.isValid && !_totalBag.isAllZero && !_collectInFlight;

    return PopScope(
      // Bloque le retour système / `maybePop` : toute sortie passe par
      // `_requestClose`. `Navigator.pop()` direct (succès d'encaissement) n'est
      // pas concerné par ce garde-fou.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _requestClose();
      },
      child: AppPageBackground(
        appBar: StudentDetailAppBar(
          fullName: _studentFullName(l10n),
          eyebrow:
              '${l10n.facturationCreatePaymentEyebrow} · ${_classLabel(l10n)}',
          firstName: widget.intent.firstName,
          lastName: widget.intent.lastName,
          fallbackRoute: AppRoutesNames.facturationDetailPath(
            studentId: widget.intent.studentId,
            academicYearId: widget.intent.academicYearId,
          ),
          // Une saisie en cours ne se perd pas sur un tap : la flèche passe par
          // la même confirmation que le retour système.
          onExit: _requestClose,
        ),
        // Sans contexte d'affichage il n'y a pas de saisie sous la barre :
        // proposer d'encaisser sous une carte d'erreur n'a aucun sens.
        bottomNavigationBar: widget.intent.hasDisplayContext
            ? FacturationCollectActionBar(
                totalLabel: _totalLabel(),
                onCollect: canCollect ? () => _onCollect(l10n) : null,
              )
            : null,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // Largeur de lecture de la Facturation : un formulaire étalé sur
            // 1180 dp éloigne les libellés de leurs champs.
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.facturationContentMaxWidth,
            ),
            child: _body(l10n),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    // Lien profond ouvert sans contexte : on n'encaisse pas au nom de quelqu'un
    // qu'on ne sait pas nommer. La fiche pose la même garde sur son propre
    // contexte.
    if (!widget.intent.hasDisplayContext) {
      return FinanceContextErrorCard(
        title: l10n.facturationCreatePaymentContextErrorTitle,
        message: l10n.facturationCreatePaymentContextErrorMessage,
        icon: Icons.report_problem_outlined,
        accent: AppColors.warning,
        accentSoft: AppColors.warning.withValues(alpha: 0.14),
        borderColor: AppColors.warning.withValues(alpha: 0.2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceSectionCard(
          backgroundColor: AppColors.surfaceRaised,
          borderColor: AppColors.border,
          child: FacturationCreatePaymentPayerSection(
            lastNameController: _payer.lastName,
            firstNameController: _payer.firstName,
            middleNameController: _payer.middleName,
            phoneController: _payer.phone,
            onPickPayer: _pickPayer,
            phoneErrorText: _payer.phoneErrorText(l10n),
            readOnly: _collectInFlight,
          ),
        ),
        const SizedBox(height: AppDimensions.detailSectionSpacing),
        FacturationCreatePaymentChargesSection(
          entries: _entries,
          onToggle: _collectInFlight ? null : _onToggle,
          onSettleAll: _collectInFlight ? null : _onSettleAll,
        ),
      ],
    );
  }
}
