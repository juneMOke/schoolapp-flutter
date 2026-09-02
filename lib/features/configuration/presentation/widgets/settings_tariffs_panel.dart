import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_amount.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_error_view.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/tariff_edit_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les tarifs d'un niveau, dépliables.
///
/// **Un tarif porte UN niveau.** Ce que l'assistant saisissait comme « un
/// minerval sur vingt niveaux » est devenu vingt lignes distinctes, chacune avec
/// son identifiant : les modifier ensemble n'est pas offert ici, et ne doit pas
/// l'être tant que le serveur n'a pas de geste pour ça — l'écran promettrait
/// sinon une atomicité qu'il ne peut pas tenir.
///
/// Chargement paresseux : les tarifs d'un niveau ne partent qu'à l'ouverture du
/// panneau. Les charger tous d'un coup ferait une vingtaine d'appels pour un
/// écran dont on ne consulte qu'une ligne.
class SettingsTariffsPanel extends StatefulWidget {
  final String levelId;
  final String levelName;
  final String schoolLevelGroupId;
  final String academicYearId;

  const SettingsTariffsPanel({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.schoolLevelGroupId,
    required this.academicYearId,
  });

  @override
  State<SettingsTariffsPanel> createState() => _SettingsTariffsPanelState();
}

class _SettingsTariffsPanelState extends State<SettingsTariffsPanel> {
  List<FeeTariff>? _tariffs;

  /// Le catalogue **complet**, masquées comprises.
  ///
  /// Un tarif peut porter une nature que l'école a depuis masquée : sans elle
  /// dans cette liste, sa ligne s'afficherait sous son code brut (« BOARDING »)
  /// au lieu du titre que la direction avait écrit. Le sélecteur, lui, ne reçoit
  /// que les sections encore attribuables — cf. [_selectableFeeCodes].
  List<FeeCodeOption> _feeCodes = const <FeeCodeOption>[];
  bool _loading = false;

  /// L'échec tel qu'il est venu, pas un drapeau.
  ///
  /// Un booléen forçait l'écran à parler de réseau quoi qu'il arrive — et à
  /// proposer « Réessayer » sur un 403, qu'aucun nouvel appel ne lèvera.
  Failure? _failure;

