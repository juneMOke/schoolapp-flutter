import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_widgets.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStep extends StatefulWidget {
  final String studentId;
  final String levelId;
  final EnrollmentStatus enrollmentStatus;
  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final bool isEditable;
  final EnrollmentStepSubmitController? stepController;

  /// Flux BROUILLON du wizard : génère les créances provisoires depuis la
  /// grille locale (FF5) avant lecture. Requiert [academicYearId] non vide,
  /// sinon dégrade en simple lecture.
  final bool initializeDraftCharges;
  final String academicYearId;
  final String? schoolLevelGroupId;

  const StudentChargesStep({
    super.key,
    required this.studentId,
    required this.levelId,
    required this.enrollmentStatus,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.isEditable = true,
    this.stepController,
    this.initializeDraftCharges = false,
    this.academicYearId = '',
    this.schoolLevelGroupId,
  });

  @override
  State<StudentChargesStep> createState() => StudentChargesStepState();
}

class StudentChargesStepState extends State<StudentChargesStep> {
  late final StudentChargesBloc _studentChargesBloc;
  late final StudentChargesStepController _controller;

  bool get _canFetch =>
      widget.studentId.trim().isNotEmpty && widget.levelId.trim().isNotEmpty;

  /// Le compte peut-il voir la grille tarifaire (ADR-014) ? Le serveur retire
  /// cette portion du référentiel à qui n'a pas `finance.grid.read`, si bien
  /// que rien ne peut être calculé localement — et une liste vide cesse de
  /// vouloir dire « cet élève ne doit rien ».
  ///
  /// Résolu dans [didChangeDependencies] plutôt qu'à la volée : la validité de
  /// l'étape en dépend, et elle se recalcule hors `build`.
  bool _tariffsWithheld = false;

  bool get _canEditAmounts =>
      widget.isEditable &&
      widget.enrollmentStatus == EnrollmentStatus.inProgress;

  void submitForm() => _onSave();

  /// Les champs de l'état dont l'étape dépend — pour reconstruire le corps
  /// **et** pour rejouer `_recomputeFormState`. Un seul prédicat pour les deux :
  /// `listenWhen` et `buildWhen` en portaient chacun une copie, et c'est
  /// précisément cette duplication qui a laissé passer l'oubli ci-dessous.
  ///
  /// `feeGridUnavailable` en fait partie et ne va pas de soi : il arrive dans un
  /// **second** `emit` qui ne touche à rien d'autre — le statut vaut déjà
  /// `success`, la liste de créances est la même instance, le type d'erreur est
  /// inchangé. L'omettre revient à ne jamais l'afficher ET à ne jamais
  /// recalculer la validité de l'étape : le secrétariat validait alors à 0 F sur
  /// une grille absente, ce que la garde était censée bloquer.
  static bool shouldReactTo(
    StudentChargesState prev,
    StudentChargesState curr,
  ) =>
      prev.status != curr.status ||
      prev.studentCharges != curr.studentCharges ||
      prev.errorType != curr.errorType ||
      prev.feeGridUnavailable != curr.feeGridUnavailable;

  @override
  void initState() {
    super.initState();
    _studentChargesBloc = getIt<StudentChargesBloc>();
    _controller = StudentChargesStepController();

    if (_canFetch) {
      _requestCharges();
    }

    _recomputeFormState(notifyParent: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });

    widget.stepController?.bind(submitForm);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTariffsWithheld();
  }

  /// Relit le droit sur la grille et, s'il a changé, recalcule la validité.
  ///
  /// Appelé au montage **et** à chaque changement de droits : un refresh en
  /// arrière-plan peut accorder ou retirer `finance.grid.read` pendant que le
  /// wizard est ouvert. [PermissionGate.allows] ne s'abonne à rien (lecture
  /// ponctuelle), et la valeur vit hors `build` puisque la validité de l'étape
  /// en dépend — sans l'abonnement posé par [_withPermissionWatch], le verdict
  /// restait celui du montage.
  ///
  /// ⚠️ **Ne reconstruit pas lui-même**, et c'est réservé à l'appel depuis
  /// [didChangeDependencies] : celui-ci précède immédiatement un `build`, et un
  /// `setState` y marquerait dirty un élément déjà en cours de construction.
  /// L'autre appelant — le listener de droits, hors phase de build — passe par
  /// [_onPermissionsChanged], qui reconstruit.
  void _syncTariffsWithheld() {
    final withheld = !PermissionGate.allows(context, const [
      Perm.financeGridRead,
    ]);
    if (withheld == _tariffsWithheld) return;
    _tariffsWithheld = withheld;
    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  /// Les droits ont changé **en séance** : relire ne suffit pas, il faut
  /// reconstruire.
  ///
  /// `_syncTariffsWithheld` s'en remettait à `_recomputeFormState` pour appeler
  /// `setState` — or celui-ci ne reconstruit que si la **validité** de l'étape
  /// bascule, et le droit sur la grille n'y entre que par
  /// `blocked = (tariffsWithheld || feeGridUnavailable) && charges.isEmpty`.
  /// Dès que des créances sont chargées, c'est-à-dire dans le cas normal, le
  /// verdict de droit changeait sans que rien ne reconstruise : le corps
  /// continuait de recevoir celui du montage jusqu'à ce qu'un changement
  /// d'état sans rapport le rafraîchisse.
  ///
  /// Rien ne s'en voyait à l'écran — avec une liste non vide, le corps affiche
  /// les créances quel que soit le droit — et c'est bien ce qui a laissé passer
  /// le défaut : le rebuild n'était garanti que par une **coïncidence**, celle
  /// des cas où l'affichage dépend du droit étant exactement ceux où la
  /// validité bascule. Le contrat est rétabli ici, et les deux widgets frères
  /// du même lot reconstruisent déjà inconditionnellement
  /// (`disciplinary_student_detail_page.dart`).
  void _onPermissionsChanged() {
    if (!mounted) return;
    final before = _tariffsWithheld;
    _syncTariffsWithheld();
    if (_tariffsWithheld != before) setState(() {});
  }

  @override
  void didUpdateWidget(covariant StudentChargesStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stepController != widget.stepController) {
      oldWidget.stepController?.unbind(submitForm);
      widget.stepController?.bind(submitForm);
    }

    final identifiersChanged =
        oldWidget.studentId != widget.studentId ||
        oldWidget.levelId != widget.levelId ||
        oldWidget.academicYearId != widget.academicYearId;

    if (identifiersChanged) {
      _controller.resetDraftState();
      if (_canFetch) {
        _requestCharges();
      }
      _recomputeFormState(notifyParent: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emitStepState();
      });
    }
  }

  @override
  void dispose() {
    widget.stepController?.unbind(submitForm);
    _controller.dispose();
    _studentChargesBloc.close();
    super.dispose();
  }

  void _requestCharges() {
    if (widget.initializeDraftCharges &&
        widget.academicYearId.trim().isNotEmpty) {
      _studentChargesBloc.add(
        DraftStudentChargesRequested(
          studentId: widget.studentId,
          levelId: widget.levelId,
          academicYearId: widget.academicYearId,
          schoolLevelGroupId: widget.schoolLevelGroupId,
        ),
      );
      return;
    }
    _studentChargesBloc.add(
      StudentChargesRequested(
        studentId: widget.studentId,
        levelId: widget.levelId,
      ),
    );
  }

  void _emitStepState() {
    final flowStepIndex = widget.flowStepIndex;
    if (flowStepIndex != null && mounted) {
      context.read<EnrollmentStepperFlowBloc>().add(
        EnrollmentStepperStepStateReported(
          step: flowStepIndex,
          stepState: _controller.stepState,
        ),
      );
    }
  }

  void _setSaving(bool saving) {
    if (_controller.isSaving == saving) return;
    setState(() => _controller.isSaving = saving);
    _emitStepState();
  }

  // Le champ édite un montant en unités monétaires ; l'entité (comme dans
  // Finance) stocke `expectedAmountInCents` en cents — même conversion que
  // FacturationChargeLine (cents / 100) et parseAmountToCents (unités * 100).
  String _formatAmount(double amountInCents) =>
      formatMonetaryAmount(amountInCents / 100);

  double? _parseAmount(String rawValue) {
    final parsed = parseMonetaryAmount(rawValue);
    if (parsed == null) return null;
    final cents = parsed * 100;
    final rounded = cents.roundToDouble();
    // Plus de 2 décimales saisies (ex. "1500.567") : rejeté comme invalide
    // plutôt qu'arrondi silencieusement au centime — l'utilisateur doit voir
    // l'erreur au lieu de faire persister un montant différent de celui tapé.
    if ((cents - rounded).abs() > 1e-6) return null;
    return rounded;
  }

  Map<String, String?> _buildAmountErrors(AppLocalizations l10n) {
    return _controller.buildAmountErrors(
      resolveError: (charge) {
        final rawValue = _controller.amountControllers[charge.id]?.text ?? '';
        return _parseAmount(rawValue) == null
            ? l10n.invalidNumberFieldError(l10n.studentChargesAmountColumn)
            : null;
      },
    );
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final changed = _controller.recomputeFormState(
      canFetch: _canFetch,
      canEditAmounts: _canEditAmounts,
      currentStatus: _studentChargesBloc.state.status,
      parseAmount: _parseAmount,
      tariffsWithheld: _tariffsWithheld,
      feeGridUnavailable: _studentChargesBloc.state.feeGridUnavailable,
    );

    if (changed) {
      setState(() {});
    }

    if (notifyParent) {
      _emitStepState();
    }
  }

  void _onAmountChanged(String _) {
    _recomputeFormState();
  }

  void _dispatchNextPendingUpdate() {
    final event = _controller.dispatchNextPendingUpdate();
    if (event == null) return;
    _studentChargesBloc.add(event);
  }

  void _finishBatchWithSuccess(AppLocalizations l10n) {
    _controller.finishBatch();
    _setSaving(false);
    _recomputeFormState();
    AppSnackBar.showSuccess(context, l10n.studentChargesSaveSuccess);
  }

  void _finishBatchWithFailure(
    AppLocalizations l10n,
    StudentChargesErrorType errorType,
  ) {
    _controller.finishBatch();
    _setSaving(false);
    _recomputeFormState();
    AppSnackBar.showError(context, errorType.localizedMessage(l10n));
  }

  void _onSave() {
    if (!_canEditAmounts) return;

    if (!_controller.isValid) {
      setState(() => _controller.showValidationHints = true);
      _emitStepState();
      return;
    }

    if (!_controller.isDirty) return;

    final updates = _controller.buildPendingUpdates(
      studentId: widget.studentId,
      parseAmount: _parseAmount,
    );
    if (updates.isEmpty) return;

    _controller.startBatchSaving(updates);
    _setSaving(true);
    _dispatchNextPendingUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _withPermissionWatch(child: _buildStep(context, l10n));
  }

  /// Rebranche [_onPermissionsChanged] sur les changements de droits. Absent de
  /// l'arbre en test, l'[AuthBloc] rend l'enveloppe transparente — même
  /// convention que `PermissionGate`.
  Widget _withPermissionWatch({required Widget child}) {
    final authBloc = PermissionGate.maybeBlocOf(context);
    if (authBloc == null) return child;

    return BlocListener<AuthBloc, AuthState>(
      bloc: authBloc,
      listenWhen: (prev, curr) =>
          !listEquals(prev.permissions, curr.permissions),
      listener: (_, _) => _onPermissionsChanged(),
      child: child,
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    return BlocProvider<StudentChargesBloc>.value(
      value: _studentChargesBloc,
      child: BlocConsumer<StudentChargesBloc, StudentChargesState>(
        listenWhen: shouldReactTo,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;

          if (state.status == StudentChargesStatus.success) {
            _controller.syncChargesFromState(
              state.studentCharges,
              formatAmount: _formatAmount,
            );

            if (_controller.isBatchSaving &&
                _controller.waitingForUpdateResult) {
              _controller.waitingForUpdateResult = false;

              if (!_controller.hasPendingUpdates) {
                _finishBatchWithSuccess(l10n);
              } else {
                _dispatchNextPendingUpdate();
              }

              if (_controller.showValidationHints) {
                setState(() => _controller.showValidationHints = false);
              }
              return;
            }

            _setSaving(false);
            _recomputeFormState();
          } else if (state.status == StudentChargesStatus.failure) {
            if (_controller.isBatchSaving &&
                _controller.waitingForUpdateResult) {
              _controller.waitingForUpdateResult = false;
              _finishBatchWithFailure(l10n, state.errorType);
              return;
            }

            _setSaving(false);
            _recomputeFormState();
          } else if (state.status == StudentChargesStatus.loading) {
            _recomputeFormState();
          }
        },
        buildWhen: shouldReactTo,
        builder: (context, state) {
          return StudentChargesStepBody(
            l10n: l10n,
            status: state.status,
            errorType: state.errorType,
            studentCharges: state.studentCharges,
            amountControllers: _controller.amountControllers,
            amountErrors: _buildAmountErrors(l10n),
            isEditable: _canEditAmounts,
            onRetry: _requestCharges,
            onAmountChanged: _onAmountChanged,
            unavailableMessage: _canFetch
                ? null
                : l10n.studentChargesUnavailable,
            tariffsWithheld: _tariffsWithheld,
            feeGridUnavailable: state.feeGridUnavailable,
          );
        },
      ),
    );
  }
}
