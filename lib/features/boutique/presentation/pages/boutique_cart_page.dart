import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/beneficiary_picker_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_print_flow.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_beneficiary_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_panel.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_clear_cart_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_confirm_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_payer_section.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_success_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_top_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le panier, en **page dédiée** — et non en colonne ni en feuille.
///
/// Une colonne à côté du catalogue ne tenait que sur un poste fixe ; empilée
/// dessous, elle obligeait à faire défiler tout un catalogue pour atteindre le
/// total, puis à remonter pour ajouter l'article suivant. Le panier a sa propre
/// page : on y désigne les bénéficiaires, on y saisit le payeur, on y encaisse,
/// et on en repart.
///
/// **Le bloc est celui du catalogue**, passé par valeur : un second bloc
/// composerait un second panier, et la vente encaissée ne serait pas celle
/// qu'on a vue à l'écran.
class BoutiqueCartPage extends StatefulWidget {
  final String academicYearId;
  final List<BoutiqueLevelOption> levels;

  const BoutiqueCartPage({
    super.key,
    required this.academicYearId,
    required this.levels,
  });

  /// Ouvre la page. Rend quand elle se referme.
  static Future<void> push(
    BuildContext context, {
    required BoutiqueBloc bloc,
    required String academicYearId,
    required List<BoutiqueLevelOption> levels,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider<BoutiqueBloc>.value(
        value: bloc,
        child: BoutiqueCartPage(academicYearId: academicYearId, levels: levels),
      ),
    ),
  );

  @override
  State<BoutiqueCartPage> createState() => _BoutiqueCartPageState();
}

class _BoutiqueCartPageState extends State<BoutiqueCartPage> {
  /// Les contrôleurs du bloc payeur vivent ICI et non dans le widget de saisie :
  /// celui-ci est reconstruit à chaque frappe (le panier change), et des
  /// contrôleurs recréés à chaque build perdraient le curseur au milieu d'un
  /// nom.
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();

  /// Vrai le temps que la modale de succès soit à l'écran — la transition vers
  /// « vente encaissée » ne doit l'ouvrir qu'une fois, et un rebuild du bloc ne
  /// doit pas en empiler une seconde par-dessus.
  bool _isClosingSale = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  /// Recopie l'identité retenue au répertoire dans les champs.
  ///
  /// Les contrôleurs ne sont pas pilotés par l'état — les réécrire à chaque
  /// build replacerait le curseur en tête à la deuxième lettre. Ils ne sont
  /// donc poussés QUE sur ce geste, où l'utilisateur ne tape pas.
  void _fillFromDirectory(BoutiquePayer payer) {
    final filled = payer.toCartPayer();
    _phoneController.text = filled.phoneNumber;
    _lastNameController.text = filled.lastName;
    _middleNameController.text = filled.middleName;
    _firstNameController.text = filled.firstName;
    context.read<BoutiqueBloc>().add(BoutiquePayerFromDirectoryUsed(payer));
  }

  /// Ouvre la modale de désignation et pose l'élève choisi sur la ligne.
  ///
  /// Le cubit est créé **par ouverture** et refermé après : le laisser vivre
  /// entre deux lignes garderait la recherche de la précédente, et le guichet
  /// verrait des résultats qu'il n'a pas demandés.
  Future<void> _pickBeneficiary(BuildContext context, String lineKey) async {
    final bloc = context.read<BoutiqueBloc>();
    final cubit = getIt<BeneficiaryPickerCubit>(param1: widget.academicYearId);
    try {
      final candidate = await BoutiqueBeneficiaryDialog.show(
        context,
        cubit: cubit,
        levels: widget.levels,
      );
      if (candidate == null) return;
      bloc.add(
        BoutiqueLineBeneficiaryAssigned(
          lineKey,
          CartBeneficiary(
            studentId: candidate.studentId,
            fullName: candidate.fullName,
            schoolLevelId: candidate.schoolLevelId,
            classroomLabel: candidate.schoolLevelName,
            knownToServer: candidate.enrollmentSynced,
          ),
        ),
      );
    } finally {
      await cubit.close();
    }
  }