  /// Une écriture est en vol : les actions se ferment. Ici, contrairement au
  /// brouillon de l'assistant, chaque geste part au serveur — un double envoi
  /// créerait deux tarifs sur le même niveau.
  bool _writing = false;

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failure = null;
    });

    final repository = getIt<ProvisioningRepository>();
    final result = await repository.loadTariffs(widget.levelId);
    // Le catalogue de frais est en cache de session : ce second appel ne coûte
    // rien après la première ouverture.
    final codes = await repository.loadFeeCodes(includeHidden: true);
    // `mounted` après l'await : le panneau peut avoir été replié, ou l'onglet
    // changé, pendant que la requête volait.
    if (!mounted) return;

    _feeCodes = codes.getOrElse(() => const <FeeCodeOption>[]);
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _failure = failure;
      }),
      (tariffs) => setState(() {
        _loading = false;
        _tariffs = tariffs;
      }),
    );
  }

  /// Les sections que le formulaire peut encore proposer.
  List<FeeCodeOption> get _selectableFeeCodes => [
    for (final option in _feeCodes)
      if (option.active) option,
  ];

  /// Les tarifs du niveau, **regroupés sous le titre de leur section**.
  ///
  /// C'est la raison d'être du regroupement : sept tranches de minerval
  /// s'affichaient sept fois de suite, chacune surmontée du même code brut
  /// « TUITION ». Elles tiennent désormais sous un seul titre, celui que l'école
  /// a écrit.
  ///
  /// L'ordre est celui du serveur — donc celui que l'école a choisi. Une nature
  /// que le catalogue ne sert pas du tout (serveur plus vieux, code retiré)
  /// n'est pas perdue : elle ferme la liste sous son code, qui reste affichable.
  List<({String title, List<FeeTariff> lines})> get _sections {
    final tariffs = _tariffs ?? const <FeeTariff>[];
    final byCode = <String, List<FeeTariff>>{};
    for (final tariff in tariffs) {
      byCode.putIfAbsent(tariff.feeCode, () => <FeeTariff>[]).add(tariff);
    }

    final sections = <({String title, List<FeeTariff> lines})>[];
    for (final option in _feeCodes) {
      final lines = byCode.remove(option.code);
      if (lines != null) sections.add((title: option.label, lines: lines));
    }
    for (final entry in byCode.entries) {
      sections.add((title: entry.key, lines: entry.value));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ExpansionTile(
      title: Text(widget.levelName, style: AppTypography.bodyMedium),
      tilePadding: EdgeInsets.zero,
      onExpansionChanged: (expanded) {
        if (expanded && _tariffs == null) _load();
      },
      children: [
        if (_loading)
          // Un squelette, jamais une barre de progression : la ligne de tarifs
          // qui arrive a une forme, et la montrer évite le saut de mise en
          // page au moment où les chiffres s'affichent.
          Semantics(
            container: true,
            liveRegion: true,
            label: l10n.configurationLoadingA11yLabel,
            child: const ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    EteeloSkeletonBox(width: double.infinity, height: 40),
                    SizedBox(height: AppSpacing.xs),
                    EteeloSkeletonBox(width: double.infinity, height: 40),
                  ],
                ),
              ),
            ),
          )
        else if (_failure case final failure?)
          // Le même classement que l'assistant : un 403 ne propose rien, un 429
          // non plus. L'écran des réglages n'a pas de raison d'être plus
          // bavard — ni moins juste — que le parcours de mise en service.
          ConfigurationErrorView(failure: failure, onRetry: _load)
        else ...[
          if ((_tariffs ?? const <FeeTariff>[]).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.configurationTariffNone,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          for (final section in _sections) ...[
            // Le titre de la SECTION, pas le code brut : c'est ce que l'école a
            // écrit, et c'est sous lui que ses tranches se lisent comme un tout.
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                section.title,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            for (final tariff in section.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tariff.label,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Text(
                      FeeAmount.display(tariff.amountInCents, tariff.currency),
                      style: AppTypography.money,
                    ),
                    IconButton(
                      onPressed: _writing ? null : () => _edit(tariff),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      onPressed: _writing ? null : () => _delete(tariff),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ],
                ),
              ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _writing ? null : _create,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.configurationTariffAdd),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _create() => _openDialog(null);

  Future<void> _edit(FeeTariff tariff) => _openDialog(tariff);

  Future<void> _openDialog(FeeTariff? tariff) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<TariffEditResult>(
      context: context,
      builder: (_) => TariffEditDialog(
        feeCodes: _selectableFeeCodes,
        levelName: widget.levelName,
        initial: tariff,
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _writing = true);
    final draft = FeeTariffDraft(
      feeCode: result.feeCode,
      label: result.label,
      amountInCents: result.amountInCents,
      currency: result.currency,
      dueAt: result.dueAt,
      schoolLevelId: widget.levelId,
      schoolLevelGroupId: widget.schoolLevelGroupId,
      academicYearId: widget.academicYearId,
    );

    final repository = getIt<ProvisioningRepository>();
    final outcome = tariff == null
        ? await repository.createTariff(draft)
        : await repository.updateTariff(tariff.id, draft);
    if (!mounted) return;

    setState(() => _writing = false);
    outcome.fold((failure) => AppSnackBar.showError(context, failure.message), (
      _,
    ) {
      AppSnackBar.showSuccess(context, l10n.configurationTariffSaved);
      // On relit plutôt que de rapiécer la liste en mémoire : le serveur
      // peut avoir normalisé le libellé ou l'échéance, et un écran qui
      // affiche ce qu'il a envoyé plutôt que ce qui est écrit ment sur de
      // l'argent.
      _tariffs = null;
      _load();
    });
  }

  Future<void> _delete(FeeTariff tariff) async {
    final l10n = AppLocalizations.of(context)!;
    // Confirmation, contrairement à la ligne de l'assistant : là-bas on
    // supprimait un brouillon local, ici on écrit sur le serveur.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.configurationTariffDelete),
        content: Text(l10n.configurationTariffDeleteConfirm(tariff.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.configurationFeeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.configurationTariffDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _writing = true);
    final outcome = await getIt<ProvisioningRepository>().deleteTariff(
      tariff.id,
    );
    if (!mounted) return;

    setState(() => _writing = false);
    outcome.fold((failure) => AppSnackBar.showError(context, failure.message), (
      _,
    ) {
      AppSnackBar.showSuccess(context, l10n.configurationTariffDeleted);
      _tariffs = null;
      _load();
    });
  }
}
