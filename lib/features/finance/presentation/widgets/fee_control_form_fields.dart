import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/search/search_group_box.dart';
import 'package:school_app_flutter/core/components/search/search_level_cascade.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_name_fields.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sélecteur du frais à contrôler, alimenté par la grille du niveau choisi.
///
/// Reste fermé tant qu'aucun niveau n'est sélectionné : un frais n'existe que
/// rapporté à un niveau. Quand la grille revient vide, le message distingue
/// **trois** causes — parce qu'elles se ressemblent à l'écran et pas au
/// guichet :
///
///  - « ce niveau n'a pas de frais » : information, il n'y a rien à contrôler ;
///  - « la grille n'est pas descendue ici » : à synchroniser (ou un droit à
///    ouvrir, cf. la variante caviardée) ;
///  - « la lecture a échoué » : on ne sait rien du tout — base verrouillée,
///    chiffrement indisponible, fichier corrompu.
///
/// La troisième était rendue comme la première : une base SQLCipher verrouillée
/// annonçait à l'opérateur que l'école n'a pas de frais pour ce niveau. Elle
/// affirmait sur l'école ce qui n'était vrai que de l'appareil, et le frais
/// étant **obligatoire** ici, la recherche restait fermée sans que rien
/// n'explique pourquoi ni n'offre d'issue.
class FeeControlFeeField extends StatelessWidget {
  final List<LocalFeeTariff> tariffs;
  final String? selectedFeeCode;
  final bool hasLevel;
  final bool isLoading;
  final bool feeGridMissing;

  /// La lecture locale de la grille n'a pas abouti — à ne jamais confondre avec
  /// une grille vide, qui, elle, est une information.
  final bool loadFailed;

  final ValueChanged<String?> onChanged;

  /// Rejoue la lecture du niveau courant. Seule porte de sortie de l'échec : le
  /// frais est obligatoire, donc l'écran est bloqué tant que la grille n'est pas
  /// lue, et remonter la cascade pour re-choisir le même niveau n'est ni évident
  /// ni suffisant.
  final VoidCallback onRetry;

  const FeeControlFeeField({
    super.key,
    required this.tariffs,
    required this.selectedFeeCode,
    required this.hasLevel,
    required this.isLoading,
    required this.feeGridMissing,
    required this.loadFailed,
    required this.onChanged,
    required this.onRetry,
  });

  /// Un `fee_code` n'apparaît qu'une fois : la grille peut porter à la fois un
  /// tarif de niveau et un tarif de cycle du même code, et deux entrées de même
  /// valeur casseraient le sélecteur.
  List<LocalFeeTariff> get _uniqueTariffs {
    final seen = <String>{};
    return tariffs
        .where((tariff) => seen.add(tariff.feeCode))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _uniqueTariffs;
    final enabled = hasLevel && !isLoading && items.isNotEmpty;

    final String? errorText;
    if (!hasLevel || isLoading || items.isNotEmpty) {
      errorText = null;
    } else if (loadFailed) {
      // En tête des trois : les deux autres messages affirment quelque chose
      // sur l'école ou sur la synchronisation, et une lecture qui n'a pas
      // abouti n'autorise ni l'une ni l'autre affirmation.
      errorText = l10n.feeControlFeeLoadFailed;
    } else if (feeGridMissing) {
      // Même défaut que le sélecteur de classe, et c'est le seul des trois
      // qu'un gabarit de rôle serveur produise réellement : le référentiel
      // descend sur `school.read`, mais le serveur en ampute la portion
      // tarifaire quand la session n'a pas `finance.grid.read`. « Synchronisez »
      // promet alors une mise à jour déjà faite, qui reviendra tout aussi
      // caviardée. Le wizard d'inscription traite déjà ce cas correctement.
      errorText =
          permissionHolding(context, const [Perm.financeGridRead]) ==
              PermissionHolding.missing
          ? l10n.feeControlFeeGridWithheld
          : l10n.feeControlFeeGridMissing;
    } else {
      errorText = l10n.feeControlFeeEmptyForLevel;
    }

    final field = EteeloSelectInput<String>(
      label: l10n.feeControlFeeLabel,
      placeholder: hasLevel ? null : l10n.feeControlFeePlaceholder,
      value: items.any((tariff) => tariff.feeCode == selectedFeeCode)
          ? selectedFeeCode
          : null,
      enabled: enabled,
      errorText: errorText,
      onChanged: onChanged,
      items: items
          .map(
            (tariff) => EteeloSelectItem<String>(
              value: tariff.feeCode,
              label: _itemLabel(tariff, l10n),
            ),
          )
          .toList(growable: false),
    );

    // Une erreur sans geste de reprise laisse l'opérateur devant un formulaire
    // qu'il ne peut pas armer. Le bouton n'apparaît que pour l'échec de
    // lecture : « pas de frais à ce niveau » et « grille pas encore descendue »
    // ne se réparent pas en réessayant.
    // `items.isNotEmpty` fait partie de la garde, et pas par excès de
    // prudence : le message d'erreur, lui, s'efface dès qu'il y a des frais à
    // choisir. Sans cette condition, une grille non vide rendue avec le drapeau
    // d'échec afficherait un bouton de reprise sans rien qui le motive.
    if (!loadFailed || !hasLevel || isLoading || items.isNotEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        field,
        const SizedBox(height: AppDimensions.spacingXS),
        EteeloButton.ghost(
          label: l10n.feeControlFeeLoadRetry,
          icon: Icons.refresh,
          onPressed: onRetry,
          // ⚠️ Jamais un `TextButton`/`OutlinedButton` nu ici : le thème du
          // dépôt les veut pleine largeur, et un bouton inline sans
          // `minimumSize` casse la mise en page (contrainte infinie).
          fullWidth: false,
          size: EteeloButtonSize.compact,
        ),
      ],
    );
  }

  /// Libellé + montant. Le libellé est celui du **code de frais** localisé
  /// (`localizedFeeLabel`), exactement comme les lignes de frais du détail
  /// Facturation — et non le `label` brut de la grille, qui varie d'un
  /// établissement à l'autre et ne se traduit pas. Le montant lève l'ambiguïté
  /// entre deux frais de noms proches sans obliger à ouvrir la grille.
  static String _itemLabel(LocalFeeTariff tariff, AppLocalizations l10n) {
    final amount = formatMonetaryAmountWithCurrency(
      amount: tariff.amountInCents / 100,
      currency: tariff.currency,
    );
    return '${tariff.feeCode.localizedFeeLabel(l10n)} · $amount';
  }
}

