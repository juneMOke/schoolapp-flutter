import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les deux vides de la caisse — **et la règle qui les gouverne**.
///
/// « Jamais d'écran vide sans issue » : chacun de ces états propose une action
/// qui **élargit la fenêtre** ou **change de caisse**. Un écran qui se contente
/// de constater l'absence renvoie le lecteur à sa barre latérale, et il n'y
/// reviendra pas.
///
/// ⚠️ **La règle se tient au niveau de l'ÉCRAN, pas de la carte.** Les deux
/// issues peuvent légitimement manquer toutes les deux — une plage libre, qu'on
/// n'élargit pas, lue par quelqu'un qui n'a pas de droit sur la Facturation.
/// La carte n'a alors aucun bouton, et c'est correct : la **fenêtre de temps
/// reste rendue au-dessus**, et c'est elle, la vraie issue. Les actions d'ici
/// n'en sont que le raccourci. Ce serait un défaut si l'écran entier se
/// résumait à la carte — il ne s'y résume pas.
///
/// ## Deux niveaux, deux phrases différentes
///
/// Aucune caisse n'a rien reçu, ou la caisse regardée est vide **alors que
/// l'autre a travaillé**. Les confondre ferait lire « rien aujourd'hui » à un
/// caissier dont le collègue a encaissé 4 120 $ — d'où le message qui
/// **chiffre** l'autre caisse plutôt que de la mentionner.

/// Aucun reçu, toutes caisses confondues.
///
/// Les tuiles de caisse restent affichées **à zéro** au-dessus (le repère de
/// lecture ne disparaît pas) ; tout ce qui décrit une caisse en particulier —
/// sélecteur compris — n'est pas rendu : il n'y a pas de caisse à détailler.
class FinanceTillGlobalEmpty extends StatelessWidget {
  /// La fenêtre **qui a répondu**, telle qu'elle s'écrit : « Aujourd'hui ».
  final String windowLabel;

  /// Le grain que le serveur annonce, d'où se déduit l'élargissement offert.
  final String period;

  final ValueChanged<TillWindow> onWindowRequested;

  const FinanceTillGlobalEmpty({
    super.key,
    required this.windowLabel,
    required this.period,
    required this.onWindowRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // La maquette écrit la fenêtre en minuscules dans le titre. `toLowerCase`
    // ignore la locale ; c'est sans conséquence sur les deux langues servies,
    // et la seule alternative serait un doublon de chaque libellé de période.
    final lower = windowLabel.toLowerCase();
    final wider = _wider(period);

    return EteeloEmptyResult(
      medallionIcon: Icons.receipt_long_outlined,
      label: l10n.financeTillEmptyGlobalTitle(lower),
      description: l10n.financeTillEmptyGlobalMessage(lower),
      fullWidthCard: true,
      primaryAction: wider == null
          ? null
          : EteeloButton.primary(
              label: wider == TillPeriod.year
                  ? l10n.financeTillEmptySeeYear
                  : l10n.financeTillEmptySeeMonth,
              icon: Icons.calendar_month_outlined,
              fullWidth: false,
              onPressed: () => onWindowRequested(_windowOf(wider)),
            ),
      secondaryAction: const _OpenBillingAction(),
    );
  }

  /// La fenêtre **immédiatement plus large**, ou `null` quand il n'y en a pas.
  ///
  /// La maquette n'offre que « Voir ce mois », depuis la journée. L'année est le
  /// segment ajouté par le porteur, et elle sert ici d'élargissement au mois.
  ///
  /// ⚠️ **Une plage libre n'est pas élargie.** On ne sait pas si elle est plus
  /// étroite qu'un mois — elle peut couvrir un trimestre — et lui substituer
  /// « ce mois » **jetterait les bornes que le lecteur vient de choisir**.
  /// L'année n'a rien au-dessus d'elle. Dans ces deux cas la règle « jamais
  /// sans issue » tient par la facturation, qui est toujours offerte.
  static TillPeriod? _wider(String period) => switch (period) {
    'day' || 'week' => TillPeriod.month,
    'month' => TillPeriod.year,
    _ => null,
  };

  static TillWindow _windowOf(TillPeriod period) => switch (period) {
    TillPeriod.month => const TillWindow.month(),
    TillPeriod.year => const TillWindow.year(),
    _ => const TillWindow.day(),
  };
}

/// La caisse regardée n'a rien reçu — **mais une autre a travaillé**.
///
/// Le message la **chiffre**. C'est la différence entre « il ne s'est rien
/// passé » et « il ne s'est rien passé ICI », et c'est ce qui empêche de lire
/// l'écran comme une panne. Les tuiles et le sélecteur restent au-dessus : seul
/// le détail est remplacé.
class FinanceTillCurrencyEmpty extends StatelessWidget {
  /// La caisse regardée, vide.
  final TillCurrencyBlock selected;

