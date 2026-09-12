import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_entry_type_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de la liste nominative : l'instant, l'élève, son niveau, son type
/// et l'agent qui l'a enregistré.
///
/// ## Le sexe est toujours écrit
///
/// L'avatar garde sa **teinte d'identité** — déterministe, dérivée de
/// l'identifiant de l'élève, auditée AA — et ne porte aucune information. Le
/// sexe est écrit sous le nom, en toutes lettres. Colorer l'avatar par sexe
/// aurait fait porter la donnée par la seule couleur, et sorti le composant de
/// sa palette auditée, pour une information déjà lisible.
///
/// ## L'heure peut manquer, et c'est voulu
///
/// Elle vient de `createdAt` — l'instant de la saisie — alors que tout le
/// reste de l'écran s'aligne sur `enrollmentDate`, la date administrative. Sur
/// un dossier antidaté ou poussé le soir depuis un poste hors ligne, les deux
/// divergent et l'heure ne dit plus rien de la journée affichée. Elle laisse
/// alors un tiret : mieux vaut une case vide qu'une heure fausse dans une
/// colonne qui a l'autorité d'une colonne.
abstract final class EnrollmentEntryRow {
  /// [singleDay] choisit la première cellule : l'heure de saisie sur une
  /// journée, la date administrative au-delà.
  static DataTableRowSpec of(
    BuildContext context,
    DayEnrollmentEntry entry, {
    required bool singleDay,
    void Function(DayEnrollmentEntry entry)? onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final genderLabel = entry.gender == Gender.female
        ? l10n.enrollmentDashboardGenderGirls
        : l10n.enrollmentDashboardGenderBoys;
    final typeLabel = entry.formerStudent
        ? l10n.enrollmentDashboardTypeRe
        : l10n.enrollmentDashboardTypeFirst;

    return DataTableRowSpec(
      id: entry.enrollmentId,
      displayName: entry.displayName,
      leading: StudentAvatar(
        firstName: entry.firstName,
        lastName: entry.lastName,
        studentId: entry.studentId,
        size: AppDimensions.enrollmentDashboardDayAvatarSize,
      ),
      onTap: onTap == null ? null : () => onTap(entry),
      cells: [
        DataTableCellSpec(
          text: !singleDay
              ? dates.formatCompactDate(entry.enrollmentDate)
              : entry.hourIsMeaningful
              ? dates.formatTimeOfDay(TimeOfDay.fromDateTime(entry.createdAt))
              : l10n.enrollmentDashboardEntriesNoHour,
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          text: entry.displayName,
          variant: DataTableCellTextVariant.strong,
          // Le sexe, écrit. Jamais porté par la seule couleur de l'avatar.
          secondaryText: genderLabel,
        ),
        DataTableCellSpec(text: entry.schoolLevel),
        DataTableCellSpec(
          child: EnrollmentEntryTypePill(
            label: typeLabel,
            isReturning: entry.formerStudent,
          ),
        ),
        DataTableCellSpec(
          // Nul quand l'annuaire ne résout pas — compte inconnu, ou écriture
          // SYSTEM. Un tiret, jamais une attribution inventée.
          text: entry.recordedBy?.trim().isNotEmpty == true
              ? entry.recordedBy!
              : l10n.enrollmentDashboardEntriesUnknownAgent,
        ),
      ],
    );
  }
}