/// Groupe « Classe et frais » : la cascade Cycle → Niveau, le frais et le
/// statut. C'est le groupe **obligatoire** du formulaire, d'où sa coche verte
/// pilotée par [isComplete].
class FeeControlClassGroup extends StatelessWidget {
  final List<SearchCycle> cycles;
  final String? selectedGroupId;
  final String? selectedLevelKey;
  final List<OfflineClassroom> classrooms;
  final String? selectedClassroomId;
  final List<LocalFeeTariff> tariffs;
  final String? selectedFeeCode;
  final FeeControlPaymentFilter statusFilter;
  final bool hasLevel;
  final bool isLoading;
  final bool isTariffsLoading;
  final bool isClassroomsLoading;
  final bool feeGridMissing;
  final bool tariffsFailed;
  final bool isComplete;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<String?> onLevelChanged;
  final ValueChanged<String?> onClassroomChanged;
  final ValueChanged<String?> onFeeChanged;

  /// Rejoue la lecture de la grille du niveau courant, après un échec.
  final VoidCallback onRetryTariffs;
  final ValueChanged<FeeControlPaymentFilter?> onStatusChanged;

  const FeeControlClassGroup({
    super.key,
    required this.cycles,
    required this.selectedGroupId,
    required this.selectedLevelKey,
    required this.classrooms,
    required this.selectedClassroomId,
    required this.tariffs,
    required this.selectedFeeCode,
    required this.statusFilter,
    required this.hasLevel,
    required this.isLoading,
    required this.isTariffsLoading,
    required this.isClassroomsLoading,
    required this.feeGridMissing,
    required this.tariffsFailed,
    required this.isComplete,
    required this.onCycleChanged,
    required this.onLevelChanged,
    required this.onClassroomChanged,
    required this.onFeeChanged,
    required this.onRetryTariffs,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchGroupBox(
      icon: Icons.grid_view_rounded,
      title: l10n.feeControlSearchClassGroupTitle,
      isComplete: isComplete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchLevelCascade(
            cycles: cycles,
            selectedGroupId: selectedGroupId,
            selectedLevelKey: selectedLevelKey,
            isLoading: isLoading,
            cycleLabel: l10n.feeControlSearchCycleLabel,
            levelLabel: l10n.feeControlSearchLevelLabel,
            levelPlaceholder: l10n.feeControlSearchLevelPlaceholder,
            onCycleChanged: onCycleChanged,
            onLevelChanged: onLevelChanged,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          FeeControlClassroomField(
            classrooms: classrooms,
            selectedClassroomId: selectedClassroomId,
            hasLevel: hasLevel,
            isLoading: isLoading || isClassroomsLoading,
            onChanged: onClassroomChanged,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          FeeControlFeeField(
            tariffs: tariffs,
            selectedFeeCode: selectedFeeCode,
            hasLevel: hasLevel,
            isLoading: isLoading || isTariffsLoading,
            feeGridMissing: feeGridMissing,
            loadFailed: tariffsFailed,
            onChanged: onFeeChanged,
            onRetry: onRetryTariffs,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          FeeControlStatusField(
            selected: statusFilter,
            enabled: !isLoading,
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

/// Groupe « Affiner par élève » : les trois champs de noms, purement optionnels
/// — d'où une coche qui ne s'allume jamais, contrairement au groupe classe.
class FeeControlStudentGroup extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final bool enabled;

  const FeeControlStudentGroup({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchGroupBox(
      icon: Icons.person_outline,
      title:
          '${l10n.feeControlSearchStudentGroupTitle} · '
          '${l10n.feeControlSearchStudentGroupHint}',
      isComplete: false,
      child: SearchNameFields(
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        surnameController: surnameController,
        firstNameLabel: l10n.firstName,
        lastNameLabel: l10n.lastName,
        surnameLabel: l10n.surname,
        enabled: enabled,
        onChanged: (_) {},
      ),
    );
  }
}

/// Sélecteur de **classe** du niveau choisi — la maille sous le niveau.
///
/// Facultatif : la valeur vide vaut « toutes les classes du niveau ». Rendre la
/// classe obligatoire fermerait l'écran à un niveau dont les classes ne sont pas
/// encore composées, ou dont le roster n'est pas encore descendu sur l'appareil.
class FeeControlClassroomField extends StatelessWidget {
  /// Valeur sentinelle de « toutes les classes » — `EteeloSelectInput` distingue
  /// mal `null` (aucune sélection) d'un choix explicite.
  static const String allClassroomsValue = '__all__';

  final List<OfflineClassroom> classrooms;
  final String? selectedClassroomId;
  final bool hasLevel;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const FeeControlClassroomField({
    super.key,
    required this.classrooms,
    required this.selectedClassroomId,
    required this.hasLevel,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Reste ACTIF même sans classe composée : il porte alors la seule entrée
    // « toutes les classes du niveau », et le contrôle continue de fonctionner
    // à la maille niveau. Le message dit pourquoi la liste est courte.
    final enabled = hasLevel && !isLoading;
    final known = classrooms.any((c) => c.id == selectedClassroomId);
    // Une liste vide a deux causes, et une seule des deux se résoudra
    // (ADR-015 F1). Sans `classroom.read`, le roster n'est jamais tiré : dire
    // « aucune classe n'est composée pour ce niveau » affirme une chose sur
    // l'école alors qu'on ne sait rien d'elle — et laisse chercher côté
    // organisation des classes un manque qui est côté droits.
    final rosterWithheld =
        permissionHolding(context, const [Perm.classroomRead]) ==
        PermissionHolding.missing;

    return EteeloSelectInput<String>(
      label: l10n.feeControlClassroomLabel,
      placeholder: hasLevel ? null : l10n.feeControlClassroomPlaceholder,
      value: known ? selectedClassroomId : allClassroomsValue,
      enabled: enabled,
      errorText: hasLevel && !isLoading && classrooms.isEmpty
          ? (rosterWithheld
                ? l10n.feeControlClassroomWithheld
                : l10n.feeControlClassroomEmptyForLevel)
          : null,
      onChanged: onChanged,
      items: [
        EteeloSelectItem<String>(
          value: allClassroomsValue,
          label: l10n.feeControlClassroomAll,
        ),
        for (final classroom in classrooms)
          EteeloSelectItem<String>(value: classroom.id, label: classroom.name),
      ],
    );
  }
}

/// Filtre de statut de paiement (Tous / Payé / Partiel / À régler).
class FeeControlStatusField extends StatelessWidget {
  final FeeControlPaymentFilter selected;
  final bool enabled;
  final ValueChanged<FeeControlPaymentFilter?> onChanged;

  const FeeControlStatusField({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloSelectInput<FeeControlPaymentFilter>(
      label: l10n.feeControlPaymentStatusLabel,
      value: selected,
      enabled: enabled,
      onChanged: onChanged,
      items: FeeControlPaymentFilter.values
          .map(
            (filter) => EteeloSelectItem<FeeControlPaymentFilter>(
              value: filter,
              label: FeeControlPageHelpers.paymentFilterLabel(filter, l10n),
            ),
          )
          .toList(growable: false),
    );
  }
}