  /// Les autres caisses **qui ont reçu quelque chose**, dans l'ordre
  /// d'affichage. Jamais vide en pratique : sans elles, c'est le vide global
  /// qui parle.
  final List<TillCurrencyBlock> others;

  final String windowLabel;

  final ValueChanged<String> onCurrencySelected;

  const FinanceTillCurrencyEmpty({
    super.key,
    required this.selected,
    required this.others,
    required this.windowLabel,
    required this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = tillCurrencyName(selected.currency, l10n);

    return EteeloEmptyResult(
      medallionIcon: Icons.account_balance_wallet_outlined,
      label: l10n.financeTillEmptyCurrencyTitle(name),
      description: l10n.financeTillEmptyCurrencyMessage(
        name,
        windowLabel.toLowerCase(),
        _others(l10n),
      ),
      fullWidthCard: true,
      primaryAction: others.isEmpty
          ? null
          : EteeloButton.primary(
              label: l10n.financeTillEmptySeeTill(
                tillCurrencyName(others.first.currency, l10n),
              ),
              icon: Icons.account_balance_wallet_outlined,
              fullWidth: false,
              // Bascule directe, sans rechargement : les deux caisses sont dans
              // la même réponse, déjà en mémoire.
              onPressed: () => onCurrencySelected(others.first.currency),
            ),
      secondaryAction: const _OpenBillingAction(),
    );
  }

  /// « L'autre caisse a enregistré 4 120 $. »
  ///
  /// ⚠️ **Juxtaposés, jamais additionnés** quand il y en a plusieurs : c'est la
  /// même doctrine que la bande de caisses, et elle ne s'assouplit pas parce
  /// qu'on est dans une phrase.
  String _others(AppLocalizations l10n) {
    if (others.isEmpty) return '';
    final amounts = others
        .map(
          (block) => MoneyFormat.format(
            Money.parse(block.summary.total, block.currency),
          ),
        )
        .join(l10n.financeTillInsightAmountSeparator);

    return others.length == 1
        ? l10n.financeTillEmptyOtherTill(amounts)
        : l10n.financeTillEmptyOtherTills(amounts);
  }
}

/// « Ouvrir la facturation » — la sortie commune aux deux vides.
///
/// ⚠️ **Gardée, comme le lien du bandeau du taux.** La Facturation demande
/// `finance.charge.read` OU `finance.payment.read` ; la caisse se lit sous
/// `finance.stats.read`, qui n'implique ni l'un ni l'autre. Sans garde, un état
/// vide offrirait une porte fermée — et un état vide dont la seule issue mène à
/// un refus est pire qu'un état vide sans issue.
///
/// L'accès est **nommé** au registre plutôt que recopié : une exigence partagée
/// par plusieurs écrans finit par diverger quand on la répète.
class _OpenBillingAction extends StatelessWidget {
  const _OpenBillingAction();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PermissionGate.access(
      kBillingReadAccess,
      child: EteeloButton.ghost(
        label: l10n.financeTillEmptyOpenBilling,
        icon: Icons.open_in_new,
        fullWidth: false,
        onPressed: () => context.goNamed(
          AppRoutesNames.home,
          queryParameters: {'subMenuId': MenuConstants.facturationsId},
        ),
      ),
    );
  }
}