  /// Imprime le ticket de la vente qui vient d'être encaissée.
  ///
  /// ⚠️ **Aucun échec ici n'est un échec d'encaissement** : la vente est déjà
  /// écrite, et le papier ne coûte que du papier.
  Future<void> _print(RecordedSale sale) => printSaleTicket(
    context,
    sale: sale,
    levelLabels: {for (final level in widget.levels) level.id: level.label},
    messenger: ScaffoldMessenger.maybeOf(context),
  );

  /// L'appareil est-il hors ligne ?
  ///
  /// ⚠️ **Ne lève jamais.** L'état du réseau ne décide que d'une PHRASE dans la
  /// confirmation ; il ne conditionne pas l'encaissement, qui est local-first.
  /// Or `isOnline()` traverse un canal natif, qui peut échouer — et laisser
  /// l'exception remonter ferait perdre une vente pour un renseignement de
  /// confort, sur un client qui a déjà payé.
  ///
  /// En cas de doute on annonce **hors ligne** : c'est la formulation la plus
  /// prudente, puisqu'elle promet un ticket provisoire — ce qui est de toute
  /// façon vrai à cet instant, le reçu n'étant scellé qu'au push.
  Future<bool> _isOffline() async {
    try {
      return !await getIt<ConnectivityService>().isOnline();
    } catch (_) {
      return true;
    }
  }

  /// Confirme puis encaisse.
  ///
  /// La confirmation est un **récapitulatif non modifiable** : c'est là que le
  /// comptant intégral se voit à l'œil nu. Refuser ferme la modale et ne touche
  /// à rien.
  /// Le payeur porte-t-il au moins un nom ?
  static bool _hasName(CartPayer payer) => [
    payer.lastName,
    payer.middleName,
    payer.firstName,
  ].any((part) => part.trim().isNotEmpty);

  Future<void> _collect(BuildContext context, BoutiqueState state) async {
    final bloc = context.read<BoutiqueBloc>();
    final isOffline = await _isOffline();
    if (!context.mounted) return;

    final confirmed = await BoutiqueConfirmDialog.show(
      context,
      cart: state.cart,
      // « Nouveau » se lit sur l'absence de reconnaissance au répertoire : c'est
      // exactement ce que la phrase annonce au guichet.
      //
      // ⚠️ Sauf s'il n'y a PERSONNE : une vente anonyme n'entre au répertoire
      // sous aucun nom, et annoncer « ce payeur est nouveau » promettrait un
      // enregistrement qui n'aura pas lieu. Le répertoire se rapproche sur le
      // NUMÉRO et se remplit avec un NOM — sans l'un des deux, il n'y a rien à
      // annoncer.
      payerIsNew:
          state.payerMatch == null &&
          state.cart.payer.matchKey != null &&
          _hasName(state.cart.payer),
      isOffline: isOffline,
    );
    if (!confirmed) return;

    bloc.add(BoutiqueSaleSubmitted(academicYearId: widget.academicYearId));
  }

  /// Vide le panier — **après confirmation**.
  ///
  /// Rien n'est encaissé à ce stade, mais ce qui se perd est du travail : des
  /// lignes, des bénéficiaires désignés un par un, une identité saisie au
  /// clavier. Le geste était offert par un lien souligné qu'un doigt pouvait
  /// toucher sans le vouloir, et il n'a pas d'annulation.
  Future<void> _clearCart(BuildContext context, BoutiqueState state) async {
    final bloc = context.read<BoutiqueBloc>();
    final confirmed = await BoutiqueClearCartDialog.show(
      context,
      cart: state.cart,
    );
    if (!confirmed) return;

    // « Vider le panier » emporte le payeur : les champs doivent suivre, sinon
    // l'identité de la vente précédente resterait affichée sur la suivante.
    _phoneController.clear();
    _lastNameController.clear();
    _middleNameController.clear();
    _firstNameController.clear();
    bloc.add(const BoutiqueCartCleared());
  }

