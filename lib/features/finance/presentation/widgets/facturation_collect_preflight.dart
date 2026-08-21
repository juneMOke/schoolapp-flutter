import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/refresh_ledger_before_collection_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Délai au bout duquel l'attente devient visible. En deçà, on ne montre rien :
/// avec le TTL du refresher, la plupart des taps « Encaisser » n'attendent
/// strictement rien, et une modale ouverte puis refermée en 20 ms se lit comme
/// un bug, pas comme une vérification.
///
/// Ce n'est pas une animation mais un seuil de perception ; il emprunte le token
/// `standard` parce que c'est la durée que le module tient déjà pour « le temps
/// qu'un changement d'état devienne lisible », et qu'un second réglage à côté
/// dériverait sans que personne ne le rapproche de celui-ci.
const Duration _barrierDelay = FinanceMotion.standard;

/// Vérifie le grand-livre AVANT d'ouvrir la modale d'encaissement, puis relit
/// les créances locales.
///
/// C'est la seule attente réseau qui subsiste sur cet écran, et la seule que
/// `FACTURATION_OFFLINE_PLAN.md` §13 ait demandée : le « reste » composé qui
/// s'affiche dans la modale borne la saisie et décide s'il faut encaisser.
/// Sous-estimé parce qu'un versement du poste voisin n'est pas encore descendu,
/// il fait réencaisser. Les *lectures*, elles, n'attendent plus rien.
///
/// L'attente est doublement bornée par
/// [RefreshLedgerBeforeCollectionUseCase] — un cycle récent n'est pas rejoué, et
/// un cycle lent est abandonné en cours (il poursuit en tâche de fond).
///
/// Rend les créances relues, ou `null` si la relecture locale n'a pas abouti :
/// l'appelant retombe alors sur ce qui est déjà à l'écran. On ne refuse pas un
/// encaissement parce qu'une relecture de confort a échoué — refuser, c'est
/// renvoyer une famille qui a l'argent en main.
Future<List<StudentCharge>?> runFacturationCollectPreflight(
  BuildContext context, {
  required String studentId,
  required String academicYearId,
}) async {
  final work = _refreshThenRead(
    studentId: studentId,
    academicYearId: academicYearId,
  );

  // Le minuteur est ANNULÉ dès que la course est tranchée : `Future.any` ne
  // désarme pas le perdant, et un minuteur qui survit à son utilité est une
  // fuite (que le harnais de test signale, à juste titre).
  final barrierDue = Completer<void>();
  final barrierTimer = Timer(_barrierDelay, () {
    if (!barrierDue.isCompleted) barrierDue.complete();
  });
  final settled = await Future.any(<Future<_PreflightOutcome?>>[
    work.then<_PreflightOutcome?>(_PreflightOutcome.new),
    barrierDue.future.then<_PreflightOutcome?>((_) => null),
  ]);
  barrierTimer.cancel();
  if (settled != null) return settled.charges;
  if (!context.mounted) return work;

  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
      builder: (_) => const _CollectPreflightBarrier(),
    ),
  );
  try {
    return await work;
  } finally {
    // La barrière n'a ni bouton, ni dismiss, ni retour système : la seule route
    // que ce `pop` puisse retirer est la nôtre.
    if (navigator.canPop()) navigator.pop();
  }
}

/// Revalidation bornée puis relecture LOCALE. Ne lève jamais : cette fonction
/// est awaitée par le chemin d'encaissement, qui doit rester ouvrable même
/// quand la synchro tombe.
Future<List<StudentCharge>?> _refreshThenRead({
  required String studentId,
  required String academicYearId,
}) async {
  try {
    await getIt<RefreshLedgerBeforeCollectionUseCase>()(
      studentId: studentId,
      academicYearId: academicYearId,
    );
  } catch (_) {
    // Best-effort : hors ligne, jetons expirés, serveur muet. On encaisse quand
    // même — c'est précisément le mode de travail que l'offline-first vise.
  }
  try {
    final read = await getIt<GetStudentChargesByAcademicYearUseCase>()(
      GetStudentChargesByAcademicYearParams(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
    return read.fold((_) => null, (charges) => charges);
  } catch (_) {
    return null;
  }
}

/// Enveloppe qui distingue « terminé, éventuellement sans créances » (`null`
/// porté par l'enveloppe) de « pas encore terminé » (enveloppe absente).
class _PreflightOutcome {
  final List<StudentCharge>? charges;

  const _PreflightOutcome(this.charges);
}

class _CollectPreflightBarrier extends StatelessWidget {
  const _CollectPreflightBarrier();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.financeDetailCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        ),
        contentPadding: const EdgeInsets.all(AppDimensions.detailCardPadding),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppDimensions.spacingL,
              height: AppDimensions.spacingL,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Flexible(
              child: Text(
                l10n.facturationCollectPreflightMessage,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
