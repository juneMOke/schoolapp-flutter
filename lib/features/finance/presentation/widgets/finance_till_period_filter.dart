import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fenêtre que la caisse totalise — **jour par défaut**.
///
/// C'est la question qu'on pose le soir, à la fermeture. Les autres grains
/// répondent à la même question sur une fenêtre plus large ; aucun ne demande
/// d'attendu, puisque tout y est déjà encaissé.
///
/// Le recouvrement, lui, n'a plus de sélecteur : à la semaine, les échéances
/// tombant en fin de mois, l'attendu valait zéro.
///
/// ## Quatre segments, et `year` n'en fait pas partie
///
/// La spec dessine **Aujourd'hui / Cette semaine / Ce mois / Période**. Le
/// contrat sert aussi `year`, et [TillWindow] sait le construire — mais
/// l'exposer ajouterait une fenêtre que la spec n'a jamais dessinée, sur un
/// écran dont la doctrine est de ne montrer que ce qui a été décidé. La
/// **période libre** couvre le besoin d'élargir, en le bornant à 366 jours.
class FinanceTillPeriodFilter extends StatefulWidget {
  const FinanceTillPeriodFilter({super.key});

  @override
  State<FinanceTillPeriodFilter> createState() =>
      _FinanceTillPeriodFilterState();
}

class _FinanceTillPeriodFilterState extends State<FinanceTillPeriodFilter> {
  /// Les bornes en cours de saisie.
  ///
  /// Elles vivent **ici** et non dans le BLoC : tant que la plage n'est pas
  /// complète, aucune requête n'est due, et un état global qui porterait une
  /// borne à moitié choisie ferait rejouer l'écran pour rien.
  DateTime? _from;
  DateTime? _to;

  /// Les quatre segments de la spec. `year` reste constructible côté modèle,
  /// mais n'est pas offert ici — voir la doc de la classe.
  static const List<TillPeriod> _offered = [
    TillPeriod.day,
    TillPeriod.week,
    TillPeriod.month,
    TillPeriod.custom,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FinanceTillBloc, FinanceTillState>(
      buildWhen: (prev, curr) => prev.selectedWindow != curr.selectedWindow,
      builder: (context, state) {
        final window = state.selectedWindow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              label: l10n.financeStatsPeriodFilterA11yLabel(
                _labelOf(window.period, l10n),
              ),
              child: SegmentedTabFilter<TillPeriod>(
                options: [
                  for (final period in _offered)
                    SegmentedTabOption(
                      label: _labelOf(period, l10n),
                      value: period,
                    ),
                ],
                selected: window.period,
                onSelected: (period) => _onPeriodSelected(context, period),
              ),
            ),
            if (window.isCustom) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _CustomRangeFields(
                from: _from ?? window.from,
                to: _to ?? window.to,
                onChanged: (from, to) => _onRangeChanged(context, from, to),
                l10n: l10n,
              ),
            ],
          ],
        );
      },
    );
  }

  void _onPeriodSelected(BuildContext context, TillPeriod period) {
    if (period != TillPeriod.custom) {
      setState(() {
        _from = null;
        _to = null;
      });
      context.read<FinanceTillBloc>().add(
        FinanceTillRequested(window: _windowOf(period)),
      );
      return;
    }

    // Le segment « Période » s'ouvre sur une plage **par défaut** — les trente
    // derniers jours — plutôt que sur deux champs vides. Deux champs vides
    // n'auraient rien à charger, et l'écran se viderait sur un clic d'onglet.
    final defaultWindow = TillWindow.defaultCustom(DateTime.now());
    setState(() {
      _from = defaultWindow.from;
      _to = defaultWindow.to;
    });
    context.read<FinanceTillBloc>().add(
      FinanceTillRequested(window: defaultWindow),
    );
  }

  /// Une plage n'est demandée que **complète et dans l'ordre**.
  ///
  /// Le serveur refuse en 400 une fenêtre libre sans ses deux bornes, et
  /// n'échange pas des bornes inversées. Plutôt que d'afficher ce refus, on ne
  /// construit pas la requête : `TillWindow.custom` est inconstructible à
  /// l'envers, et l'écran garde ce qu'il affichait.
  void _onRangeChanged(BuildContext context, DateTime? from, DateTime? to) {
    setState(() {
      _from = from;
      _to = to;
    });

    if (from == null || to == null) return;
    if (TillWindow.dateOnly(from).isAfter(TillWindow.dateOnly(to))) return;

    context.read<FinanceTillBloc>().add(
      FinanceTillRequested(
        window: TillWindow.custom(from: from, to: to),
      ),
    );
  }

  static TillWindow _windowOf(TillPeriod period) => switch (period) {
    TillPeriod.day => const TillWindow.day(),
    TillPeriod.week => const TillWindow.week(),
    TillPeriod.month => const TillWindow.month(),
    TillPeriod.year => const TillWindow.year(),
    // Jamais atteint : la période libre passe par `_onPeriodSelected`, qui lui
    // fabrique des bornes. Un `TillWindow.custom` sans elles serait refusé.
    TillPeriod.custom => const TillWindow.month(),
  };

  static String _labelOf(TillPeriod period, AppLocalizations l10n) =>
      switch (period) {
        TillPeriod.day => l10n.financeTillPeriodDayCurrent,
        TillPeriod.week => l10n.financeStatsPeriodWeekCurrent,
        TillPeriod.month => l10n.financeStatsPeriodMonthCurrent,
        TillPeriod.year => l10n.financeStatsPeriodYearCurrent,
        TillPeriod.custom => l10n.financeTillPeriodCustom,
      };
}

/// Les deux bornes d'une fenêtre libre.
///
/// Bornes **incluses** — du 5 au 5 cadre bien une journée. Le serveur plafonne
/// la plage à 366 jours ; au-delà il refuse, et c'est un refus qu'on laisse
/// remonter plutôt que de le devancer par une borne dupliquée côté client.
class _CustomRangeFields extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;
  final AppLocalizations l10n;

  const _CustomRangeFields({
    required this.from,
    required this.to,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DateButton(
          label: l10n.financeTillPeriodFrom,
          value: from,
          onPick: (picked) => onChanged(picked, to),
        ),
        _DateButton(
          label: l10n.financeTillPeriodTo,
          value: to,
          onPick: (picked) => onChanged(from, picked),
        ),
      ],
    );
  }
}

/// Une borne, choisie au calendrier plutôt que saisie au clavier.
///
/// La spec décrit deux champs texte `jj/mm/aaaa`, avec un repli sur le mois
/// quand la saisie est illisible. Le sélecteur natif rend ce repli **sans
/// objet** : il ne peut pas produire une date invalide, et il évite d'avoir à
/// arbitrer ce que vaut « 31/02 » sur un écran qu'on rapproche de billets.
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);
    final shown = value == null ? '—' : materialL10n.formatCompactDate(value!);

    return Semantics(
      button: true,
      label: '$label : $shown',
      child: ExcludeSemantics(
        child: OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              // Une caisse ne se lit pas dans le futur : rien n'y est encore
              // entré.
              firstDate: DateTime(now.year - 5),
              lastDate: now,
            );
            if (picked != null) onPick(picked);
          },
          icon: const Icon(Icons.event_outlined, size: 16),
          label: Text('$label · $shown'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            textStyle: AppTextStyles.caption,
          ),
        ),
      ),
    );
  }
}