  /// La vente vient d'être écrite : on l'annonce, on propose le ticket, puis on
  /// repart du catalogue avec un panier vide.
  ///
  /// **Le panier n'est vidé qu'ici**, une fois la modale refermée : le vider
  /// plus tôt effacerait ce que le ticket sert justement à imprimer.
  Future<void> _closeSale(BuildContext context, RecordedSale sale) async {
    if (_isClosingSale) return;
    _isClosingSale = true;
    final bloc = context.read<BoutiqueBloc>();
    final navigator = Navigator.of(context);
    try {
      await BoutiqueSaleSuccessDialog.show(
        context,
        sale: sale,
        onPrint: () => _print(sale),
      );
    } finally {
      _isClosingSale = false;
    }
    bloc.add(const BoutiqueNewSaleStarted());
    // La page se referme sur le catalogue, panier vidé. `maybePop` et non
    // `pop` : l'écran a pu être quitté à la main pendant l'impression.
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<BoutiqueBloc, BoutiqueState>(
      // La transition est lue dans ce sens précis — d'aucune vente vers une
      // vente écrite. Sans cela, un simple rebuild rouvrirait la modale.
      listenWhen: (previous, current) =>
          previous.recordedSale == null && current.recordedSale != null,
      listener: (context, state) => _closeSale(context, state.recordedSale!),
      builder: (context, state) {
        final bloc = context.read<BoutiqueBloc>();

        return AppPageBackground(
          appBar: BoutiqueTopBar(
            eyebrow: l10n.boutiqueCartPageEyebrow,
            title: l10n.boutiqueCartTitle,
            onBack: () => Navigator.of(context).maybePop(),
            backTooltip: l10n.boutiqueBackToCatalog,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingXL),
            child: BoutiqueCartPanel(
              cart: state.cart,
              levels: widget.levels,
              rates: state.rates,
              onTenderCurrencyChanged: (catalogCurrency, currency) => bloc.add(
                BoutiqueTenderCurrencyChanged(
                  catalogCurrency: catalogCurrency,
                  currency: currency,
                ),
              ),
              onTenderedChanged: (catalogCurrency, cents) => bloc.add(
                BoutiqueTenderAmountChanged(
                  catalogCurrency: catalogCurrency,
                  tenderedCents: cents,
                ),
              ),
              payerSection: BoutiquePayerSection(
                payer: state.cart.payer,
                match: state.payerMatch,
                phoneController: _phoneController,
                lastNameController: _lastNameController,
                middleNameController: _middleNameController,
                firstNameController: _firstNameController,
                onPhoneChanged: (value) => bloc.add(
                  BoutiquePayerChanged(
                    state.cart.payer.copyWith(phoneNumber: value),
                  ),
                ),
                onLastNameChanged: (value) => bloc.add(
                  BoutiquePayerChanged(
                    state.cart.payer.copyWith(lastName: value),
                  ),
                ),
                onMiddleNameChanged: (value) => bloc.add(
                  BoutiquePayerChanged(
                    state.cart.payer.copyWith(middleName: value),
                  ),
                ),
                onFirstNameChanged: (value) => bloc.add(
                  BoutiquePayerChanged(
                    state.cart.payer.copyWith(firstName: value),
                  ),
                ),
                onUseMatch: _fillFromDirectory,
              ),
              onRemoveLine: (key) => bloc.add(BoutiqueLineRemoved(key)),
              onQuantityChanged: (key, quantity) =>
                  bloc.add(BoutiqueLineQuantityChanged(key, quantity)),
              onLevelChanged: (key, levelId) =>
                  bloc.add(BoutiqueLineLevelChanged(key, levelId)),
              onPickBeneficiary: (key) => _pickBeneficiary(context, key),
              onClearBeneficiary: (key) =>
                  bloc.add(BoutiqueLineBeneficiaryCleared(key)),
              // Un bouton actif qui ne fait rien est pire qu'un bouton inactif :
              // le pied NOMME ce qui manque, et se rend inerte tant qu'il manque
              // quelque chose.
              onCollect: state.cart.canCollect && !state.isCollecting
                  ? () => _collect(context, state)
                  : null,
              onClear: () => _clearCart(context, state),
            ),
          ),
        );
      },
    );
  }
}
