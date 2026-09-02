import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart' as constants;
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/fee_code_section_cache_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_error_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le nom que l'école donne à ses natures de frais.
///
/// **Une nature ne veut pas dire la même chose d'un établissement à l'autre.**
/// Ce que l'un appelle « frais de dossier », l'autre l'appelle « frais de
/// rentrée » ; la distinction entre `REGISTRATION`, `ENROLLMENT` et `ADMISSION`
/// n'existe que dans l'énumération du serveur. Cet écran est ce qui rend la
/// grille lisible dans le vocabulaire de la direction.
///
/// **Le code, lui, ne bouge jamais** : c'est la clé, et c'est elle qui part sur
/// le fil. Renommer une section ne renomme aucune créance — celles-ci portent le
/// libellé du tarif, figé à leur naissance. Un renommage est donc libre, y
/// compris sur une année close.
///
/// **Masquer n'est pas supprimer** : la section quitte le sélecteur, jamais les
/// statistiques. Une nature masquée qui a encaissé continue de le montrer.
class FeeSectionsSettingsCard extends StatefulWidget {
  const FeeSectionsSettingsCard({super.key});

  @override
  State<FeeSectionsSettingsCard> createState() =>
      _FeeSectionsSettingsCardState();
}

/// Une ligne de l'écran : la section servie, plus la saisie en cours.
class _SectionRow {
  final FeeCodeOption served;
  final TextEditingController label;
  bool active;

  _SectionRow(this.served)
    : label = TextEditingController(text: served.label),
      active = served.active;
}

class _FeeSectionsSettingsCardState extends State<FeeSectionsSettingsCard> {
  List<_SectionRow>? _rows;
  bool _loading = false;
  bool _saving = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final row in _rows ?? const <_SectionRow>[]) {
      row.label.dispose();
    }
    super.dispose();
  }

  /// Toujours le catalogue **complet** : sans les masquées, les rétablir serait
  /// impossible — elles auraient disparu de l'écran qui sert à les gérer.
  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await getIt<ProvisioningRepository>().loadFeeCodes(
      includeHidden: true,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _failure = failure;
      }),
      (sections) => setState(() {
        _loading = false;
        _adopt(sections);
      }),
    );
  }

  void _adopt(List<FeeCodeOption> sections) {
    for (final row in _rows ?? const <_SectionRow>[]) {
      row.label.dispose();
    }
    _rows = [for (final section in sections) _SectionRow(section)];
  }

  /// Ce qui a bougé, et rien d'autre.
  ///
  /// **On n'envoie pas les vingt-trois sections à chaque enregistrement** : le
  /// serveur ne stocke que les surcharges, et tout lui envoyer ferait naître
  /// vingt-trois lignes là où la direction n'a renommé qu'un titre. Chaque champ
  /// part indépendamment : renommer n'écrit pas un rang, masquer n'écrit pas un
  /// titre.
  List<FeeCodeSectionEdit> _pendingEdits() {
    final rows = _rows ?? const <_SectionRow>[];
    final edits = <FeeCodeSectionEdit>[];
    for (final (index, row) in rows.indexed) {
      final label = row.label.text.trim();
      final labelChanged = label != row.served.label;
      final activeChanged = row.active != row.served.active;
      final orderChanged = index != row.served.sortOrder;
      if (!labelChanged && !activeChanged && !orderChanged) continue;

      edits.add(
        FeeCodeSectionEdit(
          code: row.served.code,
          label: labelChanged ? label : null,
          active: activeChanged ? row.active : null,
          sortOrder: orderChanged ? index : null,
        ),
      );
    }
    return edits;
  }

  bool get _hasBlankLabel => (_rows ?? const <_SectionRow>[]).any(
    (row) => row.label.text.trim().isEmpty,
  );

  Future<void> _save() async {
    final edits = _pendingEdits();
    if (edits.isEmpty || _saving) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final result = await getIt<ProvisioningRepository>().saveFeeCodeSections(
      edits,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      // Le message du serveur tel quel : c'est lui qui nomme les deux sections
      // qui se disputent un titre, et aucune phrase générique ne le dirait.
      (failure) => AppSnackBar.showError(context, failure.message),
      (sections) {
        setState(() => _adopt(sections));
        // Le cache local des titres suit **immédiatement** (GF-0). Attendre le
        // prochain cycle de pull ferait afficher l'ancien titre en Facturation
        // alors que la direction vient de le changer sous ses yeux — et le
        // temps d'attente ne dépendrait de rien qu'elle puisse observer.
        //
        // Volontairement non attendu, et sans `mounted` derrière : l'écriture
        // ne rend rien à l'écran, et son échec est déjà absorbé par le
        // repository. Le renommage, lui, a bien eu lieu côté serveur — c'est ce
        // que le message de succès annonce.
        unawaited(
          getIt<FeeCodeSectionCacheRepository>().cacheFeeCodeSections(sections),
        );
        AppSnackBar.showSuccess(context, l10n.configurationSectionsSaved);
      },
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final rows = _rows!;
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      rows.insert(target, rows.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _rows;

    return FinanceSectionCard(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.sell_outlined,
            title: l10n.configurationSectionsTitle,
            subtitle: l10n.configurationSectionsSubtitle,
            accent: constants.AppColors.bleuArdoise,
            accentSoft: AppColors.surfaceAlt,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failure case final failure?)
            ConfigurationErrorView(failure: failure, onRetry: _load)
          else if (rows != null) ...[
            Text(
              l10n.configurationSectionsReorderHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ReorderableListView.builder(
              // Imbriqué dans le défilement de l'onglet : la liste ne défile
              // pas d'elle-même, sinon deux surfaces défilantes se disputent le
              // geste et le glisser-déposer devient impossible à viser.
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: rows.length,
              onReorder: _reorder,
              itemBuilder: (context, index) =>
                  _row(context, rows[index], index, l10n),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.configurationSectionsHiddenHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving || _hasBlankLabel || _pendingEdits().isEmpty
                    ? null
                    : _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _hasBlankLabel
                      ? l10n.configurationSectionsLabelRequired
                      : l10n.configurationSectionsSave,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    _SectionRow row,
    int index,
    AppLocalizations l10n,
  ) {
    return Padding(
      key: ValueKey(row.served.code),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: row.label,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                // Le code sous le champ : c'est ce qui part sur le fil, et le
                // seul repère stable quand la direction renomme.
                helperText: row.served.code,
                helperStyle: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Switch(
            value: row.active,
            onChanged: (value) => setState(() => row.active = value),
          ),
        ],
      ),
    );
  }
}
