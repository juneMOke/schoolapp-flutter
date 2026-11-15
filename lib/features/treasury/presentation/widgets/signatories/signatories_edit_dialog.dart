import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/services/report_signatory_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/signatories/signatories_message.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/signatories/signatory_row_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

typedef SignatoriesSave =
    Future<Either<Failure, ReportSignatories>> Function(
      List<ReportSignatory> list,
    );

/// Ce qu'a fait la modale, pour le toast.
enum SignatoriesOutcome { saved, defaultsRestored }

/// Modifier les signataires des rapports : jusqu'à quatre blocs, dans l'ordre
/// d'impression. Part de ce que les rapports impriment aujourd'hui.
Future<SignatoriesOutcome?> showSignatoriesEditDialog(
  BuildContext context, {
  required ReportSignatories current,
  required SignatoriesSave onSave,
}) => EteeloFormDialog.show<SignatoriesOutcome>(
  context,
  _SignatoriesEditDialog(current: current, onSave: onSave),
);

class _SignatoriesEditDialog extends StatefulWidget {
  final ReportSignatories current;
  final SignatoriesSave onSave;

  const _SignatoriesEditDialog({required this.current, required this.onSave});

  @override
  State<_SignatoriesEditDialog> createState() => _SignatoriesEditDialogState();
}

class _SignatoriesEditDialogState extends State<_SignatoriesEditDialog> {
  late var _shown = widget.current;
  late var _drafts = _draftsOf(_shown);
  var _saving = false;
  var _showErrors = false;
  Failure? _failure;

  /// Le nom de qui a changé la liste entre-temps, quand le serveur l'a dit.
  String? _changedBy;
  var _changed = false;

  static List<SignatoryDraft> _draftsOf(ReportSignatories s) => [
    for (final signatory in s.printed) SignatoryDraft.of(signatory),
  ];

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  List<ReportSignatory> get _list => [
    for (final (index, d) in _drafts.indexed) d.toSignatory(index + 1),
  ];

  bool get _valid => ReportSignatoryRules.isListValid(_list);

  /// Rien n'a bougé depuis ce qui est montré : rien à enregistrer. En mode
  /// défauts, cela évite de figer d'un clic des noms que le serveur déduit
  /// des titulaires des rôles.
  bool get _unchanged => ReportSignatoryRules.sameList(_list, _shown.printed);

  void _move(int index, int delta) => setState(() {
    final draft = _drafts.removeAt(index);
    _drafts.insert(index + delta, draft);
    // « La personne qui a clôturé » n'a de sens qu'au premier rang.
    for (final d in _drafts.skip(1)) {
      d.filledByCloser = false;
    }
  });

  void _remove(int index) => setState(() {
    _drafts.removeAt(index).dispose();
  });

  Future<void> _restoreDefaults() async {
    final confirmed = await confirmRestoreDefaults(context);
    if (confirmed && mounted) await _save(toDefaults: true);
  }

  Future<void> _save({bool toDefaults = false}) async {
    if (!toDefaults && !_valid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    // Tout retirer revient aux blocs par défaut, comme le bouton.
    final restore = toDefaults || _drafts.isEmpty;
    final result = await widget.onSave(restore ? const [] : _list);
    if (!mounted) return;
    result.fold(
      _refused,
      (_) => Navigator.of(context).pop(
        restore
            ? SignatoriesOutcome.defaultsRestored
            : SignatoriesOutcome.saved,
      ),
    );
  }

  void _refused(Failure failure) => setState(() {
    _saving = false;
    if (failure is SignatoriesChangedFailure) {
      // Rien n'est enregistré : on montre la liste actuelle à la place, pour
      // qu'on la relise avant de recommencer.
      for (final d in _drafts) {
        d.dispose();
      }
      _shown = failure.current;
      _drafts = _draftsOf(_shown);
      _changed = true;
      _changedBy = failure.current.updatedByName;
      _showErrors = false;
    } else {
      _failure = failure;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    final canAdd = _drafts.length < ReportSignatoryRules.maxSignatories;
    // Actif même sur une saisie incomplète : l'appui montre ce qui manque.
    final VoidCallback? submit = _saving || _unchanged ? null : _save;
    // Pendant l'envoi, ni la barrière ni Échap ne ferment la modale.
    return PopScope(
      canPop: !_saving,
      child: _dialog(context, l10n, failure, canAdd, submit),
    );
  }

  Widget _dialog(
    BuildContext context,
    AppLocalizations l10n,
    Failure? failure,
    bool canAdd,
    VoidCallback? submit,
  ) {
    return EteeloFormDialog(
      onSubmit: submit,
      maxWidth: AppDimensions.treasuryRegisterModalMaxWidth,
      eyebrow: l10n.treasuryFormEyebrow,
      title: l10n.treasurySignatoriesTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.treasurySignatoriesEditHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_shown.defaults) ...[
            const SizedBox(height: AppSpacing.sm),
            SignatoriesMessage(
              text: l10n.treasurySignatoriesFreezeWarning,
              color: AppColors.financeCrossedAccent,
            ),
          ],
          if (_changed) ...[
            const SizedBox(height: AppSpacing.sm),
            SignatoriesMessage(
              text: _changedBy == null
                  ? l10n.treasurySignatoriesChanged
                  : l10n.treasurySignatoriesChangedBy(_changedBy!),
              color: AppColors.financeCrossedAccent,
            ),
          ],
          for (final (index, draft) in _drafts.indexed) ...[
            const SizedBox(height: AppSpacing.md),
            SignatoryRowFields(
              key: draft.key,
              draft: draft,
              index: index,
              count: _drafts.length,
              enabled: !_saving,
              showErrors: _showErrors,
              onChanged: () => setState(() {}),
              onMove: (delta) => _move(index, delta),
              onRemove: () => _remove(index),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: EteeloButton.ghost(
              label: canAdd
                  ? l10n.treasurySignatoryAdd
                  : l10n.treasurySignatoriesMax(
                      ReportSignatoryRules.maxSignatories,
                    ),
              icon: Icons.add,
              onPressed: canAdd && !_saving
                  ? () => setState(() => _drafts.add(SignatoryDraft.of(null)))
                  : null,
              fullWidth: false,
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SignatoriesMessage(
              text: l10n.treasurySaveFailed(
                l10n.treasuryFailureReason(failure),
              ),
              color: AppColors.error,
            ),
          ],
        ],
      ),
      leading: _shown.defaults
          ? null
          : EteeloButton.ghost(
              label: l10n.treasurySignatoriesUseDefaults,
              onPressed: _saving ? null : _restoreDefaults,
              fullWidth: false,
            ),
      actions: [
        EteeloButton.secondary(
          label: l10n.treasuryCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.treasurySignatoriesSave,
          icon: Icons.check,
          isLoading: _saving,
          onPressed: submit,
          fullWidth: false,
        ),
      ],
    );
  }
}
