import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/core/widgets/money_bag_text.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_list.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_loading_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStepBody extends StatelessWidget {
  final AppLocalizations l10n;
  final StudentChargesStatus status;
  final StudentChargesErrorType errorType;
  final List<StudentCharge> studentCharges;
  final Map<String, TextEditingController> amountControllers;
  final Map<String, String?> amountErrors;
  final bool isEditable;
  final VoidCallback onRetry;
  final ValueChanged<String> onAmountChanged;
  final String? unavailableMessage;

  /// Le compte n'a pas `finance.grid.read` : le serveur retire la grille
  /// tarifaire du référentiel (ADR-014), donc rien ne peut être calculé
  /// localement. Une liste vide ne veut alors pas dire « rien à payer ».
  final bool tariffsWithheld;

  /// La grille est absente de CET APPAREIL pour l'année visée, quel que soit
  /// le droit du compte courant — typiquement parce qu'un profil sans
  /// `finance.grid.read` a hydraté le référentiel en premier sur une tablette
  /// partagée. Même conséquence, autre remède : ici une synchronisation suffit.
  final bool feeGridUnavailable;

  const StudentChargesStepBody({
    super.key,
    required this.l10n,
    required this.status,
    required this.errorType,
    required this.studentCharges,
    required this.amountControllers,
    required this.amountErrors,
    required this.isEditable,
    required this.onRetry,
    required this.onAmountChanged,
    this.unavailableMessage,
    this.tariffsWithheld = false,
    this.feeGridUnavailable = false,
  });

  // Le champ affiche/édite des unités monétaires ; on revient en cents (même
  // conversion que StudentChargesStep._parseAmount) pour sommer comme l'entité.
  double _draftAmountInCentsFor(StudentCharge charge) {
    final parsed = parseMonetaryAmount(
      amountControllers[charge.id]?.text ?? '',
    );
    return parsed == null
        ? charge.expectedAmountInCents
        : (parsed * 100).roundToDouble();
  }

  /// Le total du brouillon, **par devise**.
  ///
  /// Ce sont les montants SAISIS qui sont sommés, pas ceux de la grille : le
  /// guichet peut ajuster une ligne, et le pied doit suivre. Chacun garde la
  /// devise de sa créance — une ligne en francs ne vient pas gonfler le total
  /// en dollars.
  MoneyBag _totalBag() => MoneyBag.sumBy(
    studentCharges,
    (charge) =>
        Money.parse(_draftAmountInCentsFor(charge).round(), charge.currency),
  );

  @override
  Widget build(BuildContext context) {
    if (unavailableMessage != null) {
      return StudentChargesErrorState(message: unavailableMessage!);
    }

    return switch (status) {
      StudentChargesStatus.initial ||
      StudentChargesStatus.loading => const StudentChargesLoadingState(),
      StudentChargesStatus.failure => StudentChargesErrorState(
        message: errorType.localizedMessage(l10n),
        onRetry: onRetry,
      ),
      StudentChargesStatus.success =>
        studentCharges.isEmpty
            // « Aucune charge » et « je n'ai pas pu les calculer » se
            // ressemblent à l'écran et ne se ressemblent pas au guichet :
            // le premier laisse partir la famille sans rien devoir, le second
            // fait manquer l'encaissement du jour. On ne les confond pas.
            // Trois lectures d'une liste vide, trois gestes différents : le
            // droit manque (l'administration doit agir), la grille manque sur
            // l'appareil (une synchronisation suffit), ou ce niveau n'a
            // réellement pas de frais (on poursuit).
            ? (tariffsWithheld
                  ? StudentChargesErrorState(
                      message: l10n.studentChargesTariffsWithheld,
                    )
                  : feeGridUnavailable
                  ? StudentChargesErrorState(
                      message: l10n.studentChargesFeeGridUnavailable,
                    )
                  : const StudentChargesEmptyState())
            : Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentChargesList(
                      l10n: l10n,
                      studentCharges: studentCharges,
                      amountControllers: amountControllers,
                      amountErrors: amountErrors,
                      isEditable: isEditable,
                      onAmountChanged: onAmountChanged,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.studentChargesTotalLabel,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        MoneyBagText(
                          bag: _totalBag(),
                          style: AppTextStyles.totalAmountLora.copyWith(
                            color: AppColors.bleuArdoise,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    };
  }
}
