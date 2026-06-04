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
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre email';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un email valide';

  @override
  String get schoolApp => 'ETEELO CONNECT';

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
  String get enterEmailToReceiveOtp =>
      'Saisissez votre email pour recevoir un code de vérification.';

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
  String get subMenuDashboard => 'Tableau de bord';

  @override
  String get subMenuPreRegistrations => 'Pré-inscriptions';

  @override
  String get subMenuReRegistrations => 'Réinscriptions';

  @override
  String get subMenuFirstRegistration => 'Première inscription';

  @override
  String get subMenuBilling => 'Facturations';

  @override
  String get subMenuOrganization => 'Composition\ndes classes';

  @override
  String get classesOrganisationHeroTitle => 'Composition des classes';

  @override
  String get classesOrganisationHeroSubtitle =>
      'Repartissez les élèves d\'un niveau en sous-classes (ex. 1ere année A, 1ere année B, 1ere année C) et visualisez la liste des élèves par sous-classe.';

  @override
  String get classesOrganisationSearchTitle =>
      'Sélection du niveau à organiser';

  @override
  String get classesOrganisationSearchHint =>
      'Sélectionnez le cycle et le niveau à organiser, puis lancez la recherche pour afficher la répartition actuelle ou préparer la distribution en sous-classes.';

  @override
  String get classesOrganisationClassroomFieldLabel => 'Sous-classe';

  @override
  String get classesOrganisationDistributionLabel => 'Critère de répartition';

  @override
  String get classesOrganisationDistributionByGender => 'Répartition par genre';

  @override
  String get classesOrganisationDistributionByPercentage =>
      'Répartition par moyenne';

  @override
  String get classesOrganisationDistributionAction => 'Répartir';

  @override
  String get classesOrganisationDistributionConfirmTitle =>
      'Confirmer la répartition';

  @override
  String get classesOrganisationDistributionConfirmMessage =>
      'Voulez-vous lancer la répartition des élèves pour ce niveau ?';

  @override
  String get classesOrganisationDistributionSuccess =>
      'Répartition terminée avec succès.';

  @override
  String get classesOrganisationSplitInfo =>
      'Mode sous-classes actif : affichage par sous-classe avec effectifs et statistiques.';

  @override
  String get classesOrganisationNonSplitInfo =>
      'Mode classe unique actif : liste des élèves du niveau sélectionné.';

  @override
  String get classesOrganisationNoClassrooms =>
      'Aucune sous-classe disponible pour ce niveau.';

  @override
  String classesOrganisationClassroomStats(int total, int girls, int boys) {
    return '$total élèves - Filles: $girls - Garçons: $boys';
  }

  @override
  String get classesOrganisationTransferDialogTitle => 'Transférer l\'élève';

  @override
  String classesOrganisationTransferDialogMessage(String studentName) {
    return 'Choisissez la sous-classe de destination pour $studentName.';
  }

  @override
  String get classesOrganisationTransferTargetLabel =>
      'Sous-classe de destination';

  @override
  String get classesOrganisationTransferAction => 'Transférer';

  @override
  String get classesOrganisationTransferInProgress => 'Transfert en cours...';

  @override
  String get classesOrganisationTransferSuccess =>
      'Transfert effectué avec succès.';

  @override
  String get classesOrganisationTransferNoTarget =>
      'Aucune sous-classe de destination disponible.';

  @override
  String get classesOrganisationSelectCycleAndLevelTitle =>
      'Sélectionnez un cycle et un niveau';

  @override
  String get classesOrganisationSelectCycleAndLevelSubtitle =>
      'Commencez par choisir un cycle, puis un niveau pour afficher la composition des classes.';

  @override
  String get classesOrganisationSelectLevelTitle => 'Sélectionnez un niveau';

  @override
  String classesOrganisationSelectLevelSubtitle(String cycleName) {
    return 'Choisissez maintenant un niveau dans le cycle $cycleName.';
  }

  @override
  String get classesOrganisationPendingTitle => 'Niveau non encore réparti';

  @override
  String get classesOrganisationPendingSubtitle =>
      'Lancez la répartition initiale pour constituer les classes de ce niveau.';

  @override
  String classesOrganisationPendingStudentsToDistribute(int count) {
    return '$count élèves à répartir';
  }

  @override
  String classesOrganisationPendingPlannedClassrooms(int count) {
    return '$count classes prévues';
  }

  @override
  String get classesOrganisationAppliedCriterionInfo =>
      'Critère appliqué : répartition équilibrée par genre (école mixte).';

  @override
  String classesOrganisationSplitSummary(
    int studentsCount,
    int classroomsCount,
    String criterion,
  ) {
    return '$studentsCount élèves répartis en $classroomsCount classes · Critère appliqué : $criterion';
  }

  @override
  String get classesOrganisationClassroomsSectionTitle => 'Classes constituées';

  @override
  String get classesOrganisationUnassignedTitle => 'Élèves à affecter';

  @override
  String get classesOrganisationUnassignedTitleSuffix =>
      ' — arrivés après la répartition';

  @override
  String get classesOrganisationUnassignedBadge => 'À affecter';

  @override
  String classesOrganisationUnassignedSummary(int count) {
    return '$count élèves en attente d\'affectation';
  }

  @override
  String get classesOrganisationNoMembers => 'Aucun élève dans cette classe.';

  @override
  String get classesOrganisationAssignAction => 'Affecter à une classe';

  @override
  String get classesOrganisationAssignDialogTitle => 'Affecter à une classe';

  @override
  String classesOrganisationAssignDialogMessage(String studentName) {
    return 'Choisissez la classe de destination pour $studentName.';
  }

  @override
  String classesOrganisationClassroomPopulation(int count) {
    return 'Effectif actuel : $count';
  }

  @override
  String classesOrganisationTransferConfirmMessage(String studentName) {
    return 'Confirmez-vous le transfert de $studentName vers cette classe ?';
  }

  @override
  String classesOrganisationLoadingClassroomsCount(int count) {
    return 'Chargement des membres de $count sous-classes...';
  }

  @override
  String get classesOrganisationStudentDetailSoon =>
      'Le détail élève sera disponible au prochain lot.';

  @override
  String get classesOrganisationErrorNetwork =>
      'Vérifiez votre connexion internet.';

  @override
  String get classesOrganisationErrorNotFound =>
      'Aucune donnée trouvée pour ces critères.';

  @override
  String get classesOrganisationErrorValidation =>
      'Certaines informations saisies sont invalides.';

  @override
  String get classesOrganisationErrorUnauthorized => 'Accès non autorisé.';

  @override
  String get classesOrganisationErrorInvalidCredentials =>
      'Identifiants invalides.';

  @override
  String get classesOrganisationErrorServer =>
      'Erreur serveur, réessayez plus tard.';

  @override
  String get classesOrganisationErrorStorage => 'Erreur de stockage local.';

  @override
  String get classesOrganisationErrorAuth =>
      'Session non valide, reconnectez-vous.';

  @override
  String get classesOrganisationErrorUnknown => 'Une erreur est survenue.';

  @override
  String get classesListHeroTitle => 'Listes de classe';

  @override
  String get classesListHeroSubtitle =>
      'Recherchez rapidement les élèves par cycle, niveau ou classe, puis exportez les résultats affichés.';

  @override
  String get classesListHeroFilterChip =>
      'Recherche multi-critères par identité et niveau.';

  @override
  String get classesListHeroClassroomChip =>
      'Filtrage optionnel par classe de l\'année courante.';

  @override
  String get classesListSearchTitle => 'Formulaire de recherche';

  @override
  String get classesListSearchHint => '';

  @override
  String get classesListValidationAtLeastOneCriterion =>
      'Renseignez au moins un critère pour lancer la recherche.';

  @override
  String get classesListClassroomOptionalLabel => 'Classe (optionnel)';

  @override
  String get classesListFirstNameOptionalLabel => 'Prénom (optionnel)';

  @override
  String get classesListLastNameOptionalLabel => 'Nom (optionnel)';

  @override
  String get classesListSurnameOptionalLabel => 'Post-nom (optionnel)';

  @override
  String get classesListInitialEmptyTitle => 'Aucune recherche en cours';

  @override
  String get classesListInitialEmptyMessage =>
      'Renseignez au moins un critère pour afficher les élèves.';

  @override
  String get classesListNoMatchTitle =>
      'Aucun élève ne correspond aux critères';

  @override
  String get classesListNoMatchMessage =>
      'Essayez d\'élargir vos filtres ou de modifier votre recherche.';

  @override
  String classesListResultsSummary(int count, String criteria) {
    return '$count élèves trouvés — $criteria';
  }

  @override
  String classesListResultsSummaryWithoutCriteria(int count) {
    return '$count élèves trouvés';
  }

  @override
  String get classesListClassroomChipLabel => 'Classe';

  @override
  String get classesListLoadingClassroomMembers =>
      'Chargement des membres de la classe...';

  @override
  String get classesListClassroomEmptyMessage =>
      'Aucun élève n\'est actuellement affecté à cette classe.';

  @override
  String get classesListClassroomFilteredEmptyMessage =>
      'Aucun élève de cette classe ne correspond aux filtres saisis.';

  @override
  String get classesListStudentDetailSoon =>
      'Le détail élève sera disponible dans une prochaine version.';

  @override
  String get classesListExportSuccess => 'Export copié dans le presse-papiers.';

  @override
  String get classesListExportFailed =>
      'Impossible de préparer l\'export pour le moment.';

  @override
  String get classesListExportNothingToExport =>
      'Aucune donnée à exporter pour cette recherche.';

  @override
  String get classesListExportPdf => 'Exporter en PDF';

  @override
  String get subMenuClassesList => 'Listes de classe';

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
  String get homeTopBarPendingSubtitle => 'Suivi des dossiers en attente';

  @override
  String get homeTopBarNotificationsTooltip => 'Notifications';

  @override
  String get homeUserMenuTooltip => 'Menu utilisateur';

  @override
  String get homeSidebarCollapseTooltip => 'Replier le menu';

  @override
  String get homeSidebarExpandTooltip => 'Étendre le menu';

  @override
  String get homeSidebarFooterLabel => 'Tableau de bord scolaire';

  @override
  String get homeSidebarNavigationLabel => 'Navigation principale';

  @override
  String get pageUnderConstruction =>
      'Cette page est en cours de développement';

  @override
  String get preRegistrations => 'Pré-Inscriptions';

  @override
  String get searchStudents => 'Rechercher des élèves';

  @override
  String get searchFormSubtitleFirstRegistration =>
      'Filtrez la liste des inscriptions';

  @override
  String get searchFormSubtitlePreRegistration =>
      'Demandes reçues en ligne, en attente de validation';

  @override
  String get reRegistrationSearchHint =>
      'Renseignez soit Prénom, Nom et Post-nom, soit le cycle/niveau souhaité pour lancer la recherche.';

  @override
  String get reRegistrationAcademicInfoHelp =>
      'Sélectionnez le cycle et le niveau ciblés pour filtrer les résultats.';

  @override
  String get reRegistrationSearchNoOptions =>
      'Aucun niveau/cycle disponible pour la recherche.';

  @override
  String get reRegistrationSearchNeedCriteria =>
      'Renseignez soit Prénom, Nom et Post-nom, soit Cycle/Niveau.';

  @override
  String get reRegistrationSearchReady =>
      'Critères valides, vous pouvez lancer la recherche.';

  @override
  String get reRegistrationSearchInvitationTitle =>
      'Lancez une recherche de re-inscription';

  @override
  String get reRegistrationSearchInvitationMessage =>
      'Remplissez le formulaire ci-dessus puis cliquez sur Rechercher pour afficher les dossiers.';

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
  String get viewDetails => 'Voir les détails';

  @override
  String get editEnrollment => 'Modifier';

  @override
  String get exportData => 'Exporter';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get enrollmentNoResultsDescription =>
      'Aucun élève ne correspond à vos critères de recherche.';

  @override
  String get enrollmentEmptyTitle => 'Aucun résultat';

  @override
  String get enrollmentEmptyDescription =>
      'Aucune inscription ne correspond à vos critères. Essayez d\'élargir la recherche ou créez une nouvelle inscription.';

  @override
  String get enrollmentEmptyWithoutFilterDescription =>
      'Aucune inscription pour le moment.';

  @override
  String get enrollmentEmptyCreateAction => 'Inscrire un nouvel élève';

  @override
  String get enrollmentErrorRetry => 'Réessayer';

  @override
  String get enrollmentErrorReconnect => 'Se reconnecter';

  @override
  String get enrollmentErrorContactAdmin => 'Contacter l\'administrateur';

  @override
  String get enrollmentErrorNetworkTitle => 'Connexion indisponible';

  @override
  String get enrollmentErrorNetworkMessage =>
      'Vérifiez votre connexion internet puis relancez la recherche.';

  @override
  String get enrollmentErrorUnauthorizedTitle => 'Session expirée';

  @override
  String get enrollmentErrorUnauthorizedMessage =>
      'Votre session a expiré. Reconnectez-vous pour continuer.';

  @override
  String get enrollmentErrorForbiddenTitle => 'Accès refusé';

  @override
  String get enrollmentErrorForbiddenMessage =>
      'Vous n\'avez pas les droits requis pour voir cette liste.';

  @override
  String get enrollmentErrorServerTitle => 'Erreur serveur';

  @override
  String get enrollmentErrorServerMessage =>
      'Le serveur est temporairement indisponible. Réessayez dans quelques instants.';

  @override
  String get enrollmentErrorUnknownTitle => 'Chargement impossible';

  @override
  String get enrollmentErrorUnknownMessage =>
      'Une erreur inattendue est survenue lors du chargement des résultats.';

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
  String get firstRegistrationNewEnrollmentAction => 'Nouvelle inscription';

  @override
  String get enrollmentDetailLoadingTitle => 'Chargement du dossier';

  @override
  String get enrollmentDetailLoadingMessage =>
      'Veuillez patienter pendant la récupération des informations.';

  @override
  String get enrollmentDetailLoadErrorTitle =>
      'Impossible de charger le dossier';

  @override
  String get enrollmentDetailLoadErrorFallback =>
      'Erreur lors du chargement des détails.';

  @override
  String get enrollmentDetailRetryAction => 'Réessayer';

  @override
  String get enrollmentDetailNotFoundTitle => 'Détails introuvables';

  @override
  String get enrollmentDetailNotFoundMessage =>
      'Ce dossier n\'existe pas ou n\'est plus disponible.';

  @override
  String get gender => 'Genre';

  @override
  String get actions => 'Actions';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get address => 'Adresse';

  @override
  String get previousYear => 'Année Précédente';

  @override
  String get targetYear => 'Année Cible';

  @override
  String get guardianInformation => 'Informations des tuteurs';

  @override
  String get guardianAddAction => 'Ajouter un tuteur/responsable';

  @override
  String get guardianSaveAction => 'Enregistrer';

  @override
  String get guardianRelationshipLabel => 'Relation';

  @override
  String get guardianMarkAsPrimary => 'Désigner comme tuteur principal';

  @override
  String get guardianPrimaryRequiredHint =>
      'Au moins un tuteur principal est requis';

  @override
  String get guardianPrincipalBadge => 'Principal';

  @override
  String get guardianToggleCard => 'Ouvrir ou fermer la carte tuteur';

  @override
  String get guardianEmailOptionalInline => '(facultatif)';

  @override
  String get guardianDeleteAction => 'Supprimer ce tuteur';

  @override
  String get guardianDeleteConfirmTitle => 'Confirmer la suppression';

  @override
  String get guardianDeleteConfirmMessage =>
      'Voulez-vous vraiment supprimer ce tuteur ? Cette action est irréversible.';

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
  String get summaryYes => 'Oui';

  @override
  String get summaryNo => 'Non';

  @override
  String get summaryChargesTotalDue => 'Total à régler';

  @override
  String get summaryChargesUnavailable =>
      'Montants indisponibles pour le moment.';

  @override
  String get summaryValidationNoticeTitle => 'Avant validation';

  @override
  String get summaryValidationNoticeBody =>
      'Vous certifiez que les informations sont exactes. Le dossier passera au statut validé et un reçu pourra être généré.';

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
  String get dateOfBirthHelp =>
      'Utiliser le sélecteur pour choisir la date de naissance.';

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
  String get firstNameExample => 'Claudine';

  @override
  String get lastNameExample => 'Furah';

  @override
  String get surnameExample => 'Sifiwe';

  @override
  String get selectPlaceholderChoose => 'Choisir';

  @override
  String get requiredSemanticSuffix => 'obligatoire';

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
  String get addressComplementaryHelp =>
      'Précisez rue, avenue et numéro si nécessaire.';

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
  String get yearValidatedHelp =>
      'Indique si l\'élève a validé son année scolaire précédente.';

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
  String get stepAcademicPreviousSubtitle =>
      'Historique académique de l\'année précédente';

  @override
  String get stepAcademicTargetSubtitle =>
      'Objectifs académiques pour l\'année cible';

  @override
  String get stepGuardianSubtitle => 'Responsables légaux et contacts';

  @override
  String get stepSummarySubtitle => 'Récapitulatif final du dossier';

  @override
  String get wizardStepShortPersonal => 'Perso';

  @override
  String get wizardStepShortAddress => 'Adresse';

  @override
  String get wizardStepShortPrevious => 'Précédent';

  @override
  String get wizardStepShortTarget => 'Cible';

  @override
  String get wizardStepShortCharges => 'Charges';

  @override
  String get wizardStepShortGuardian => 'Tuteurs';

  @override
  String get wizardStepShortSummary => 'Résumé';

  @override
  String stepIndicator(int current, int total) {
    return 'Étape $current / $total';
  }

  @override
  String get stepForwardHint =>
      'Cliquez sur Continuer pour avancer étape par étape.';

  @override
  String get journeyModeNew => 'Nouvelle';

  @override
  String get journeyModeEdit => 'Modification';

  @override
  String get journeyModeView => 'Consultation';

  @override
  String get journeyCloseAction => 'Fermer';

  @override
  String get stepSaveStateIdle => 'Aucune saisie';

  @override
  String get stepSaveStatePending => 'Modifications non enregistrées';

  @override
  String get stepSaveStateSaving => 'Enregistrement en cours...';

  @override
  String get stepSaveStateSaved => 'Étape enregistrée';

  @override
  String get validatePersonalInfoHint =>
      'Veuillez compléter les informations personnelles.';

  @override
  String get validateAddressHint =>
      'Veuillez compléter l\'adresse de l\'élève.';

  @override
  String get validateAcademicInfoHint =>
      'Veuillez compléter les informations académiques.';

  @override
  String get validateGuardianInfoHint =>
      'Veuillez vérifier les informations du/des tuteur(s).';

  @override
  String get enrollmentReadyForValidation =>
      'Dossier prêt pour validation finale.';

  @override
  String get completedEnrollmentRedirecting =>
      'Ce dossier est déjà complété. Redirection vers Première Inscription.';

  @override
  String get validateEnrollment => 'Valider l\'inscription';

  @override
  String get validatingEnrollment => 'Validation en cours...';

  @override
  String get goToFirstRegistration => 'Retourner à la première inscription';

  @override
  String get enrollmentStatusUpdateSuccess => 'Statut mis à jour avec succès.';

  @override
  String enrollmentStatusUpdateError(String message) {
    return 'Erreur lors de la mise à jour du statut : $message';
  }

  @override
  String get personalInfoSaveHintBeforeContinue =>
      'Veuillez enregistrer vos modifications avant de continuer.';

  @override
  String get personalInfoValidationReasonsTitle =>
      'Veuillez corriger les champs suivants :';

  @override
  String requiredFieldError(String field) {
    return 'Le champ $field est requis.';
  }

  @override
  String invalidNumberFieldError(String field) {
    return 'Le champ $field doit contenir un nombre valide.';
  }

  @override
  String get savePersonalInfo => 'Enregistrer les informations personnelles';

  @override
  String get savingPersonalInfo => 'Enregistrement en cours...';

  @override
  String get personalInfoSaveSuccess =>
      'Informations personnelles mises à jour avec succès.';

  @override
  String personalInfoSaveError(String message) {
    return 'Erreur lors de la mise à jour : $message';
  }

  @override
  String get saveAddress => 'Enregistrer l\'adresse';

  @override
  String get savingAddress => 'Enregistrement de l\'adresse...';

  @override
  String get saveAcademicInfo => 'Enregistrer les informations académiques';

  @override
  String get savingAcademicInfo => 'Enregistrement en cours...';

  @override
  String get saveGuardianInfo => 'Enregistrer le tuteur';

  @override
  String get savingGuardianInfo => 'Enregistrement du tuteur...';

  @override
  String get academicInfoValidationReasonsTitle =>
      'Veuillez corriger les champs académiques suivants :';

  @override
  String get academicInfoSaveHintBeforeContinue =>
      'Veuillez enregistrer les modifications académiques avant de continuer.';

  @override
  String get academicInfoSaveSuccess =>
      'Informations académiques mises à jour avec succès.';

  @override
  String academicInfoSaveError(String message) {
    return 'Erreur lors de la mise à jour des informations académiques : $message';
  }

  @override
  String get addressValidationReasonsTitle =>
      'Veuillez corriger les informations d\'adresse suivantes :';

  @override
  String get addressNoCityAvailable =>
      'Aucune ville disponible dans le catalogue.';

  @override
  String get addressSelectCityFirst => 'Sélectionnez d\'abord une ville.';

  @override
  String get addressNoDistrictAvailable =>
      'Aucun district disponible pour cette ville.';

  @override
  String get addressSelectDistrictFirst => 'Sélectionnez d\'abord un district.';

  @override
  String get addressNoMunicipalityAvailable =>
      'Aucune commune disponible pour ce district.';

  @override
  String get addressSelectMunicipalityFirst =>
      'Sélectionnez d\'abord une commune.';

  @override
  String get addressNoNeighborhoodAvailable =>
      'Aucun quartier disponible pour cette commune.';

  @override
  String get addressSaveHintBeforeContinue =>
      'Veuillez enregistrer les modifications d\'adresse avant de continuer.';

  @override
  String get addressSaveSuccess => 'Adresse mise à jour avec succès.';

  @override
  String addressSaveError(String message) {
    return 'Erreur lors de la mise à jour de l\'adresse : $message';
  }

  @override
  String get enrollmentStudentColumnLabel => 'Eleve';

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
  String get enrollmentReadOnlyMessage =>
      'Ce dossier est finalisé (COMPLETED). Les informations sont affichées en lecture seule.';

  @override
  String get enrollmentEditableTitle => 'Mode édition';

  @override
  String get enrollmentEditableMessage =>
      'Ce dossier est en cours (IN_PROGRESS). Les informations peuvent être modifiées.';

  @override
  String get studentChargesStepTitle => 'Charges de l\'élève';

  @override
  String get studentChargesStepSubtitle =>
      'Montants financiers appliqués à l\'élève';

  @override
  String get studentChargesLoading => 'Chargement des charges de l\'élève...';

  @override
  String get studentChargesRetry => 'Réessayer';

  @override
  String get studentChargesEmpty => 'Aucune charge disponible pour cet élève.';

  @override
  String get studentChargesUnavailable =>
      'Impossible de charger les charges sans élève ou niveau cible.';

  @override
  String get studentChargesAmountColumn => 'Montant';

  @override
  String get studentChargesLabelColumn => 'Libellé';

  @override
  String get studentChargesActionsColumn => 'Actions';

  @override
  String get studentChargesAmountPaidLabel => 'Montant payé';

  @override
  String get studentChargesSaveAction => 'Enregistrer les charges';

  @override
  String get studentChargesSavingAction => 'Enregistrement des charges...';

  @override
  String get studentChargesSaveSuccess => 'Charges enregistrées avec succès.';

  @override
  String get studentChargesSaveHintBeforeContinue =>
      'Veuillez enregistrer les modifications des charges avant de continuer.';

  @override
  String get studentChargesTotalLabel => 'Total';

  @override
  String get studentChargesHelperText =>
      'Les montants peuvent être modifiés ultérieurement depuis la fiche de l\'élève.';

  @override
  String get studentChargesNetworkError =>
      'Impossible de charger les charges. Vérifiez votre connexion internet.';

  @override
  String get studentChargesNotFound => 'Aucune charge trouvée pour cet élève.';

  @override
  String get studentChargesValidationError =>
      'Les informations de charges demandées sont invalides.';

  @override
  String get studentChargesUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces charges.';

  @override
  String get studentChargesInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux charges.';

  @override
  String get studentChargesServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get studentChargesStorageError =>
      'Une erreur locale empêche l\'affichage des charges.';

  @override
  String get studentChargesAuthError =>
      'Une erreur d\'authentification empêche le chargement des charges.';

  @override
  String get studentChargesUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des charges.';

  @override
  String get studentChargeStatusDue => 'À régler';

  @override
  String get studentChargeStatusPartial => 'Partiel';

  @override
  String get studentChargeStatusPaid => 'Payé';

  @override
  String get studentChargeFeeCodeTuition => 'Frais de scolarité';

  @override
  String get studentChargeFeeCodeRegistration => 'Frais d\'inscription';

  @override
  String get studentChargeFeeCodeEnrollment => 'Frais d\'enrôlement';

  @override
  String get studentChargeFeeCodeApplication => 'Frais de dossier';

  @override
  String get studentChargeFeeCodeAdmission => 'Frais d\'admission';

  @override
  String get studentChargeFeeCodeCanteen => 'Cantine';

  @override
  String get studentChargeFeeCodeTransport => 'Transport';

  @override
  String get studentChargeFeeCodeBoarding => 'Internat';

  @override
  String get studentChargeFeeCodeBooks => 'Livres et matériels';

  @override
  String get studentChargeFeeCodeUniform => 'Uniforme';

  @override
  String get studentChargeFeeCodeExamination => 'Frais d\'examen';

  @override
  String get studentChargeFeeCodeLabFee => 'Frais de laboratoire';

  @override
  String get studentChargeFeeCodeActivity => 'Frais d\'activités';

  @override
  String get studentChargeFeeCodeSports => 'Frais de sport';

  @override
  String get studentChargeFeeCodeLibrary => 'Frais de bibliothèque';

  @override
  String get studentChargeFeeCodeTechnology =>
      'Frais technologie / informatique';

  @override
  String get studentChargeFeeCodeDevelopment =>
      'Frais de développement / infrastructure';

  @override
  String get studentChargeFeeCodeInsurance => 'Assurance';

  @override
  String get studentChargeFeeCodeSecurityDeposit => 'Caution';

  @override
  String get studentChargeFeeCodeProcessingFee => 'Frais de traitement';

  @override
  String get studentChargeFeeCodeLatePaymentFee => 'Pénalité de retard';

  @override
  String get studentChargeFeeCodeRefund => 'Remboursement';

  @override
  String get studentChargeFeeCodeOther => 'Autre';

  @override
  String get studentChargeFeeCodeFallback => 'Frais scolaire';

  @override
  String get facturationSearchTitle => 'Rechercher les élèves';

  @override
  String get facturationSearchHint =>
      'Renseignez le Prénom, Nom et Post-nom et/ou le Cycle/Niveau pour filtrer les résultats.';

  @override
  String get facturationSearchInvitationTitle => 'Aucune recherche en cours';

  @override
  String get facturationSearchInvitationMessage =>
      'Saisissez un nom ou un niveau ci-dessus pour afficher les élèves correspondants.';

  @override
  String get facturationViewChargesLabel => 'Voir les charges';

  @override
  String get facturationActionsColumnLabel => 'Actions';

  @override
  String get facturationNoResultsDescription =>
      'Aucun élève ne correspond à ces critères. Modifiez le formulaire et relancez la recherche.';

  @override
  String get facturationDetailBackLabel => 'Retour aux facturations';

  @override
  String get facturationDetailContextErrorTitle =>
      'Contexte de détail indisponible';

  @override
  String get facturationDetailContextErrorMessage =>
      'Les informations nécessaires pour afficher ce détail ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

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
  String get facturationDetailInfoTitle => 'Fiche financière';

  @override
  String get facturationDetailInfoSubtitle =>
      'Consultez les paiements récents et l\'état des charges de l\'élève.';

  @override
  String get facturationDetailHeaderKpiTotalDue => 'Total dû';

  @override
  String get facturationDetailHeaderKpiAlreadyPaid => 'Déjà payé';

  @override
  String get facturationDetailHeaderKpiRemaining => 'Reste à payer';

  @override
  String get facturationDetailInfoChipPayments => 'Paiements';

  @override
  String get facturationDetailInfoChipCharges => 'Charges';

  @override
  String get facturationDetailPaymentsSectionTitle => 'Derniers paiements';

  @override
  String get facturationDetailPaymentsSectionSubtitle =>
      'Historique des encaissements enregistrés pour cet élève.';

  @override
  String facturationDetailPaymentsRecordedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements enregistrés',
      one: '1 paiement enregistré',
      zero: 'Aucun paiement enregistré',
    );
    return '$_temp0';
  }

  @override
  String get facturationDetailCollectPaymentAction => 'Encaisser un paiement';

  @override
  String get facturationDetailPaymentsRetry => 'Réessayer';

  @override
  String get facturationDetailPaymentsEmpty =>
      'Aucun paiement n\'a été enregistré pour cet élève.';

  @override
  String get facturationDetailPaymentPayerColumn => 'Payeur';

  @override
  String get facturationDetailPaymentPaidAtColumn => 'Date';

  @override
  String get facturationDetailPaymentAmountColumn => 'Montant';

  @override
  String get facturationDetailPaymentActionsColumn => 'Actions';

  @override
  String get facturationDetailViewPaymentLabel => 'Voir le détail du paiement';

  @override
  String get facturationDetailViewChargeLabel => 'Voir le détail de la charge';

  @override
  String get facturationPaymentDetailHeroTitle => 'Détail du paiement';

  @override
  String get facturationPaymentDetailHeroSubtitle =>
      'Consultez les informations de ce paiement et la répartition des montants alloués.';

  @override
  String get facturationPaymentInfoSectionTitle => 'Informations du paiement';

  @override
  String get facturationPaymentPayerLabel => 'Payeur';

  @override
  String get facturationPaymentAmountLabel => 'Montant global payé';

  @override
  String get facturationPaymentPaidAtLabel => 'Date de paiement';

  @override
  String get facturationPaymentAllocationsSectionTitle =>
      'Allocations de paiement';

  @override
  String get facturationPaymentAllocationsSectionSubtitle =>
      'Liste des charges couvertes par ce paiement.';

  @override
  String get facturationPaymentAllocationsTotalLabel => 'Total alloué';

  @override
  String get facturationPaymentAllocationsEmpty =>
      'Aucune allocation n\'a été trouvée pour ce paiement.';

  @override
  String get facturationPaymentAllocationsConsistencyOk =>
      'La somme des allocations est cohérente avec le montant global payé.';

  @override
  String get facturationPaymentAllocationsConsistencyWarning =>
      'Incohérence détectée : la somme des allocations ne correspond pas au montant global payé.';

  @override
  String get facturationPaymentAllocationsNetworkError =>
      'Impossible de charger les allocations du paiement. Vérifiez votre connexion internet.';

  @override
  String get facturationPaymentAllocationsNotFound =>
      'Aucune allocation trouvée pour ce paiement.';

  @override
  String get facturationPaymentAllocationsValidationError =>
      'Les informations demandées pour les allocations sont invalides.';

  @override
  String get facturationPaymentAllocationsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter les allocations de ce paiement.';

  @override
  String get facturationPaymentAllocationsInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux allocations de ce paiement.';

  @override
  String get facturationPaymentAllocationsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get facturationPaymentAllocationsStorageError =>
      'Une erreur locale empêche l\'affichage des allocations.';

  @override
  String get facturationPaymentAllocationsAuthError =>
      'Une erreur d\'authentification empêche le chargement des allocations.';

  @override
  String get facturationPaymentAllocationsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des allocations.';

  @override
  String get facturationDetailChargesSectionTitle => 'Charges de l\'élève';

  @override
  String get facturationDetailChargesSectionSubtitle =>
      'Répartition des montants attendus, payés et restants.';

  @override
  String facturationDetailChargesSummary(
    num totalCount,
    Object partialCount,
    Object dueCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      totalCount,
      locale: localeName,
      other: '$totalCount charges',
      one: '1 charge',
      zero: '0 charge',
    );
    return '$_temp0 · $partialCount partielle(s), $dueCount à régler';
  }

  @override
  String get facturationDetailChargesRetry => 'Réessayer';

  @override
  String get facturationDetailChargesEmpty =>
      'Aucune charge n\'a été trouvée pour cet élève.';

  @override
  String get facturationDetailChargeLabelColumn => 'Libellé';

  @override
  String get facturationDetailChargeExpectedAmountColumn => 'Attendu';

  @override
  String get facturationDetailChargePaidAmountColumn => 'Payé';

  @override
  String get facturationDetailChargeRemainingAmountColumn => 'Reste';

  @override
  String get facturationDetailChargeStatusColumn => 'Statut';

  @override
  String get facturationDetailChargeTotalsLabel => 'Totaux';

  @override
  String get facturationPaymentsNetworkError =>
      'Impossible de charger les paiements. Vérifiez votre connexion internet.';

  @override
  String get facturationPaymentsNotFound =>
      'Aucun paiement trouvé pour cet élève.';

  @override
  String get facturationPaymentsValidationError =>
      'Les informations demandées pour les paiements sont invalides.';

  @override
  String get facturationPaymentsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces paiements.';

  @override
  String get facturationPaymentsInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux paiements.';

  @override
  String get facturationPaymentsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get facturationPaymentsStorageError =>
      'Une erreur locale empêche l\'affichage des paiements.';

  @override
  String get facturationPaymentsAuthError =>
      'Une erreur d\'authentification empêche le chargement des paiements.';

  @override
  String get facturationPaymentsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des paiements.';

  @override
  String get facturationPrintReceiptLabel => 'Imprimer le reçu';

  @override
  String get facturationPrintReceiptSubtitle =>
      'Générez et téléchargez le reçu de ce paiement';

  @override
  String get facturationPaymentDownloadPdfLabel => 'Télécharger le PDF';

  @override
  String get facturationPrintStatementsLabel => 'Imprimer les relevés';

  @override
  String get facturationPrintStatementsSubtitle =>
      'Générez et téléchargez les relevés de facturation de cet étudiant';

  @override
  String get facturationChargeDetailBackLabel =>
      'Retour au détail de facturation';

  @override
  String get facturationChargeDetailHeroTitle => 'Détail d\'une charge';

  @override
  String get facturationChargeDetailHeroSubtitle =>
      'Consultez l\'état de cette charge et les paiements qui y ont été alloués.';

  @override
  String get facturationChargeDetailInfoSectionTitle =>
      'Informations de la charge';

  @override
  String get facturationChargeDetailExpectedAmountLabel => 'Montant attendu';

  @override
  String get facturationChargeDetailPaidAmountLabel => 'Montant payé';

  @override
  String get facturationChargeDetailRemainingAmountLabel => 'Reste à payer';

  @override
  String get facturationChargeDetailStatusLabel => 'Statut';

  @override
  String get facturationChargeDetailAllocationsSectionTitle =>
      'Allocations liées à cette charge';

  @override
  String get facturationChargeDetailAllocationsSectionSubtitle =>
      'Détail des paiements alloués à cette charge.';

  @override
  String get facturationChargeDetailAllocationLabelColumn => 'Allocation';

  @override
  String get facturationChargeDetailAllocationsTotalLabel => 'Total alloué';

  @override
  String get facturationChargeDetailAllocationsEmpty =>
      'Aucune allocation n\'a été trouvée pour cette charge.';

  @override
  String get facturationChargeDetailAllocationsRetry => 'Réessayer';

  @override
  String get facturationChargeDetailAllocationsNetworkError =>
      'Impossible de charger les allocations. Vérifiez votre connexion internet.';

  @override
  String get facturationChargeDetailAllocationsNotFound =>
      'Aucune allocation trouvée pour cette charge.';

  @override
  String get facturationChargeDetailAllocationsValidationError =>
      'Les informations demandées pour les allocations sont invalides.';

  @override
  String get facturationChargeDetailAllocationsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter les allocations de cette charge.';

  @override
  String get facturationChargeDetailAllocationsInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux allocations de cette charge.';

  @override
  String get facturationChargeDetailAllocationsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get facturationChargeDetailAllocationsStorageError =>
      'Une erreur locale empêche l\'affichage des allocations.';

  @override
  String get facturationChargeDetailAllocationsAuthError =>
      'Une erreur d\'authentification empêche le chargement des allocations.';

  @override
  String get facturationChargeDetailAllocationsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des allocations.';

  @override
  String get facturationChargeDetailContextErrorTitle =>
      'Contexte de détail de charge indisponible';

  @override
  String get facturationChargeDetailContextErrorMessage =>
      'Les informations nécessaires pour afficher cette charge ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get facturationCreatePaymentBackLabel =>
      'Retour au détail de facturation';

  @override
  String get facturationCreatePaymentHeroTitle => 'Nouveau paiement';

  @override
  String get facturationCreatePaymentHeroSubtitle =>
      'Renseignez les informations du payeur et les allocations pour enregistrer un paiement.';

  @override
  String get facturationCreatePaymentPayerSectionTitle =>
      'Informations du payeur';

  @override
  String get facturationCreatePaymentPayerLastNameLabel => 'Nom';

  @override
  String get facturationCreatePaymentPayerLastNameHint => 'Entrez le nom';

  @override
  String get facturationCreatePaymentPayerFirstNameLabel => 'Prénom';

  @override
  String get facturationCreatePaymentPayerFirstNameHint => 'Entrez le prénom';

  @override
  String get facturationCreatePaymentPayerMiddleNameLabel =>
      'Post-nom (optionnel)';

  @override
  String get facturationCreatePaymentPayerMiddleNameHint =>
      'Entrez le post-nom';

  @override
  String get facturationCreatePaymentPayerFieldRequired =>
      'Ce champ est obligatoire';

  @override
  String get facturationCreatePaymentDetailsSectionTitle =>
      'Détails du paiement';

  @override
  String get facturationCreatePaymentDetailsSectionSubtitle =>
      'Saisissez le montant reçu, la devise et la date du paiement.';

  @override
  String get facturationCreatePaymentReceivedAmountLabel => 'Montant reçu';

  @override
  String get facturationCreatePaymentReceivedAmountHint => 'Ex : 200';

  @override
  String get facturationCreatePaymentCurrencyLabel => 'Devise';

  @override
  String get facturationCreatePaymentCurrencyReadOnlyHint =>
      'Plusieurs devises détectées : valeur en lecture seule.';

  @override
  String get facturationCreatePaymentCurrencyUnavailable =>
      'Devise indisponible';

  @override
  String get facturationCreatePaymentDateLabel => 'Date du paiement';

  @override
  String get facturationCreatePaymentAllocationSectionTitle =>
      'Allocations de paiement';

  @override
  String get facturationCreatePaymentAllocationSectionSubtitle =>
      'Associez un montant à une ou plusieurs charges de l\'élève.';

  @override
  String get facturationCreatePaymentAddAllocationLabel =>
      'Ajouter une allocation';

  @override
  String get facturationCreatePaymentAllChargesPaid =>
      'Toutes les charges de cet élève sont déjà réglées.';

  @override
  String get facturationCreatePaymentChargesUnavailable =>
      'Aucune charge disponible. Revenez à la liste et recommencez.';

  @override
  String get facturationCreatePaymentChargeDropdownHint =>
      'Sélectionnez une charge';

  @override
  String get facturationCreatePaymentAmountLabel => 'Montant à payer';

  @override
  String get facturationCreatePaymentAmountHint => 'Ex : 5000';

  @override
  String get facturationCreatePaymentAmountRequired =>
      'Le montant est obligatoire';

  @override
  String get facturationCreatePaymentAmountInvalid =>
      'Veuillez entrer un nombre valide';

  @override
  String get facturationCreatePaymentAmountExceedsRemaining =>
      'Le montant ne peut pas dépasser le restant à payer';

  @override
  String get facturationCreatePaymentAmountMustBePositive =>
      'Le montant doit être supérieur à zéro';

  @override
  String get facturationCreatePaymentBeforeLabel => 'Avant paiement';

  @override
  String get facturationCreatePaymentAfterLabel => 'Après paiement';

  @override
  String get facturationCreatePaymentRemoveAllocationConfirmTitle =>
      'Confirmer la suppression';

  @override
  String facturationCreatePaymentRemoveAllocationConfirmMessage(
    int allocationIndex,
  ) {
    return 'Voulez-vous vraiment supprimer l\'allocation n° $allocationIndex ? Cette action est irréversible.';
  }

  @override
  String get facturationCreatePaymentRemoveAllocationConfirmAction =>
      'Supprimer';

  @override
  String get facturationCreatePaymentSubmitLabel => 'Valider le paiement';

  @override
  String get facturationCreatePaymentNoAllocations =>
      'Ajoutez au moins une allocation pour valider le paiement.';

  @override
  String get facturationCreatePaymentConfirmTitle => 'Confirmer le paiement';

  @override
  String get facturationCreatePaymentConfirmMessage =>
      'Cette opération est irréversible. Confirmez-vous l\'enregistrement de ce paiement ?';

  @override
  String get facturationCreatePaymentConfirmCancel => 'Annuler';

  @override
  String get facturationCreatePaymentConfirmValidate => 'Confirmer';

  @override
  String get facturationCreatePaymentSuccessMessage =>
      'Paiement enregistré avec succès.';

  @override
  String get facturationCreatePaymentExpectedLabel => 'Montant attendu';

  @override
  String get facturationCreatePaymentPaidLabel => 'Déjà payé';

  @override
  String get facturationCreatePaymentRemainingLabel => 'Restant';

  @override
  String get facturationCreatePaymentStatusLabel => 'Statut';

  @override
  String get facturationCreatePaymentChargeImpactTitle =>
      'Impact sur la charge';

  @override
  String facturationCreatePaymentChargeRemainingHelper(String remainingAmount) {
    return 'Restant sur cette charge : $remainingAmount';
  }

  @override
  String get facturationCreatePaymentPayAllAction => 'Tout payer';

  @override
  String get facturationCreatePaymentDistributionTrackerIdle =>
      'Saisissez au moins une allocation pour calculer le total paiements.';

  @override
  String facturationCreatePaymentFooterTotalPayments(String allocatedAmount) {
    return 'Total paiements : $allocatedAmount';
  }

  @override
  String get facturationCreatePaymentNetworkError =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get facturationCreatePaymentNotFoundError =>
      'La ressource demandée est introuvable.';

  @override
  String get facturationCreatePaymentValidationError =>
      'Les données saisies sont invalides. Vérifiez le formulaire.';

  @override
  String get facturationCreatePaymentUnauthorizedError =>
      'Vous n\'êtes pas autorisé à effectuer cette opération.';

  @override
  String get facturationCreatePaymentInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'enregistrer ce paiement.';

  @override
  String get facturationCreatePaymentServerError =>
      'Le serveur est indisponible. Réessayez plus tard.';

  @override
  String get facturationCreatePaymentStorageError =>
      'Une erreur de stockage est survenue.';

  @override
  String get facturationCreatePaymentAuthError =>
      'Une erreur d\'authentification est survenue.';

  @override
  String get facturationCreatePaymentUnknownError =>
      'Une erreur inattendue est survenue.';

  @override
  String get facturationCreatePaymentNoChargesAvailable =>
      'Aucune charge non réglée disponible pour cet élève.';

  @override
  String get attendanceHeroTitle => 'Présences';

  @override
  String get attendanceHeroSubtitle =>
      'Consultez les présences par classe et date pour un suivi quotidien fiable.';

  @override
  String get attendanceHeroChipClass => 'Recherche par classe';

  @override
  String get attendanceHeroChipDate => 'Filtre par date';

  @override
  String get attendanceSearchTitle => 'Recherche des présences';

  @override
  String get attendanceSearchHint =>
      'Sélectionnez cycle, niveau, classe et date pour afficher les enregistrements.';

  @override
  String get attendanceDateLabel => 'Date';

  @override
  String get attendanceCycleLabel => 'Cycle';

  @override
  String get attendanceLevelLabel => 'Niveau';

  @override
  String get attendanceClassLabel => 'Classe';

  @override
  String get attendanceShowClassAction => 'Afficher la classe';

  @override
  String get attendanceInvitationMessage =>
      'Lancez une recherche pour afficher les présences de la classe sélectionnée.';

  @override
  String get attendanceEmptySelectionMessage =>
      'Sélectionnez une classe et une date pour faire l\'appel.';

  @override
  String get attendanceLoadingMessage => 'Chargement des présences en cours...';

  @override
  String get attendanceEmptyMessage =>
      'Aucune présence trouvée pour ces critères.';

  @override
  String get attendanceExportAction => 'Exporter';

  @override
  String get attendanceExportTooltip => 'Préparer l\'export des résultats';

  @override
  String get attendanceExportSoon => 'L\'export sera disponible prochainement.';

  @override
  String get attendanceSaveAction => 'Enregistrer';

  @override
  String get attendanceSavingAction => 'Enregistrement...';

  @override
  String get attendanceSaveTooltip =>
      'Enregistrer toutes les modifications saisies';

  @override
  String get attendanceSaveValidationHint =>
      'Corrigez les lignes absentes sans motif avant d\'enregistrer.';

  @override
  String get attendanceSaveSuccess =>
      'Les présences ont été enregistrées avec succès.';

  @override
  String get attendanceValidateCallAction => 'Valider l\'appel';

  @override
  String get attendancePendingChanges => 'Modifications en attente';

  @override
  String get attendancePendingInvalidChanges => 'Corrections requises';

  @override
  String get attendanceRowModifiedLabel => 'Modifiée';

  @override
  String get attendanceUnsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get attendanceUnsavedChangesMessage =>
      'Une nouvelle recherche supprimera les changements non enregistrés. Voulez-vous continuer ?';

  @override
  String get attendanceDateTooltip => 'Choisir la date des présences';

  @override
  String get attendanceStatusInProgress => 'Appel en cours';

  @override
  String get attendanceStatusReady => 'Prêt à valider';

  @override
  String get attendancePresentCount => 'Présents';

  @override
  String get attendanceAbsentCount => 'Absents';

  @override
  String get attendanceTotalCountCompact => 'Total';

  @override
  String get attendanceDefaultPresenceHelper =>
      'Tous les élèves sont présents par défaut. Tapez Absent pour signaler une exception.';

  @override
  String get attendanceReadyToValidate =>
      'Aucune absence sans motif. Vous pouvez valider l\'appel.';

  @override
  String attendanceMissingReasonsStatus(int count) {
    return '$count absence(s) sans motif — à compléter';
  }

  @override
  String get attendanceAllPresentConfirmTitle => 'Confirmer l\'appel';

  @override
  String attendanceAllPresentConfirmMessage(int count) {
    return 'Confirmez-vous que les $count élèves sont présents ?';
  }

  @override
  String get attendanceTotalCount => 'Effectif total';

  @override
  String get attendanceGirlsCount => 'Effectif filles';

  @override
  String get attendanceBoysCount => 'Effectif garçons';

  @override
  String attendanceCriteriaSummary(String classroomName, String formattedDate) {
    return 'Classe : $classroomName · Date : $formattedDate';
  }

  @override
  String get attendanceTableLastName => 'Nom';

  @override
  String get attendanceTableMiddleName => 'Post-nom';

  @override
  String get attendanceTableFirstName => 'Prénom';

  @override
  String get attendanceTablePresent => 'Présence';

  @override
  String get attendanceTableAbsenceReason => 'Motif';

  @override
  String get attendanceTableAbsenceReasonNote => 'Note';

  @override
  String get attendancePresenceStatusLabel => 'Statut de présence';

  @override
  String get attendancePresentValue => 'Présent';

  @override
  String get attendanceAbsentValue => 'Absent';

  @override
  String get attendanceReadOnlyHint => 'Statut consultatif en lecture seule';

  @override
  String get attendanceReasonRequiredError =>
      'Veuillez sélectionner un motif pour cette absence.';

  @override
  String get attendanceReasonRequiredHint => 'Motif requis pour une absence.';

  @override
  String get attendanceReasonDisabledHint =>
      'Le motif est requis seulement pour une absence.';

  @override
  String get attendanceNoteDisabledHint =>
      'La note est facultative seulement pour une absence.';

  @override
  String get attendanceNotePlaceholder => 'Ajouter une précision si nécessaire';

  @override
  String get attendanceNoMiddleName => 'Non renseigné';

  @override
  String get attendanceNoAbsenceReason => 'Aucun motif';

  @override
  String get attendanceNoAbsenceNote => 'Aucune note';

  @override
  String get attendanceErrorNetwork =>
      'Vérifiez votre connexion internet puis réessayez.';

  @override
  String get attendanceErrorNotFound =>
      'Aucune ressource de présence n\'a été trouvée.';

  @override
  String get attendanceErrorValidation =>
      'Les données envoyées sont invalides.';

  @override
  String get attendanceErrorUnauthorized =>
      'Vous n\'êtes pas autorisé à accéder à cette ressource.';

  @override
  String get attendanceErrorInvalidCredentials =>
      'Vos identifiants ne permettent pas d\'accéder aux présences.';

  @override
  String get attendanceErrorServer =>
      'Le serveur est indisponible. Réessayez plus tard.';

  @override
  String get attendanceErrorStorage =>
      'Une erreur de stockage local est survenue.';

  @override
  String get attendanceErrorAuth =>
      'Une erreur d\'authentification est survenue.';

  @override
  String get attendanceErrorUnknown => 'Une erreur inattendue est survenue.';

  @override
  String get absenceReasonSickness => 'Maladie';

  @override
  String get absenceReasonFamilyEmergency => 'Urgence familiale';

  @override
  String get absenceReasonPersonal => 'Personnel';

  @override
  String get absenceReasonUnknown => 'Inconnu';

  @override
  String get absenceReasonVacation => 'Vacances';

  @override
  String get absenceReasonUnderGraduateLeave => 'Congé d\'études';

  @override
  String get absenceReasonMarriageLeave => 'Congé de mariage';

  @override
  String get absenceReasonParentalLeave => 'Congé parental';

  @override
  String get absenceReasonWorkLeave => 'Congé professionnel';

  @override
  String get absenceReasonOther => 'Autre';

  @override
  String get bootstrapContextUnavailableTitle =>
      'Contexte d\'inscription indisponible';

  @override
  String get bootstrapContextUnavailableMessage =>
      'Les données bootstrap (année scolaire / école) sont absentes. Veuillez vous déconnecter puis vous reconnecter pour recharger la configuration.';

  @override
  String get signOutAction => 'Se déconnecter';

  @override
  String get disciplinaryDetailBackLabel => 'Retour aux disciplines';

  @override
  String get disciplinaryFollowUpTitle => 'Suivi disciplinaire';

  @override
  String get disciplinaryHeroTitle => 'Détail du dossier disciplinaire';

  @override
  String get disciplinaryHeroChipCases => 'Cas disciplinaires';

  @override
  String get disciplinaryDetailContextErrorTitle =>
      'Contexte de détail indisponible';

  @override
  String get disciplinaryDetailContextErrorMessage =>
      'Les informations nécessaires pour afficher ce détail ne sont pas disponibles. Revenez à la liste puis relancez la consultation.';

  @override
  String get disciplinaryTabCasesLabel => 'Cas disciplinaires';

  @override
  String get disciplinaryTabAttendanceHistoryLabel => 'Historique de présences';

  @override
  String get disciplinaryAttendanceHistoryComingSoon =>
      'L\'historique de présences sera ajouté dans une prochaine feature.';

  @override
  String get disciplinaryUnknownValue => '-';

  @override
  String get disciplinaryCaseCreateAction => 'Nouveau cas';

  @override
  String get disciplinaryCaseCreateCtaSubtitle =>
      'Documentez un nouvel incident disciplinaire pour cet élève.';

  @override
  String disciplinaryCasesSummary(int total, int open) {
    return '$total cas enregistrés - $open ouverts';
  }

  @override
  String get disciplinaryCasesTableTitleColumn => 'Titre';

  @override
  String get disciplinaryCasesTableStatusColumn => 'Statut';

  @override
  String get disciplinaryCasesTableActionColumn => 'Actions';

  @override
  String get disciplinaryCasesDateUnavailable => 'Date non disponible';

  @override
  String get disciplinaryCaseViewLabel => 'Voir le cas';

  @override
  String get disciplinaryCasesLoadingMessage =>
      'Chargement des cas disciplinaires...';

  @override
  String get disciplinaryCasesEmptyMessage =>
      'Aucun cas disciplinaire pour cet élève.';

  @override
  String get disciplinaryCaseViewDialogTitle => 'Détail du cas disciplinaire';

  @override
  String get disciplinaryCaseViewDialogSectionTitle => 'Informations du cas';

  @override
  String get disciplinaryCaseViewDialogTitleField => 'Titre';

  @override
  String get disciplinaryCaseViewDialogStatusField => 'Statut';

  @override
  String get disciplinaryCaseViewDialogContentField => 'Contenu';

  @override
  String get disciplinaryCaseViewDialogLoadingMessage =>
      'Chargement du détail du cas...';

  @override
  String get disciplinaryCaseViewDialogErrorMessage =>
      'Impossible de charger le détail du cas';

  @override
  String get disciplinaryCaseCreateDialogTitle => 'Créer un cas disciplinaire';

  @override
  String get disciplinaryCaseCreateDialogTitleField => 'Titre du cas';

  @override
  String get disciplinaryCaseCreateDialogTitleHint =>
      'Décrivez brièvement le cas';

  @override
  String get disciplinaryCaseCreateDialogContentField => 'Contenu';

  @override
  String get disciplinaryCaseCreateDialogContentHint =>
      'Détails du cas disciplinaire';

  @override
  String get disciplinaryCaseCreateDialogCaseDateField => 'Date du cas';

  @override
  String get disciplinaryCaseCreateDialogCaseDateHint => 'Sélectionner la date';

  @override
  String get disciplinaryCaseCreateDialogSubmitAction => 'Créer le cas';

  @override
  String get disciplinaryCaseCreateDialogCreatingMessage =>
      'Création en cours...';

  @override
  String get disciplinaryCaseCreateDialogSuccessMessage =>
      'Cas disciplinaire créé avec succès.';

  @override
  String get disciplinaryCaseCreateDialogRequiredFieldError =>
      'Ce champ est obligatoire.';

  @override
  String get disciplinaryCasesNetworkError =>
      'Vérifiez votre connexion internet puis réessayez.';

  @override
  String get disciplinaryCasesNotFound => 'Aucun cas disciplinaire trouvé.';

  @override
  String get disciplinaryCasesValidationError =>
      'Les données demandées sont invalides.';

  @override
  String get disciplinaryCasesUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces cas.';

  @override
  String get disciplinaryCasesInvalidCredentialsError =>
      'Vos identifiants ne permettent pas d\'accéder aux cas.';

  @override
  String get disciplinaryCasesServerError =>
      'Le serveur est indisponible. Réessayez plus tard.';

  @override
  String get disciplinaryCasesStorageError =>
      'Une erreur de stockage local est survenue.';

  @override
  String get disciplinaryCasesAuthError =>
      'Une erreur d\'authentification empêche le chargement des cas.';

  @override
  String get disciplinaryCasesUnknownError =>
      'Une erreur inattendue est survenue.';

  @override
  String get disciplinaryCaseStatusOpen => 'Ouvert';

  @override
  String get disciplinaryCaseStatusInProgress => 'En cours';

  @override
  String get disciplinaryCaseStatusClosed => 'Clôturé';

  @override
  String get disciplinaryCaseStatusUnknown => 'Inconnu';

  @override
  String get enrollmentStatusPreRegistered => 'Pré-inscrit';

  @override
  String get statusPaid => 'Payé';

  @override
  String get statusPartial => 'Partiel';

  @override
  String get statusOverdue => 'En retard';

  @override
  String get statusPresent => 'Présent';

  @override
  String get statusAbsentJustified => 'Justifié';

  @override
  String get statusAbsentUnjustified => 'Absent';

  @override
  String get statusSynced => 'À jour';

  @override
  String get statusSyncing => 'Synchro…';

  @override
  String get statusOffline => 'Hors ligne';

  @override
  String get statusPendingUpload => 'À envoyer';

  @override
  String get statusSyncConflict => 'Conflit';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Continuer';

  @override
  String get componentGalleryTitle => 'Galerie de composants';

  @override
  String get enrollmentStatsDashboardTitle =>
      'Vue d\'ensemble – Année scolaire';

  @override
  String get enrollmentStatsPeriodYear => 'Année';

  @override
  String get enrollmentStatsPeriodMonth => 'Mois';

  @override
  String get enrollmentStatsPeriodWeek => 'Semaine';

  @override
  String get enrollmentStatsKpiTotal => 'Total';

  @override
  String get enrollmentStatsKpiFirst => 'Premières inscriptions';

  @override
  String get enrollmentStatsKpiRe => 'Réinscriptions';

  @override
  String get enrollmentStatsKpiPre => 'Pré-inscriptions';

  @override
  String get enrollmentStatsKpiInProgress => 'En cours';

  @override
  String get enrollmentStatsSectionEvolution => 'Évolution';

  @override
  String get enrollmentStatsSectionCycle => 'Par cycle';

  @override
  String get enrollmentStatsSectionGender => 'Par genre';

  @override
  String get enrollmentStatsSectionEvolutionEnrollments =>
      'Evolution des Inscritions';

  @override
  String get enrollmentStatsSectionLevelEvolution => 'Evolution par niveau';

  @override
  String get enrollmentStatsSectionGenderEvolution => 'Evolution par genre';

  @override
  String get enrollmentStatsGenderMale => 'Garçons';

  @override
  String get enrollmentStatsGenderFemale => 'Filles';

  @override
  String get enrollmentStatsGenderOther => 'Autre';

  @override
  String get enrollmentStatsNoData => 'Aucune donnée pour cette période';

  @override
  String get enrollmentStatsLoadingError =>
      'Impossible de charger les statistiques';

  @override
  String get enrollmentStatsRetry => 'Réessayer';

  @override
  String get enrollmentStatsStudents => 'élèves';

  @override
  String enrollmentStatsPercent(int percent) {
    return '$percent %';
  }

  @override
  String get enrollmentStatsPeriodWeekCurrent => 'Cette semaine';

  @override
  String get enrollmentStatsPeriodMonthCurrent => 'Ce mois';

  @override
  String get enrollmentStatsPeriodYearCurrent => 'Cette année';

  @override
  String get enrollmentStatsSchoolYearUnavailable =>
      'Année scolaire indisponible';

  @override
  String enrollmentStatsHeaderA11yLabel(String schoolYear) {
    return 'Tableau de bord des inscriptions, année scolaire $schoolYear';
  }

  @override
  String enrollmentStatsPeriodFilterA11yLabel(String selectedPeriod) {
    return 'Filtre temporel des statistiques d\'inscription, période active : $selectedPeriod';
  }

  @override
  String enrollmentStatsContextSchoolYear(String schoolYear) {
    return 'Vue d\'ensemble — Année scolaire $schoolYear';
  }

  @override
  String get classesStatsDashboardTitle =>
      'Vue d\'ensemble Classes — Année scolaire';

  @override
  String get classesStatsSchoolYearUnavailable => 'Année scolaire indisponible';

  @override
  String classesStatsHeaderA11yLabel(String schoolYear) {
    return 'Tableau de bord des classes, année scolaire $schoolYear';
  }

  @override
  String get classesStatsKpiTotalStudents => 'TOTAL ELEVES';

  @override
  String get classesStatsKpiActiveGirls => 'TOTAL FILLES';

  @override
  String get classesStatsKpiActiveBoys => 'GARCONS';

  @override
  String get classesStatsKpiInactiveStudents => 'TOTAL ELEVES INACTIFS';

  @override
  String get classesStatsSectionCycleDistribution =>
      'Répartition des actifs par cycle';

  @override
  String classesStatsSectionLevelDistribution(String cycleCode) {
    return 'Répartition des niveaux — $cycleCode';
  }

  @override
  String get classesStatsSectionClassroomDetail => 'Détail des classes';

  @override
  String get classesStatsDetailColumnClassroom => 'Classe';

  @override
  String get classesStatsDetailColumnCycle => 'Cycle';

  @override
  String get classesStatsDetailColumnLevel => 'Niveau';

  @override
  String get classesStatsDetailColumnTotal => 'Total';

  @override
  String get classesStatsDetailColumnGirls => 'Filles';

  @override
  String get classesStatsDetailColumnBoys => 'Garçons';

  @override
  String get classesStatsNoData =>
      'Aucune donnée disponible pour cette période';

  @override
  String get classesStatsKpiBandA11yLabel =>
      'Bandeau des indicateurs clés classes';

  @override
  String get classesStatsCycleChartA11yLabel =>
      'Graphique de répartition des élèves actifs par cycle';

  @override
  String classesStatsLevelChartA11yLabel(String cycleCode) {
    return 'Graphique de répartition des élèves actifs par niveau pour le cycle $cycleCode';
  }

  @override
  String get classesStatsDetailA11yLabel =>
      'Tableau détaillé des classes avec effectifs par genre';

  @override
  String get classesStatsLoadingA11yLabel =>
      'Chargement des statistiques classes en cours';

  @override
  String get classesStatsErrorTitle => 'Erreur de chargement';

  @override
  String get classesStatsRetry => 'Réessayer';

  @override
  String get classesStatsRetryHint =>
      'Relancer le chargement des statistiques classes';

  @override
  String classesStatsErrorA11yLabel(String message) {
    return 'Erreur de chargement des statistiques classes : $message';
  }

  @override
  String get classesStatsNetworkError =>
      'Impossible de charger les statistiques classes. Vérifiez votre connexion internet.';

  @override
  String get classesStatsNotFoundError =>
      'Aucune statistique classes disponible.';

  @override
  String get classesStatsValidationError =>
      'Les paramètres demandés sont invalides.';

  @override
  String get classesStatsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces statistiques.';

  @override
  String get classesStatsInvalidCredentialsError =>
      'Session invalide, reconnectez-vous.';

  @override
  String get classesStatsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get classesStatsStorageError =>
      'Une erreur locale empêche l\'affichage des statistiques.';

  @override
  String get classesStatsAuthError =>
      'Une erreur d\'authentification empêche le chargement des statistiques.';

  @override
  String get classesStatsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des statistiques.';

  @override
  String get financeStatsDashboardTitle => 'Vue d\'ensemble — Année scolaire';

  @override
  String get financeStatsSchoolYearUnavailable => 'Année scolaire indisponible';

  @override
  String financeStatsContextSchoolYear(String schoolYear) {
    return 'Vue d\'ensemble — Année scolaire $schoolYear';
  }

  @override
  String get financeStatsPeriodWeekCurrent => 'Cette semaine';

  @override
  String get financeStatsPeriodMonthCurrent => 'Ce mois';

  @override
  String get financeStatsPeriodYearCurrent => 'Cette année';

  @override
  String get financeStatsKpiCollected => 'Total encaissé';

  @override
  String get financeStatsKpiExpected => 'Total attendu';

  @override
  String get financeStatsKpiOutstanding => 'Reste à recouvrer';

  @override
  String get financeStatsKpiCollectionRate => 'Taux de recouvrement';

  @override
  String financeStatsPercentOfTotal(int percent) {
    return '$percent% du total';
  }

  @override
  String get financeStatsSectionEvolution => 'Évolution des encaissements';

  @override
  String get financeStatsLegendCurrentPeriod => 'Période en cours';

  @override
  String get financeStatsLegendOtherPeriods => 'Autres périodes';

  @override
  String get financeStatsSectionFeeTypeDistribution =>
      'Répartition par type de frais';

  @override
  String financeStatsFeeTypeCollected(String amount) {
    return 'Encaissé : $amount';
  }

  @override
  String financeStatsFeeTypeExpected(String amount) {
    return 'Attendu : $amount';
  }

  @override
  String financeStatsFeeTypeRate(int rate) {
    return 'Taux : $rate%';
  }

  @override
  String get financeStatsNoData =>
      'Aucune donnée disponible pour cette période';

  @override
  String get financeStatsNoDataHint =>
      'Essayez une autre période pour afficher davantage d\'informations.';

  @override
  String get financeStatsErrorTitle => 'Erreur de chargement';

  @override
  String get financeStatsRetry => 'Réessayer';

  @override
  String get financeStatsRetryHint =>
      'Relancer le chargement des statistiques financières';

  @override
  String get financeStatsLoadingA11yLabel =>
      'Chargement des statistiques financières en cours';

  @override
  String financeStatsHeaderA11yLabel(String schoolYear) {
    return 'Tableau de bord finance, année scolaire $schoolYear';
  }

  @override
  String financeStatsPeriodFilterA11yLabel(String selectedPeriod) {
    return 'Filtre temporel des statistiques financières, période active : $selectedPeriod';
  }

  @override
  String get financeStatsKpiBandA11yLabel =>
      'Bandeau des indicateurs clés financiers';

  @override
  String get financeStatsEvolutionChartA11yLabel =>
      'Graphique d\'évolution des montants encaissés';

  @override
  String get financeStatsFeeTypeSectionA11yLabel =>
      'Répartition des montants par type de frais';

  @override
  String financeStatsFeeTypeItemA11yLabel(
    String code,
    String collected,
    String expected,
    int rate,
  ) {
    return 'Type $code, encaissé $collected, attendu $expected, taux $rate%';
  }

  @override
  String financeStatsErrorA11yLabel(String message) {
    return 'Erreur de chargement des statistiques financières : $message';
  }

  @override
  String get financeStatsEmptyA11yLabel =>
      'Aucune donnée financière disponible pour cette période';

  @override
  String get financeStatsNetworkError =>
      'Impossible de charger les statistiques finance. Vérifiez votre connexion internet.';

  @override
  String get financeStatsNotFoundError =>
      'Aucune statistique finance disponible.';

  @override
  String get financeStatsValidationError =>
      'Les paramètres demandés sont invalides.';

  @override
  String get financeStatsUnauthorizedError =>
      'Vous n\'êtes pas autorisé à consulter ces statistiques.';

  @override
  String get financeStatsInvalidCredentialsError =>
      'Session invalide, reconnectez-vous.';

  @override
  String get financeStatsServerError =>
      'Le serveur est indisponible pour le moment.';

  @override
  String get financeStatsStorageError =>
      'Une erreur locale empêche l\'affichage des statistiques.';

  @override
  String get financeStatsAuthError =>
      'Une erreur d\'authentification empêche le chargement des statistiques.';

  @override
  String get financeStatsUnknownError =>
      'Une erreur inattendue est survenue lors du chargement des statistiques.';

  @override
  String get enrollmentResults => 'Résultats';

  @override
  String get sort => 'Trier';

  @override
  String get switchToTableView => 'Passer à la vue tableau';

  @override
  String get switchToGridView => 'Passer à la vue grille';

  @override
  String get enrollmentViewTable => 'Tableau';

  @override
  String get enrollmentViewGrid => 'Grille';

  @override
  String get enrollmentResultsA11yLabel => 'Résultats d\'inscriptions';

  @override
  String get dataTableSortAscending => 'Tri croissant';

  @override
  String get dataTableSortDescending => 'Tri décroissant';

  @override
  String get dataTableSortNone => 'Tri non appliqué';

  @override
  String openDetailsForStudent(String studentName) {
    return 'Ouvrir la fiche de $studentName';
  }

  @override
  String removeFilterNamed(String filter) {
    return 'Retirer le filtre $filter';
  }
}
