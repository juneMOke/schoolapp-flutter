// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get hello => 'Bonjour';

  @override
  String get login => 'Connexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get passwordTooShort => 'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre email';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un email valide';

  @override
  String get schoolApp => 'ETEELO TECH';

  @override
  String get logout => 'Déconnexion';

  @override
  String welcome(String name) {
    return 'Bienvenue$name !';
  }

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get receiveOtp => 'Recevoir un code OTP';

  @override
  String get enterEmailToReceiveOtp => 'Saisissez votre email pour recevoir un code de vérification.';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get otpValidation => 'Validation OTP';

  @override
  String get enterSixDigitCode => 'Entrez le code à 6 chiffres';

  @override
  String codeSentTo(String email) {
    return 'Code envoyé à $email';
  }

  @override
  String get otpCodeLabel => 'Code OTP';

  @override
  String get validateCode => 'Valider le code';

  @override
  String get otpMustBeSixDigits => 'Le code OTP doit contenir 6 chiffres';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get chooseNewPassword => 'Choisissez un nouveau mot de passe';

  @override
  String account(String email) {
    return 'Compte: $email';
  }

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get validateAndLogin => 'Valider et se connecter';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get menuInscriptions => 'Inscriptions';

  @override
  String get menuFinances => 'Finances';

  @override
  String get menuClasses => 'Classes';

  @override
  String get menuDisciplines => 'Disciplines';

  @override
  String get subMenuDashboard => 'Tableau de Bord';

  @override
  String get subMenuPreRegistrations => 'Pré-Inscriptions';

  @override
  String get subMenuReRegistrations => 'Re-Inscriptions';

  @override
  String get subMenuFirstRegistration => 'Première Inscription';

  @override
  String get subMenuBilling => 'Facturations';

  @override
  String get subMenuOrganization => 'Organisation';

  @override
  String get subMenuClassesList => 'Classes';

  @override
  String get subMenuAttendance => 'Présences';

  @override
  String get subMenuDisciplinesList => 'Disciplines';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get home => 'Accueil';

  @override
  String get pageUnderConstruction => 'Cette page est en cours de développement';

  @override
  String get preRegistrations => 'Pré-Inscriptions';

  @override
  String get searchStudents => 'Rechercher des Étudiants';

  @override
  String get reRegistrationSearchHint => 'Renseignez soit Prénom, Nom et Post-nom, soit le cycle/niveau souhaité pour lancer la recherche.';

  @override
  String get reRegistrationAcademicInfoHelp => 'Sélectionnez le cycle et le niveau ciblés pour filtrer les résultats.';

  @override
  String get reRegistrationSearchNoOptions => 'Aucun niveau/cycle disponible pour la recherche.';

  @override
  String get reRegistrationSearchNeedCriteria => 'Renseignez soit Prénom, Nom et Post-nom, soit Cycle/Niveau.';

  @override
  String get reRegistrationSearchReady => 'Critères valides, vous pouvez lancer la recherche.';

  @override
  String get reRegistrationSearchInvitationTitle => 'Lancez une recherche de re-inscription';

  @override
  String get reRegistrationSearchInvitationMessage => 'Remplissez le formulaire ci-dessus puis cliquez sur Rechercher pour afficher les dossiers.';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get surname => 'Post-nom';

  @override
  String get dateOfBirth => 'Date de Naissance';

  @override
  String get search => 'Rechercher';

  @override
  String get clear => 'Effacer';

  @override
  String get viewDetails => 'Voir Détails';

  @override
  String get editEnrollment => 'Modifier';

  @override
  String get exportData => 'Exporter';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get enrollmentNoResultsDescription => 'Aucun élève ne correspond à vos critères de recherche.';

  @override
  String get loadingStudents => 'Chargement des étudiants...';

  @override
  String enrollmentResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: '0 résultat',
    );
    return '$_temp0';
  }

  @override
  String enrollmentPageFooter(int pageCount, int totalCount) {
    String _temp0 = intl.Intl.pluralLogic(
      pageCount,
      locale: localeName,
      other: 'résultats',
      one: 'résultat',
    );
    return '$pageCount $_temp0 sur $totalCount';
  }

  @override
  String enrollmentPageIndicator(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get refresh => 'Actualiser';

  @override
  String get statusPending => 'En Attente';

  @override
  String get statusValidated => 'Validé';

  @override
  String get statusRejected => 'Rejeté';

  @override
  String get enrollmentCode => 'Code d\'Inscription';

  @override
  String get enrollmentDetailTitle => 'Dossier d\'inscription';

  @override
  String get enrollmentUnknownStudent => 'Élève non renseigné';

  @override
  String get gender => 'Genre';

  @override
  String get actions => 'Actions';

  @override
  String get personalInformation => 'Informations Personnelles';

  @override
  String get address => 'Adresse';

  @override
  String get previousYear => 'Année Précédente';

  @override
  String get targetYear => 'Année Cible';

  @override
  String get guardianInformation => 'Informations Tuteurs';

  @override
  String get guardianAddAction => 'Ajouter un tuteur/responsable';

  @override
  String get guardianSaveAction => 'Enregistrer';

  @override
  String get guardianRelationshipLabel => 'Relation';

  @override
  String get guardianDeleteAction => 'Supprimer ce tuteur';

  @override
  String get guardianDeleteConfirmTitle => 'Confirmer la suppression';

  @override
  String get guardianDeleteConfirmMessage => 'Voulez-vous vraiment supprimer ce tuteur ? Cette action est irréversible.';

  @override
  String get guardianDeleteConfirmAction => 'Supprimer';

  @override
  String get guardianUnlinkSuccess => 'Tuteur supprimé avec succès.';

  @override
  String guardianUnlinkError(String message) {
    return 'Erreur lors de la suppression du tuteur : $message';
  }

  @override
  String get schoolFees => 'Frais Scolaires';

  @override
  String get summary => 'Résumé';

  @override
  String get next => 'Continuer';

  @override
  String get previous => 'Précédent';

  @override
  String get nextPage => 'Page suivante';

  @override
  String get previousPage => 'Page précédente';

  @override
  String get finish => 'Terminer';

  @override
  String get personalInfoSubtitle => 'Informations personnelles modifiables';

  @override
  String get firstNameHelp => 'Le prénom officiel de l\'élève.';

  @override
  String get lastNameHelp => 'Le nom de famille de l\'élève.';

  @override
  String get surnameHelp => 'Le postnom ou autre nom usuel.';

  @override
  String get dateOfBirthHelp => 'Utiliser le sélecteur pour choisir la date de naissance.';

  @override
  String get birthPlace => 'Lieu de naissance';

  @override
  String get birthPlaceHelp => 'Ville ou localité de naissance.';

  @override
  String get nationality => 'Nationalité';

  @override
  String get nationalityHelp => 'Nationalité principale de l\'élève.';

  @override
  String get genderHelp => 'Sexe renseigné pour le dossier administratif.';

  @override
  String get selectDateOfBirthHelpText => 'Sélectionner une date de naissance';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String enterFieldHint(String label) {
    return 'Saisir $label';
  }

  @override
  String get dateHint => 'jj/mm/aaaa';

  @override
  String get genderMale => 'Masculin';

  @override
  String get genderFemale => 'Féminin';

  @override
  String get city => 'Ville';

  @override
  String get cityHelp => 'Ville de résidence de l\'élève.';

  @override
  String get district => 'District';

  @override
  String get districtHelp => 'District ou arrondissement.';

  @override
  String get municipality => 'Commune';

  @override
  String get municipalityHelp => 'Commune de résidence de l\'élève.';

  @override
  String get neighborhood => 'Quartier';

  @override
  String get neighborhoodHelp => 'Quartier ou avenue de résidence.';

  @override
  String get addressComplementary => 'Adresse complémentaire';

  @override
  String get addressComplementaryHelp => 'Précisez rue, avenue et numéro si nécessaire.';

  @override
  String get addressComplementaryPlaceholder => 'Ex: 10, Avenue La source';

  @override
  String get fullAddress => 'Adresse complète';

  @override
  String get fullAddressHelp => 'Adresse complète de résidence.';

  @override
  String get academicYearLabel => 'Année scolaire';

  @override
  String get academicYearLabelHelp => 'Année scolaire de référence.';

  @override
  String get schoolLabel => 'École';

  @override
  String get schoolLabelHelp => 'Nom de l\'école précédente.';

  @override
  String get schoolCycle => 'Cycle';

  @override
  String get schoolCycleHelp => 'Cycle d\'enseignement précédent.';

  @override
  String get schoolLevelLabel => 'Niveau';

  @override
  String get schoolLevelLabelHelp => 'Niveau d\'étude précédent.';

  @override
  String get averageLabel => 'Moyenne';

  @override
  String get averageLabelHelp => 'Moyenne annuelle obtenue.';

  @override
  String get rankingLabel => 'Classement';

  @override
  String get rankingLabelHelp => 'Classement dans la classe.';

  @override
  String get yearValidated => 'Année validée';

  @override
  String get yearNotValidated => 'Non validée';

  @override
  String get currentAcademicYearLabel => 'Année académique';

  @override
  String get currentAcademicYearHelp => 'Année académique cible.';

  @override
  String get targetCycleLabel => 'Cycle souhaité';

  @override
  String get targetCycleLabelHelp => 'Cycle souhaité pour l\'inscription.';

  @override
  String get targetLevelLabel => 'Niveau souhaité';

  @override
  String get targetLevelLabelHelp => 'Niveau souhaité pour l\'inscription.';

  @override
  String get optionLabel => 'Option';

  @override
  String get optionLabelHelp => 'Option ou spécialisation souhaitée.';

  @override
  String get toDefine => 'À définir';

  @override
  String get primaryGuardian => 'Tuteur Principal';

  @override
  String guardianNumber(int number) {
    return 'Tuteur $number';
  }

  @override
  String get noGuardianInfo => 'Aucune information de tuteur disponible';

  @override
  String get identificationNumberLabel => 'Numéro d\'identification';

  @override
  String get identificationNumberHelp => 'Numéro d\'identification officiel.';

  @override
  String get phoneNumberLabel => 'Téléphone';

  @override
  String get phoneNumberHelp => 'Numéro de téléphone du tuteur.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailLabelHelp => 'Adresse email du tuteur.';

  @override
  String get relationshipFather => 'Père';

  @override
  String get relationshipMother => 'Mère';

  @override
  String get relationshipGuardian => 'Tuteur';

  @override
  String get relationshipUncle => 'Oncle';

  @override
  String get relationshipAunt => 'Tante';

  @override
  String get relationshipGrandparent => 'Grand-parent';

  @override
  String get relationshipOther => 'Autre';

  @override
  String get stepPersonalInfoSubtitle => 'Informations générales de l\'élève';

  @override
  String get stepAddressSubtitle => 'Localisation et adresse complète';

  @override
  String get stepAcademicSubtitle => 'Historique académique et objectifs';

  @override
  String get stepAcademicPreviousSubtitle => 'Historique académique de l\'année précédente';

  @override
  String get stepAcademicTargetSubtitle => 'Objectifs académiques pour l\'année cible';

  @override
  String get stepGuardianSubtitle => 'Responsables légaux et contacts';

  @override
  String get stepSummarySubtitle => 'Récapitulatif final du dossier';

  @override
  String stepIndicator(int current, int total) {
    return 'Étape $current / $total';
  }

  @override
  String get stepForwardHint => 'Cliquez sur Continuer pour avancer étape par étape.';

  @override
  String get validatePersonalInfoHint => 'Veuillez compléter les informations personnelles.';

  @override
  String get validateAddressHint => 'Veuillez compléter l\'adresse de l\'élève.';

  @override
  String get validateAcademicInfoHint => 'Veuillez compléter les informations académiques.';

  @override
  String get validateGuardianInfoHint => 'Veuillez vérifier les informations du/des tuteur(s).';

  @override
  String get enrollmentReadyForValidation => 'Dossier prt pour validation finale.';

  @override
  String get completedEnrollmentRedirecting => 'Ce dossier est deja complete. Redirection vers Premiere Inscription.';

  @override
  String get validateEnrollment => 'Valider l\'inscription';

  @override
  String get validatingEnrollment => 'Validation en cours...';

  @override
  String get goToFirstRegistration => 'Retourner a la premiere inscription';

  @override
  String get enrollmentStatusUpdateSuccess => 'Statut mis à jour avec succès.';

  @override
  String enrollmentStatusUpdateError(String message) {
    return 'Erreur lors de la mise à jour du statut : $message';
  }

  @override
  String get personalInfoSaveHintBeforeContinue => 'Veuillez enregistrer vos modifications avant de continuer.';

  @override
  String get personalInfoValidationReasonsTitle => 'Veuillez corriger les champs suivants :';

  @override
  String requiredFieldError(String field) {
    return 'Le champ $field est requis.';
  }

  @override
  String invalidNumberFieldError(String field) {
    return 'Le champ $field doit contenir un nombre valide.';
  }

  @override
  String get savePersonalInfo => 'Enregistrer';

  @override
  String get savingPersonalInfo => 'Enregistrement en cours...';

  @override
  String get personalInfoSaveSuccess => 'Informations personnelles mises à jour avec succès.';

  @override
  String personalInfoSaveError(String message) {
    return 'Erreur lors de la mise à jour : $message';
  }

  @override
  String get saveAddress => 'Enregistrer l\'adresse';

  @override
  String get savingAddress => 'Enregistrement de l\'adresse...';

  @override
  String get saveAcademicInfo => 'Enregistrer les infos acadmiques';

  @override
  String get savingAcademicInfo => 'Enregistrement en cours...';

  @override
  String get saveGuardianInfo => 'Enregistrer le tuteur';

  @override
  String get savingGuardianInfo => 'Enregistrement du tuteur...';

  @override
  String get academicInfoValidationReasonsTitle => 'Veuillez corriger les champs académiques suivants :';

  @override
  String get academicInfoSaveHintBeforeContinue => 'Veuillez enregistrer les modifications académiques avant de continuer.';

  @override
  String get academicInfoSaveSuccess => 'Informations académiques mises à jour avec succès.';

  @override
  String academicInfoSaveError(String message) {
    return 'Erreur lors de la mise à jour des infos académiques : $message';
  }

  @override
  String get addressValidationReasonsTitle => 'Veuillez corriger les informations d\'adresse suivantes :';

  @override
  String get addressNoCityAvailable => 'Aucune ville disponible dans le catalogue.';

  @override
  String get addressSelectCityFirst => 'Sélectionnez d\'abord une ville.';

  @override
  String get addressNoDistrictAvailable => 'Aucun district disponible pour cette ville.';

  @override
  String get addressSelectDistrictFirst => 'Sélectionnez d\'abord un district.';

  @override
  String get addressNoMunicipalityAvailable => 'Aucune commune disponible pour ce district.';

  @override
  String get addressSelectMunicipalityFirst => 'Sélectionnez d\'abord une commune.';

  @override
  String get addressNoNeighborhoodAvailable => 'Aucun quartier disponible pour cette commune.';

  @override
  String get addressSaveHintBeforeContinue => 'Veuillez enregistrer les modifications d\'adresse avant de continuer.';

  @override
  String get addressSaveSuccess => 'Adresse mise à jour avec succès.';

  @override
  String addressSaveError(String message) {
    return 'Erreur lors de la mise à jour de l\'adresse : $message';
  }

  @override
  String get enrollmentStatusFilterLabel => 'Statut';

  @override
  String get enrollmentStatusInProgress => 'En cours';

  @override
  String get enrollmentStatusAdminCompleted => 'Complété (Administratif)';

  @override
  String get enrollmentStatusFinancialCompleted => 'Complété (Financier)';

  @override
  String get enrollmentStatusCompleted => 'Complété';

  @override
  String get enrollmentStatusValidated => 'Validé';

  @override
  String get enrollmentStatusRejected => 'Rejeté';

  @override
  String get enrollmentStatusCancelled => 'Annulé';

  @override
  String get enrollmentReadOnlyTitle => 'Mode consultation';

  @override
  String get enrollmentReadOnlyMessage => 'Ce dossier est finalisé (COMPLETED). Les informations sont affichées en lecture seule.';

  @override
  String get enrollmentEditableTitle => 'Mode édition';

  @override
  String get enrollmentEditableMessage => 'Ce dossier est en cours (IN_PROGRESS). Les informations peuvent être modifiées.';

  @override
  String get studentChargesStepTitle => 'Charges de l\'élève';

  @override
  String get studentChargesStepSubtitle => 'Montants financiers appliqués à l\'élève';

  @override
  String get studentChargesLoading => 'Chargement des charges de l\'élève...';

  @override
  String get studentChargesRetry => 'Réessayer';

  @override
  String get studentChargesEmpty => 'Aucune charge disponible pour cet élève.';

  @override
  String get studentChargesUnavailable => 'Impossible de charger les charges sans élève ou niveau cible.';

  @override
  String get studentChargesAmountColumn => 'Montant';

  @override
  String get studentChargesAmountPaidLabel => 'Montant payé';

  @override
  String get studentChargesSaveAction => 'Enregistrer les charges';

  @override
  String get studentChargesSavingAction => 'Enregistrement des charges...';

  @override
  String get studentChargesSaveSuccess => 'Charges enregistrées avec succès.';

  @override
  String get studentChargesSaveHintBeforeContinue => 'Veuillez enregistrer les modifications des charges avant de continuer.';

  @override
  String get studentChargesNetworkError => 'Impossible de charger les charges. Vérifiez votre connexion internet.';

  @override
  String get studentChargesNotFound => 'Aucune charge trouvée pour cet élève.';

  @override
  String get studentChargesValidationError => 'Les informations de charges demandées sont invalides.';

  @override
  String get studentChargesUnauthorizedError => 'Vous n\'êtes pas autorisé à consulter ces charges.';

  @override
  String get studentChargesInvalidCredentialsError => 'Vos identifiants ne permettent pas d\'accéder aux charges.';

  @override
  String get studentChargesServerError => 'Le serveur est indisponible pour le moment.';

  @override
  String get studentChargesStorageError => 'Une erreur locale empêche l\'affichage des charges.';

  @override
  String get studentChargesAuthError => 'Une erreur d\'authentification empêche le chargement des charges.';

  @override
  String get studentChargesUnknownError => 'Une erreur inattendue est survenue lors du chargement des charges.';

  @override
  String get studentChargeStatusDue => 'Dû';

  @override
  String get studentChargeStatusPartial => 'Partiel';

  @override
  String get studentChargeStatusPaid => 'Payé';

  @override
  String get facturationPageHeaderTitle => 'Facturation des élèves';

  @override
  String get facturationPageHeaderSubtitle => 'Recherchez un élève par nom ou par niveau de classe pour consulter ses charges de scolarité.';

  @override
  String get facturationPageHeaderChipByName => 'Recherche par nom';

  @override
  String get facturationPageHeaderChipByLevel => 'Filtrer par niveau';

  @override
  String get facturationPageHeaderChipViewCharges => 'Voir les charges';

  @override
  String get facturationSearchTitle => 'Rechercher les élèves';

  @override
  String get facturationSearchHint => 'Renseignez le Prénom, Nom et Post-nom et/ou le Cycle/Niveau pour filtrer les résultats.';

  @override
  String get facturationSearchInvitationTitle => 'Lancez une recherche de facturation';

  @override
  String get facturationSearchInvitationMessage => 'Sélectionnez un niveau ou renseignez le nom d\'un élève puis cliquez sur Rechercher pour afficher les dossiers.';

  @override
  String get facturationViewChargesLabel => 'Voir les charges';

  @override
  String get facturationActionsColumnLabel => 'Actions';

  @override
  String get facturationNoResultsDescription => 'Aucun élève ne correspond à ces critères. Modifiez le formulaire et relancez la recherche.';

  @override
  String get facturationDetailBackLabel => 'Retour aux facturations';

  @override
  String get facturationDetailContextErrorTitle => 'Contexte de détail indisponible';

  @override
  String get facturationDetailContextErrorMessage => 'Les informations nécessaires pour afficher ce détail ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get facturationDetailUnknownValue => '-';

  @override
  String get facturationDetailStudentSectionTitle => 'Informations de l\'élève';

  @override
  String get facturationDetailStudentLastName => 'Nom';

  @override
  String get facturationDetailStudentFirstName => 'Prénom';

  @override
  String get facturationDetailStudentSurname => 'Post-nom';

  @override
  String get facturationDetailStudentLevelGroup => 'Cycle';

  @override
  String get facturationDetailStudentLevel => 'Niveau';

  @override
  String get facturationDetailInfoTitle => 'Détail de facturation';

  @override
  String get facturationDetailInfoSubtitle => 'Consultez les paiements récents et l\'état des charges de l\'élève pour l\'année scolaire sélectionnée.';

  @override
  String get facturationDetailInfoChipPayments => 'Paiements';

  @override
  String get facturationDetailInfoChipCharges => 'Charges';

  @override
  String get facturationDetailPaymentsSectionTitle => 'Derniers paiements';

  @override
  String get facturationDetailPaymentsSectionSubtitle => 'Historique des paiements enregistrés pour cet élève.';

  @override
  String get facturationDetailCollectPaymentAction => 'Encaisser un paiement';

  @override
  String get facturationDetailPaymentsRetry => 'Réessayer';

  @override
  String get facturationDetailPaymentsEmpty => 'Aucun paiement n\'a été enregistré pour cet élève.';

  @override
  String get facturationDetailPaymentPayerColumn => 'Infos du payeur';

  @override
  String get facturationDetailPaymentPaidAtColumn => 'Date de paiement';

  @override
  String get facturationDetailPaymentAmountColumn => 'Montant';

  @override
  String get facturationDetailPaymentActionsColumn => 'Actions';

  @override
  String get facturationDetailViewPaymentLabel => 'Voir le détail du paiement';

  @override
  String get facturationPaymentDetailHeroTitle => 'Détail du paiement';

  @override
  String get facturationPaymentDetailHeroSubtitle => 'Consultez les informations de ce paiement et la répartition des montants alloués.';

  @override
  String get facturationPaymentInfoSectionTitle => 'Informations du paiement';

  @override
  String get facturationPaymentPayerLabel => 'Payeur';

  @override
  String get facturationPaymentAmountLabel => 'Montant global payé';

  @override
  String get facturationPaymentPaidAtLabel => 'Date de paiement';

  @override
  String get facturationPaymentAllocationsSectionTitle => 'Allocations de paiement';

  @override
  String get facturationPaymentAllocationsSectionSubtitle => 'Liste des charges couvertes par ce paiement.';

  @override
  String get facturationPaymentAllocationsTotalLabel => 'Total alloué';

  @override
  String get facturationPaymentAllocationsEmpty => 'Aucune allocation n\'a été trouvée pour ce paiement.';

  @override
  String get facturationPaymentAllocationsConsistencyOk => 'La somme des allocations est cohérente avec le montant global payé.';

  @override
  String get facturationPaymentAllocationsConsistencyWarning => 'Incohérence détectée : la somme des allocations ne correspond pas au montant global payé.';

  @override
  String get facturationPaymentAllocationsNetworkError => 'Impossible de charger les allocations du paiement. Vérifiez votre connexion internet.';

  @override
  String get facturationPaymentAllocationsNotFound => 'Aucune allocation trouvée pour ce paiement.';

  @override
  String get facturationPaymentAllocationsValidationError => 'Les informations demandées pour les allocations sont invalides.';

  @override
  String get facturationPaymentAllocationsUnauthorizedError => 'Vous n\'êtes pas autorisé à consulter les allocations de ce paiement.';

  @override
  String get facturationPaymentAllocationsInvalidCredentialsError => 'Vos identifiants ne permettent pas d\'accéder aux allocations de ce paiement.';

  @override
  String get facturationPaymentAllocationsServerError => 'Le serveur est indisponible pour le moment.';

  @override
  String get facturationPaymentAllocationsStorageError => 'Une erreur locale empêche l\'affichage des allocations.';

  @override
  String get facturationPaymentAllocationsAuthError => 'Une erreur d\'authentification empêche le chargement des allocations.';

  @override
  String get facturationPaymentAllocationsUnknownError => 'Une erreur inattendue est survenue lors du chargement des allocations.';

  @override
  String get facturationDetailChargesSectionTitle => 'Charges de l\'élève';

  @override
  String get facturationDetailChargesSectionSubtitle => 'Répartition des montants attendus, payés et restants.';

  @override
  String get facturationDetailChargesRetry => 'Réessayer';

  @override
  String get facturationDetailChargesEmpty => 'Aucune charge n\'a été trouvée pour cet élève.';

  @override
  String get facturationDetailChargeLabelColumn => 'Libellé';

  @override
  String get facturationDetailChargeExpectedAmountColumn => 'Montant attendu';

  @override
  String get facturationDetailChargePaidAmountColumn => 'Montant payé';

  @override
  String get facturationDetailChargeRemainingAmountColumn => 'Reste à payer';

  @override
  String get facturationDetailChargeStatusColumn => 'Statut';

  @override
  String get facturationPaymentsNetworkError => 'Impossible de charger les paiements. Vérifiez votre connexion internet.';

  @override
  String get facturationPaymentsNotFound => 'Aucun paiement trouvé pour cet élève.';

  @override
  String get facturationPaymentsValidationError => 'Les informations demandées pour les paiements sont invalides.';

  @override
  String get facturationPaymentsUnauthorizedError => 'Vous n\'êtes pas autorisé à consulter ces paiements.';

  @override
  String get facturationPaymentsInvalidCredentialsError => 'Vos identifiants ne permettent pas d\'accéder aux paiements.';

  @override
  String get facturationPaymentsServerError => 'Le serveur est indisponible pour le moment.';

  @override
  String get facturationPaymentsStorageError => 'Une erreur locale empêche l\'affichage des paiements.';

  @override
  String get facturationPaymentsAuthError => 'Une erreur d\'authentification empêche le chargement des paiements.';

  @override
  String get facturationPaymentsUnknownError => 'Une erreur inattendue est survenue lors du chargement des paiements.';

  @override
  String get facturationPrintReceiptLabel => 'Imprimer le reu';

  @override
  String get facturationPrintReceiptSubtitle => 'Gnrez et tlchargez le reu de ce paiement';

  @override
  String get facturationPrintStatementsLabel => 'Imprimer les relevs';

  @override
  String get facturationPrintStatementsSubtitle => 'Gnrez et tlchargez les relevs de facturation de cet tudiant';

  @override
  String get facturationChargeDetailBackLabel => 'Retour au détail de facturation';

  @override
  String get facturationChargeDetailHeroTitle => 'Détail d\'une charge';

  @override
  String get facturationChargeDetailHeroSubtitle => 'Consultez l\'état de cette charge et les paiements qui y ont été alloués.';

  @override
  String get facturationChargeDetailInfoSectionTitle => 'Informations de la charge';

  @override
  String get facturationChargeDetailExpectedAmountLabel => 'Montant attendu';

  @override
  String get facturationChargeDetailPaidAmountLabel => 'Montant payé';

  @override
  String get facturationChargeDetailRemainingAmountLabel => 'Reste à payer';

  @override
  String get facturationChargeDetailStatusLabel => 'Statut';

  @override
  String get facturationChargeDetailAllocationsSectionTitle => 'Allocations liées à cette charge';

  @override
  String get facturationChargeDetailAllocationsSectionSubtitle => 'Détail des paiements alloués à cette charge.';

  @override
  String get facturationChargeDetailAllocationsTotalLabel => 'Total alloué';

  @override
  String get facturationChargeDetailAllocationsEmpty => 'Aucune allocation n\'a été trouvée pour cette charge.';

  @override
  String get facturationChargeDetailAllocationsRetry => 'Réessayer';

  @override
  String get facturationChargeDetailAllocationsNetworkError => 'Impossible de charger les allocations. Vérifiez votre connexion internet.';

  @override
  String get facturationChargeDetailAllocationsNotFound => 'Aucune allocation trouvée pour cette charge.';

  @override
  String get facturationChargeDetailAllocationsValidationError => 'Les informations demandées pour les allocations sont invalides.';

  @override
  String get facturationChargeDetailAllocationsUnauthorizedError => 'Vous n\'êtes pas autorisé à consulter les allocations de cette charge.';

  @override
  String get facturationChargeDetailAllocationsInvalidCredentialsError => 'Vos identifiants ne permettent pas d\'accéder aux allocations de cette charge.';

  @override
  String get facturationChargeDetailAllocationsServerError => 'Le serveur est indisponible pour le moment.';

  @override
  String get facturationChargeDetailAllocationsStorageError => 'Une erreur locale empêche l\'affichage des allocations.';

  @override
  String get facturationChargeDetailAllocationsAuthError => 'Une erreur d\'authentification empêche le chargement des allocations.';

  @override
  String get facturationChargeDetailAllocationsUnknownError => 'Une erreur inattendue est survenue lors du chargement des allocations.';

  @override
  String get facturationChargeDetailContextErrorTitle => 'Contexte de détail de charge indisponible';

  @override
  String get facturationChargeDetailContextErrorMessage => 'Les informations nécessaires pour afficher cette charge ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get bootstrapContextUnavailableTitle => 'Contexte d\'inscription indisponible';

  @override
  String get bootstrapContextUnavailableMessage => 'Les données bootstrap (année scolaire / école) sont absentes. Veuillez vous déconnecter puis vous reconnecter pour recharger la configuration.';

  @override
  String get signOutAction => 'Se déconnecter';
}
